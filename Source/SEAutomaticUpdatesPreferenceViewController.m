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

#import "SEAutomaticUpdatesPreferenceViewController.h"
#import <Sparkle/Sparkle.h>

NSString *SECheckForUpdatesPreferenceKey = @"SECheckForUpdates";
NSString *SECheckForUpdatesIntervalPreferenceKey = @"SECheckForUpdatesInterval";
NSString *SECheckForUpdatesTypePreferenceKey = @"SECheckForUpdatesType";
NSString *SESendAnonymousInformationPreferenceKey = @"SESendAnonymousInformation";

@implementation SEAutomaticUpdatesPreferenceViewController

+ (void)registerDefaults {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:YES], SECheckForUpdatesPreferenceKey,
		[NSNumber numberWithInt:0], SECheckForUpdatesIntervalPreferenceKey,
#ifdef BETA
		[NSNumber numberWithInt:1], SECheckForUpdatesTypePreferenceKey,
#else
		[NSNumber numberWithInt:0], SECheckForUpdatesTypePreferenceKey,
#endif
		[NSNumber numberWithBool:TRUE], SESendAnonymousInformationPreferenceKey,
		nil]];	
}

+ (NSString *)nibName {
	return @"AutomaticUpdatesPreferences";
}

- (id)init {
	if ((self = [super init])) {
		[[senuti updateController] addStartStopObserver:self];
	}
	return self;
}

- (void)dealloc {
	[[senuti updateController] removeStartStopObserver:self];
	[super dealloc];
}

- (NSString *)label {
	return FSLocalizedString(@"Updates", nil);
}

- (NSImage *)image {
	return [NSImage imageNamed:@"pref_updates"];
}

- (void)awakeFromNib {	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[lastUpdateCheckDateField setFormatter:dateFormatter];
	[lastUpdateCheckDateField bind:@"value" toObject:[NSUserDefaults standardUserDefaults] withKeyPath:@"SULastCheckTime" options:[NSDictionary dictionaryWithObjectsAndKeys:FSLocalizedString(@"Never", nil), NSNullPlaceholderBindingOption, nil]];
}

- (IBAction)checkForUpdates:(id)sender {
	[checkForUpdatesSpinner startAnimation:nil];
	[[senuti updateController] checkForUpdates:nil];
}

- (void)updateStart:(id)updater { }

- (void)updateStop:(id)updater {
	[checkForUpdatesSpinner stopAnimation:nil];
}

@end
