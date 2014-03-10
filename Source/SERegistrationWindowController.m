/* 
 * Senuti is the legal property of its developers, whose names are listed in the copyright file included
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

#include <openssl/md5.h>
#import <AddressBook/AddressBook.h>
#import "SERegistrationWindowController.h"

#define SPLIT_SIZE 8

NSString *SERegistrationOwnerPreferenceKey = @"SERegistrationOwner";
NSString *SERegistrationKeyPreferenceKey = @"SERegistrationKey";

@interface SERegistrationWindowController (PRIVATE)
- (NSString *)registrationNumberForName:(NSString *)name;
- (void)setupContentView:(NSView *)contentView;
- (void)setupInformation;
- (BOOL)isRegistered;
@end

@implementation SERegistrationWindowController

+ (void)initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		@"", SERegistrationOwnerPreferenceKey,
		@"", SERegistrationKeyPreferenceKey, nil]];
}

+ (NSString *)nibName {
	return @"Registration";
}

- (void)awakeFromNib {
	if ([self isRegistered]) {
		[[self window] setContentSize:[informationView frame].size];
		[[self window] setContentView:informationView];
	} else {
		[[self window] setContentSize:[registrationView frame].size];
		[[self window] setContentView:registrationView];
	}
	[[self window] center];
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setLenient:YES];
	[[date cell] setFormatter:dateFormatter];
	
	NSArray *parts = [[[NSUserDefaults standardUserDefaults] objectForKey:SERegistrationKeyPreferenceKey] componentsSeparatedByString:@"-"];
	if ([parts count] > 0) { [numberEntry1 setStringValue:[parts objectAtIndex:0]]; }
	if ([parts count] > 1) { [numberEntry2 setStringValue:[parts objectAtIndex:1]]; }
	if ([parts count] > 2) { [numberEntry3 setStringValue:[parts objectAtIndex:2]]; }
	if ([parts count] > 3) { [numberEntry4 setStringValue:[parts objectAtIndex:3]]; }
	if ([parts count] > 4) { [numberEntry5 setStringValue:[parts objectAtIndex:4]]; }
	[ownerEntry setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:SERegistrationOwnerPreferenceKey]];
	
	ABPerson *person = [[ABAddressBook sharedAddressBook] me];
	if ([person imageData]) {
		[image setImage:[[[NSImage alloc] initWithData:[person imageData]] autorelease]];
	}
	
	[self setupInformation];
}

- (void)setupInformation {
	[owner setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:SERegistrationOwnerPreferenceKey]];
	[number setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:SERegistrationKeyPreferenceKey]];
	NSArray *parts = [[[NSUserDefaults standardUserDefaults] objectForKey:SERegistrationKeyPreferenceKey] componentsSeparatedByString:@"-"];
	NSString *dateHash = [[parts firstObject] uppercaseString];
	if (dateHash) {
		time_t time = strtol([dateHash cString], NULL, 16);
		NSDate *dateRegistered = [NSDate dateWithTimeIntervalSince1970:time];
		[date setObjectValue:dateRegistered];
	}
}

- (BOOL)isRegistered {
	NSString *name = [[NSUserDefaults standardUserDefaults] objectForKey:SERegistrationOwnerPreferenceKey];
	NSString *key = [[NSUserDefaults standardUserDefaults] objectForKey:SERegistrationKeyPreferenceKey];
	if ([key length] == 44 && [[key substringFromIndex:9] caseInsensitiveCompare:[self registrationNumberForName:name]] == 0) {
		return YES;
	}
	return NO;
}

- (NSString *)registrationNumberForName:(NSString *)name {
	const char *data = [[[name lowercaseString] stringByAppendingString:@"|senuti"] cStringUsingEncoding:NSUTF8StringEncoding];
	unsigned char *digest = MD5((const unsigned char *)data, strlen(data), NULL);
	int digestLength = 16;
	
	NSMutableArray *parts = [NSMutableArray array];
	NSMutableString *code = [NSMutableString string];
	
	int counter;
	for (counter = 0; counter < digestLength; counter++) {
		[code appendFormat:@"%02X", digest[counter]];
		if ([code length] == SPLIT_SIZE) {
			[parts addObject:code];
			code = [NSMutableString string];
		}
	}
		
	return [parts componentsJoinedByString:@"-"];
}


- (IBAction)finishRegistration:(id)sender {
	[self setupInformation];
	[self setupContentView:informationView];
	[finishRegistration setEnabled:[self isRegistered]];
}

- (IBAction)purchase:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.fadingred.org/senuti/purchase/"]];
}

- (IBAction)change:(id)sender {
	[self setupContentView:registrationView];
	[finishRegistration setEnabled:[self isRegistered]];
}

- (void)setupContentView:(NSView *)contentView {
	NSRect windowRect = [[self window] frame];
	NSSize frameSize = [NSWindow frameRectForContentRect:[[[self window] contentView] frame] styleMask:[[self window] styleMask]].size;
	NSSize newFrameSize = [NSWindow frameRectForContentRect:[contentView frame] styleMask:[[self window] styleMask]].size;
	[[self window] setContentView:[[[NSView alloc] init] autorelease]];
	[[self window] setFrame:NSMakeRect(windowRect.origin.x - (newFrameSize.width - frameSize.width) / 2,
									   windowRect.origin.y - (newFrameSize.height - frameSize.height),
									   newFrameSize.width,
									   newFrameSize.height) display:YES animate:YES];
	[[self window] setContentView:contentView];
	
}


- (void)controlTextDidChange:(NSNotification *)notification {
	
	NSTextField *field = [notification object];
	if (field == ownerEntry) {
		[[NSUserDefaults standardUserDefaults] setObject:[ownerEntry stringValue] forKey:SERegistrationOwnerPreferenceKey];
	} else {
		NSString *string = [field stringValue];
		while ([string length] > 0) {
			int index = SPLIT_SIZE;
			if (index > [string length]) { index = [string length]; }
			[field setStringValue:[string substringToIndex:index]];
			string = [string substringFromIndex:index];
			string = [string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
			
			if (index == SPLIT_SIZE) {
				NSTextField *nextField = (NSTextField *)[[field nextKeyView] nextKeyView];
				if (!nextField || ![nextField isKindOfClass:[NSTextField class]]) { break; }
				if ([[nextField stringValue] length] && [string length]) {
					NSBeep();
					break;
				}
				[[self window] selectKeyViewFollowingView:[field nextKeyView]];
				field = nextField;
			} else { break; }
		}
		
		NSArray *registrationKey = [NSArray arrayWithObjects:
			[numberEntry1 stringValue],
			[numberEntry2 stringValue],
			[numberEntry3 stringValue],
			[numberEntry4 stringValue],
			[numberEntry5 stringValue], nil];
		[[NSUserDefaults standardUserDefaults] setObject:[registrationKey componentsJoinedByString:@"-"] forKey:SERegistrationKeyPreferenceKey];
	}

	[finishRegistration setEnabled:[self isRegistered]];
}

@end
