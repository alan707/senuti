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

#import <Sparkle/Sparkle.h>
#import "SEUpdateURLMacros.h"

#import "SEUpdateController.h"
#import "SEAutomaticUpdatesPreferenceViewController.h"

#define BETA_UPDATE_CHECK_FULL_URL	[NSString stringWithFormat:@"%@?version=%@", BETA_UPDATE_CHECK_URL, SUHostAppVersion()]
#define UPDATE_CHECK_FULL_URL		[NSString stringWithFormat:@"%@?version=%@", UPDATE_CHECK_URL, SUHostAppVersion()]

@interface SEUpdateController (PRIVATE)
- (NSString *)appendProfileInfoToURLString:(NSString *)appcastString;
- (NSMutableArray *)systemProfileInformationArray;
@end

@implementation SEUpdateController

- (void)controllerDidLoad {
	updater = [(SUDelegatedUpdater *)[SUDelegatedUpdater alloc] initWithDelegate:self];
	observers = [[NSMutableArray alloc] init];
	[updater applicationDidFinishLaunching:nil];
}

- (void)controllerWillClose {
	[updater release];
	[observers release];
}

- (IBAction)checkForUpdates:(id)sender {
	id <SEUpdateControllerStartStopObserverProtocol> object;
	NSEnumerator *enumerator = [observers objectEnumerator];
	while (object = [enumerator nextObject]) { [object updateStart:updater]; }
	[updater checkForUpdates:sender];
}

- (NSTimeInterval)checkInterval {
	NSNumber *checkForUpdates = [[NSUserDefaults standardUserDefaults] objectForKey:@"SECheckForUpdates"];
	if ([checkForUpdates boolValue]) {
		NSNumber *interval = [[NSUserDefaults standardUserDefaults] objectForKey:SECheckForUpdatesIntervalPreferenceKey];
		switch ([interval intValue]) {
			case 1:
				return 60 * 60 * 24 * 7;
				break;
			case 0:
			default:
				return 60 * 60 * 24;
				break;
		}
	} else {
		return 0;
	}	
}

- (NSString *)appcastURL {
	NSString *appcastURL = nil;

#ifdef BETA
	// always check for beta updates when they're running a beta
	appcastURL = BETA_UPDATE_CHECK_FULL_URL;
#else
	switch ([[NSUserDefaults standardUserDefaults] integerForKey:SECheckForUpdatesTypePreferenceKey]) {
		case 1:
			appcastURL = BETA_UPDATE_CHECK_FULL_URL;
			break;
		case 0:
		default:
			appcastURL = UPDATE_CHECK_FULL_URL;
			break;
	}
#endif
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:SESendAnonymousInformationPreferenceKey]) {
		appcastURL = [appcastURL stringByAppendingFormat:@"&%@", [FSSystem encodedProfileURLString]];
	}
	return appcastURL;
}

- (void)addStartStopObserver:(id <SEUpdateControllerStartStopObserverProtocol>)observer {
	[observers addObject:observer];
	[(NSObject *)observer release];
}
- (void)removeStartStopObserver:(id <SEUpdateControllerStartStopObserverProtocol>)observer {
	[(NSObject *)observer retain];
	[observers removeObjectIdenticalTo:observer];
}

#pragma mark sparkle delegate
// ----------------------------------------------------------------------------------------------------
// sparkle delegate
// ----------------------------------------------------------------------------------------------------

- (NSTimeInterval)checkIntervalForUpdater:(SUDelegatedUpdater *)updater {
	return [self checkInterval];
}

- (NSString *)appcastURLForUpdater:(SUDelegatedUpdater *)updater {
	return [self appcastURL];
}

- (BOOL)updater:(id)theUpdater shouldContinueAfterRecievingVersion:(NSString *)versionString isNew:(BOOL)flag {
	id <SEUpdateControllerStartStopObserverProtocol> object;
	NSEnumerator *enumerator = [observers objectEnumerator];
	while (object = [enumerator nextObject]) { [object updateStop:theUpdater]; }
	return YES;
}
- (BOOL)updaterShouldContinueAfterFailingToRecievingVersion:(id)theUpdater {
	id <SEUpdateControllerStartStopObserverProtocol> object;
	NSEnumerator *enumerator = [observers objectEnumerator];
	while (object = [enumerator nextObject]) { [object updateStop:theUpdater]; }
	return YES;
}	

@end
