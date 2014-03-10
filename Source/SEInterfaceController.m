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

#import "SEInterfaceController.h"
#import "SEMainWindowController.h"
#import "SECopyProgressWindowController.h"
#import "SEPreferenceWindowController.h"
#import "SESetupAssistantWindowController.h"
#import "SETrackInfoWindowController.h"
#import "SERegistrationWindowController.h"

#import "SEControllerObserver.h"

NSString *SECompletedSetupKey = @"SECompletedSetupKey";

@implementation SEInterfaceController

+ (void)initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:FALSE], SECompletedSetupKey, nil]];
}

- (void)dealloc {
	[mainWindowController release];
	[preferenceWindowController release];
	[copyProgressWindowController release];
	[trackInfoWindowController release];
	[registrationWindowController release];
	
	[super dealloc];
}

- (void)controllerDidLoad {
	trackInfoWindowController = [[SETrackInfoWindowController alloc] init];
	registrationWindowController = [[SERegistrationWindowController alloc] init];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:SECompletedSetupKey]) {
		[self showMainWindow:nil];
		
	} else {
		[SESetupAssistantWindowController runSetupAssistantWithDelegate:self
														 didEndSelector:@selector(finishedSetupAssistant:)
													 didDismissSelector:@selector(dismissedSetupAssistant:)];		
	}
}

- (void)finishedSetupAssistant:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:SECompletedSetupKey];
	[self showMainWindow:nil];
}

- (void)dismissedSetupAssistant:(id)sender {
	[NSApp terminate:nil];
}

- (void)controllerWillClose {
	[mainWindowController removeControllerObservers];
	[copyProgressWindowController removeControllerObservers];
	[trackInfoWindowController removeControllerObservers];
}

- (SEMainWindowController *)mainWindowController {
	if (!mainWindowController) {
		// create the window and also set the autosave name
		mainWindowController = [[SEMainWindowController alloc] init];
		// using setAutosaveName and NOT setFrameAutosaveName so that
		// autosave information is passed on to other controllers
		[mainWindowController setAutosaveName:@"Main Window"];
	}
	return mainWindowController;
}

- (SECopyProgressWindowController *)copyProgressWindowController {
	if (!copyProgressWindowController) {
		copyProgressWindowController = [[SECopyProgressWindowController alloc] init];
	}
	return copyProgressWindowController;
}

- (NSWindow *)mainWindow {
	return [[self mainWindowController] window];
}

- (IBAction)showMainWindow:(id)sender {
	[[self mainWindow] makeKeyAndOrderFront:nil];
}

- (IBAction)showProgressWindow:(id)sender {
	NSWindow *window = [[self copyProgressWindowController] window];
	if ([window isVisible]) { [window orderOut:nil]; }
	else { [window orderFront:nil]; }
}

- (IBAction)showTrackInfo:(id)sender {
	[[trackInfoWindowController window] makeKeyAndOrderFront:nil];
}

- (IBAction)showRegistration:(id)sender {
	[[registrationWindowController window] makeKeyAndOrderFront:nil];
}

- (IBAction)showPreferences:(id)sender {
	[SEPreferenceWindowController openPreferenceWindow:nil];
}

@end
