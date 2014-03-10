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

#import "SESenuti.h"
#import "SEInterfaceController.h"
#import "SELibraryController.h"
#import "SEUpdateController.h"
#import "SEMenuController.h"
#import "SECopyController.h"
#import "SEAudioController.h"
#import "SEApplescriptController.h"

#import "SEPreferenceWindowController.h"

#import <CrashReporter/CrashReporter.h>
#import "SEController.h"
#import "SEObject.h"

#import "SETextColorTransformer.h"
#import "SETimeTransformer.h"
#import "SEShortTimeTransformer.h"
#import "SESimilarTracksTransformer.h"
#import "SEAddValueIntegerTransformer.h"
#import "SESizeTransformer.h"
#import "SETupleTransformer.h"
#import "SEKBPSTransformer.h"
#import "SENotZeroTransformer.h"

@interface SESenuti (PRIVATE)

- (void)setupControllers;
- (void)tearDownControllers;

@end

@implementation SESenuti

+ (void)initialize {
		
#ifndef UNIT_TEST
	// register application defaults
	[SEPreferenceWindowController registerDefaults];

	[NSValueTransformer setValueTransformer:[[[SETextColorTransformer alloc] initAsActive:TRUE] autorelease]
									forName:@"SEActiveTextColorTransformer"];
	[NSValueTransformer setValueTransformer:[[[SETextColorTransformer alloc] initAsActive:FALSE] autorelease]
									forName:@"SEInactiveTextColorTransformer"];
	[NSValueTransformer setValueTransformer:[[[SETimeTransformer alloc] init] autorelease]
									forName:@"SETimeTransformer"];
	[NSValueTransformer setValueTransformer:[[[SEShortTimeTransformer alloc] init] autorelease]
									forName:@"SEShortTimeTransformer"];
	[NSValueTransformer setValueTransformer:[[[SESizeTransformer alloc] init] autorelease]
									forName:@"SESizeTransformer"];
	[NSValueTransformer setValueTransformer:[[[SEKBPSTransformer alloc] init] autorelease]
									forName:@"SEKBPSTransformer"];
	[NSValueTransformer setValueTransformer:[[[SETupleTransformer alloc] init] autorelease]
									forName:@"SETupleTransformer"];
	[NSValueTransformer setValueTransformer:[[[SENotZeroTransformer alloc] init] autorelease]
									forName:@"SENotZeroTransformer"];
	[NSValueTransformer setValueTransformer:[[[SESimilarTracksTransformer alloc] init] autorelease]
									forName:@"SESimilarTracksTransformer"];
	[NSValueTransformer setValueTransformer:[[[SEAddValueIntegerTransformer alloc] initWithAmount:5] autorelease]
									forName:@"SEPlusFiveIntegerTransformer"];
	[NSValueTransformer setValueTransformer:[[[SEAddValueIntegerTransformer alloc] initWithAmount:10] autorelease]
									forName:@"SEPlusTenIntegerTransformer"];
#endif
	
	// register default date behavior
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	[NSNumberFormatter setDefaultFormatterBehavior:NSNumberFormatterBehavior10_4];
}

- (id)init {
	if ((self = [super init])) {
		[SEObject _setSharedSenutiInstance:self];
	}
	return self;
}


- (NSString *)senutiApplicationSupportFolder {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *appSupportDirectory = nil;
	if ([paths count] == 1) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		BOOL isDirectory = NO;

		appSupportDirectory = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Senuti"];
		if (![fileManager fileExistsAtPath:appSupportDirectory isDirectory:&isDirectory]) {
			if (![fileManager createDirectoryAtPath:appSupportDirectory attributes:nil]) { return nil; }
		} else {
			if (!isDirectory) {
				return nil;
			}
		}
		return appSupportDirectory;
	}
	return nil;
}

- (SEMenuController *)menuController {
	return menuController;
}

- (SEInterfaceController *)interfaceController {
	return interfaceController;
}

- (SELibraryController *)libraryController {
	return libraryController;
}

- (SEUpdateController *)updateController {
	return updateController;
}

- (SECopyController *)copyController {
	return copyController;
}

- (SEAudioController *)audioController {
	return audioController;
}

- (SEApplescriptController *)applescriptController {
	return applescriptController;
}

- (void)setupControllers {
	if (!controllersSetup) {
		libraryController = [[SELibraryController alloc] init];
		updateController = [[SEUpdateController alloc] init];
		copyController = [[SECopyController alloc] init];
		audioController = [[SEAudioController alloc] init];
		applescriptController = [[SEApplescriptController alloc] init];
		
		[updateController controllerDidLoad]; // register for updates first
		[libraryController controllerDidLoad]; // load the data setup as soon as possible
		[menuController controllerDidLoad];	
		[interfaceController controllerDidLoad]; // make sure data is loaded first
		[copyController controllerDidLoad];
		[audioController controllerDidLoad];
		[applescriptController controllerDidLoad];

		controllersSetup = TRUE;
	}
}

- (void)tearDownControllers {
	if (!controllersTornDown) {
		[applescriptController controllerWillClose];
		[audioController controllerWillClose];
		[copyController controllerWillClose];
		[interfaceController controllerWillClose];
		[menuController controllerWillClose];
		[libraryController controllerWillClose];
		[updateController controllerWillClose];		

		[libraryController release];
		libraryController = nil;
		[updateController release];
		updateController = nil;
		[copyController release];
		copyController = nil;
		[audioController release];
		audioController = nil;
		[applescriptController release];
		applescriptController = nil;

		controllersTornDown = TRUE;
	}
}

#pragma mark application delegate
// ----------------------------------------------------------------------------------------------------
// application delegate
// ----------------------------------------------------------------------------------------------------

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
#ifdef RELEASE
#ifndef UNIT_TEST
#warning CrashReporter enabled
	[AICrashController enableCrashCatching];
	[AIExceptionController enableExceptionCatching];
#endif
#endif
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
	if (!flag) { [interfaceController showMainWindow:nil]; }
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)sender {
	[self tearDownControllers];
}

- (void)awakeFromNib {
	[self setupControllers];
}


#pragma mark interface methods
// ----------------------------------------------------------------------------------------------------
// interface methods
// ----------------------------------------------------------------------------------------------------

- (IBAction)showAboutBox:(id)sender {
#ifndef UNIT_TEST
	[[FSAboutBoxController aboutBoxController] setHomepage:@"http://www.fadingred.org/senuti/"];
	[[FSAboutBoxController aboutBoxController] setBuildInfoDisplayKeys:[NSArray arrayWithObjects:@"build_date", @"build_revision", nil]];
	[[FSAboutBoxController aboutBoxController] showWindow:nil];
#endif
}

- (IBAction)checkForUpdates:(id)sender {
	[updateController checkForUpdates:sender];
}

#pragma mark information
// ----------------------------------------------------------------------------------------------------
// information
// ----------------------------------------------------------------------------------------------------

- (NSImage *)iTunesApplicationIcon {	
	NSString *iTunesPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes"];
	if (iTunesPath) {
		return [[NSWorkspace sharedWorkspace] iconForFile:iTunesPath];
	} else {
		return [NSImage imageNamed:@"itunes_icon"];
	}
}


@end