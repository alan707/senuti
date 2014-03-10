/* 
 * Libxpod is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "LXMobile.h"
#import "itdb_private.h"

NSString *LXMobileDeviceConnectedNotification = @"LXMobileDeviceConnectedNotification";
NSString *LXMobileDeviceDisconnectedNotification = @"LXMobileDeviceDisconnectedNotification";
static const char* kMediaAFC = "com.apple.afc";

@interface LXMobile (PRIVATE)
+ (id)mobileWithDevice:(struct am_device *)device;
- (id)initWithDevice:(struct am_device *)device;
- (id)registerMobile;
- (id)unregisterMobile;

- (afc_file_ref)openRead:(char *)path size:(int *)size;
@end

static void notify(struct am_device_notification_callback_info *info, void* arg) {
	if (info->msg == ADNCI_MSG_CONNECTED) {
		LXMobile *mobile = [LXMobile mobileWithDevice:info->dev];
		if (mobile) {
			[mobile registerMobile];
			[[NSNotificationCenter defaultCenter] postNotificationName:LXMobileDeviceConnectedNotification object:mobile];
		}
	} else if(info->msg == ADNCI_MSG_DISCONNECTED) {
		LXMobile *mobile = [LXMobile mobileForDevice:info->dev];
		if (mobile) {
			[[NSNotificationCenter defaultCenter] postNotificationName:LXMobileDeviceDisconnectedNotification object:mobile];
			[mobile unregisterMobile];
		}
	}
}

@implementation LXMobile

#pragma mark global handling
// ----------------------------------------------------------------------------------------------------
// global handling
// ----------------------------------------------------------------------------------------------------

+ (void)beginWatch {
    struct am_device_notification *notif;
	int ret = AMDeviceNotificationSubscribe(notify, 0, 0, NULL, &notif);
	if (ret != 0) {
		NSLog(@"AMDeviceNotificationSubscribe: Failed: %i", ret);
	}
}

static NSMutableDictionary *devices = nil;
+ (id)mobileForDevice:(struct am_device *)device {
	return [devices objectForKey:[NSString stringWithCString:device->serial]];
}

- (id)registerMobile {
	if (!devices) { devices = [[NSMutableDictionary alloc] init]; }
	[devices setObject:self forKey:[NSString stringWithCString:device->serial]];
}

- (id)unregisterMobile {
	[devices removeObjectForKey:[NSString stringWithCString:device->serial]];
	if (![devices count]) { [devices release]; devices = nil; }
}

#pragma mark mobile object
// ----------------------------------------------------------------------------------------------------
// mobile object
// ----------------------------------------------------------------------------------------------------

+ (id)mobileWithDevice:(struct am_device *)device {
	return [[[self alloc] initWithDevice:device] autorelease];
}

- (id)initWithDevice:(struct am_device *)dev {
	if ((self = [super init])) {
		AMDeviceRetain(dev);
		device = dev;
		
		int ret = AMDeviceConnect(device);
		if (ret != 0) {
			NSLog(@"AMDeviceConnect: Connect failed: %i", ret);
			[self release];
			return nil;
		}
		if (!AMDeviceIsPaired(device)) {
			NSLog(@"AMDeviceIsPaired: Device was not paired");
			[self release];
			return nil;
		}
		ret = AMDeviceValidatePairing(device);
		if (ret != 0) {
			NSLog(@"AMDeviceValidatePairing: Device pairing was not validated: %i", ret);
			[self release];
			return nil;
		}
		ret = AMDeviceStartSession(device);
		if (ret != 0) {
			NSLog(@"AMDeviceStartSession: Session was not started: %i", ret);
			[self release];
			return nil;
		}
		
		// open
		CFStringRef serv = CFStringCreateWithCString(NULL, kMediaAFC, strlen(kMediaAFC));
		ret = AMDeviceStartService(device, serv, &connection, NULL);
		if (ret != 0 || connection == NULL) {
			NSLog(@"AMDeviceStartService: Device service was not started: %i", ret);
			[self release];
			return nil;
		}
		ret = AFCConnectionOpen(connection, 0, &connection);
		if (ret != 0) {
			NSLog(@"AFCConnectionOpen: Failed to open connection: %i", ret);
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)dealloc {
	AMDeviceRelease(device);
	device = NULL;
	if (contents) {
		itdb_free(contents);
		contents = NULL;
	}
	[super dealloc];
}

- (Itdb_iTunesDB *)contents {
	if (!contents) {

		// this could be one of 2 paths
		char *dbPaths[] = { "/iTunes_Control/iTunes/iTunesDB", "/iTunes_Control/iTunesDB", NULL };
		char *dbPath;
		afc_file_ref db;
		unsigned int size;

		int i = 0;
		BOOL found = FALSE;
		while ((dbPath = dbPaths[i++])) {
			if ([self openRead:dbPath reference:&db size:&size]) {
				found = TRUE;
				break;
			}
		}
		
		if (!found) {
			NSLog(@"AFCFileInfoOpen: Failed to stat a valid file.  Device structure may have changed");
			return NULL;
		}
				
		// read
		FContents *cts;
		cts = g_new0 (FContents, 1);
		cts->reversed = FALSE;
		cts->filename = g_strdup(dbPath);
		cts->length = size;
		cts->contents = g_malloc(cts->length+1);
		gsize bytes_read = 0;
		while (bytes_read < cts->length) {
			unsigned int afcSize = cts->length - bytes_read;
			int ret = AFCFileRefRead(connection, db, cts->contents + bytes_read, &afcSize);
			if (ret != 0) {
				NSLog(@"AFCFileRefRead: Failed to read");
				return NULL;
			} else {
				bytes_read += afcSize;
			}
		}
		cts->contents[bytes_read] = '\0';
		
		// close
		AFCFileRefClose(connection, db);
		
		// create itunesdb
		contents = itdb_new();
		contents->filename = g_strdup("/");

		FImport *fimp = g_new0 (FImport, 1);
		fimp->itdb = contents;
		
		fimp->fcontents = cts;
		if (!fimp->fcontents) { NSLog(@"No contents"); return NULL;	}
		if (!playcounts_init(fimp)) { NSLog(@"Failed to init playcounts"); return NULL; }
		if (!parse_fimp(fimp)) { NSLog(@"Failed to parse"); return NULL; }
		if (!read_OTG_playlists(fimp)) { NSLog(@"Failed to read OTG"); return NULL; }
		itdb_free_fimp(fimp);
	}
    return contents;	
}

- (BOOL)copyPath:(NSString *)source toPath:(NSString *)destination {
	afc_file_ref file;	
	if (![self openRead:[source UTF8String] reference:&file size:NULL]) {
		NSLog(@"failed to open source");
		return NO;
	}
	
	int ofile = open([destination UTF8String], O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
	if (ofile < 0) { NSLog(@"failed to open dest %s", [destination UTF8String]); return NO; }

	const unsigned int BUFFER_SIZE = 1024 * 256; // 256K at a time
	char buffer[BUFFER_SIZE];
	while (true) {
		unsigned int size = BUFFER_SIZE;
		if (AFCFileRefRead(connection, file, buffer, &size) != 0) { NSLog(@"AFCFileRefRead: Failed to read"); return NO; }
		write(ofile, buffer, size);
		if (size < BUFFER_SIZE) { break; }
	}
	
	// close
	close(ofile);
	AFCFileRefClose(connection, file);	
	
	return YES;
}

- (unsigned int)openFile:(const char *)path read:(BOOL)flag {
	afc_file_ref file;
	AFCFileRefOpen(connection, path, read ? 2 : 3, &file);
	return file;
}

- (void)closeFile:(unsigned int)file {
	AFCFileRefClose(connection, file);
}

- (int)readFile:(unsigned int)file into:(char *)buffer length:(int)len {
	AFCFileRefRead(connection, file, buffer, &len);
	return len;
}

- (void)seekFile:(unsigned int)file position:(int)position {
	AFCFileRefSeek(connection, file, position, 0);
}

#pragma mark util
// ----------------------------------------------------------------------------------------------------
// util
// ----------------------------------------------------------------------------------------------------

- (BOOL)openRead:(char *)path reference:(afc_file_ref *)ref size:(unsigned int *)size {
	if (size) {
		// stat the file
		struct afc_dictionary *info;
		if (AFCFileInfoOpen(connection, path, &info) != 0) {
			return FALSE;
		}
	
		BOOL found = FALSE;
		char *key, *val;
		while ((AFCKeyValueRead(info, &key, &val) == 0) && key && val) {
			if (strcmp("st_size", key) == 0) {
				*size = atoll(val);
				found = TRUE;
			}
		}
		if (!found) { [NSException raise:@"AFCKeyValueRead" format:@"st_size not found for file"]; }
	}
	
	afc_file_ref file;
	// open
	int ret = AFCFileRefOpen(connection, path, 2, &file);
	if (ret != 0) { return FALSE; }
	
	// seek
	ret = AFCFileRefSeek(connection, file, 0 /* offset */, 0);
	if (ret != 0) { return FALSE; }
	
	if (ref) { *ref = file; }
	return TRUE;
}

@end
