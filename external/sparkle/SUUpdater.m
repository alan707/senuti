//
//  SUUpdater.m
//  Sparkle
//
//  Created by Whitney Young on 8/8/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SUUpdater.h"
#import "SUUtilities.h"

@implementation SUUpdater

- (id)init {
	if ((self = [super init])) {
		// if the user default for SUCheckAtStartupKey hasn't been set, then this is the first check
		firstCheck = ![[NSUserDefaults standardUserDefaults] objectForKey:SUCheckAtStartupKey];
	}
	return self;
}

- (IBAction)checkForUpdates:sender {
	[super checkForUpdates:sender];
}

- (void)checkForUpdatesInBackground {
	[super checkForUpdatesInBackground];
}

- (void)scheduleCheckWithInterval:(NSTimeInterval)interval {
	[super scheduleCheckWithInterval:interval];
}

- (BOOL)showReleaseNotesForUpdateAlert:(id)alert
{
	id value = SUInfoValueForKey(SUShowReleaseNotesKey);
	if (!value) { return YES; } // defaults to YES
	return [value boolValue];
}

- (BOOL)allowAutomaticUpdateForUpdateAlert:(id)alert
{
	id expectsDSAValue = SUInfoValueForKey(SUExpectsDSASignatureKey);
	id allowsAutoUpdateValue = SUInfoValueForKey(SUAllowsAutomaticUpdatesKey);
	if (!expectsDSAValue) { return NO; } // automatic updating requires DSA-signed updates
	if (!allowsAutoUpdateValue) { return YES; } // defaults to YES
	return [allowsAutoUpdateValue boolValue];
}

- (NSString *)appcastURL {
	// A value in the user defaults overrides one in the Info.plist (so preferences panels can be created wherein users choose between beta / release feeds).
	NSString *appcastString = [[NSUserDefaults standardUserDefaults] objectForKey:SUFeedURLKey];
	if (!appcastString) { appcastString = SUInfoValueForKey(SUFeedURLKey); }
	if (!appcastString) { [NSException raise:@"SUNoFeedURL" format:@"No feed URL is specified in the Info.plist or the user defaults!"]; }
	return appcastString;
}

- (SUFirstCheckType)firstCheckAction {
	NSNumber *pref = SUInfoValueForKey(SUCheckAtStartupKey);
	if (pref) {
		// if a value was set in the Info.plist file, then we do what it says
		if ([pref boolValue]) {
			return SUFirstRunPerformCheck;
		} else {
			return SUFirstRunNoCheck;
		}
	} else {
		// if a value wasn't set in the Info.plist file, then we ask
		return SUFirstRunAsk;
	}
}

- (BOOL)automaticallyUpdates
{
	id value = SUInfoValueForKey(SUAllowsAutomaticUpdatesKey);
	if (![value boolValue] && [value boolValue]) { return NO; }
	if (![[NSUserDefaults standardUserDefaults] objectForKey:SUAutomaticallyUpdateKey]) { return NO; } // defaults to NO
	return [[[NSUserDefaults standardUserDefaults] objectForKey:SUAutomaticallyUpdateKey] boolValue];
}

- (NSTimeInterval)checkInterval {
	id value;
	
	value = [[NSUserDefaults standardUserDefaults] objectForKey:SUScheduledCheckIntervalKey];
	if (value) {
		long interval = [value longValue];
		if (interval > 0) { return interval; }
	}
	
	value = SUInfoValueForKey(SUScheduledCheckIntervalKey);
	if (value) { return [value longValue]; }
	
	return 0;
}

- (NSString *)skippedVersion {
	return [[NSUserDefaults standardUserDefaults] objectForKey:SUSkippedVersionKey];
}

- (NSDate *)lastCheck {
	NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:SULastCheckTimeKey];
	return (date ? date : [NSDate date]);
}

- (BOOL)shouldCheckAtStartup {
	return [[[NSUserDefaults standardUserDefaults] objectForKey:SUCheckAtStartupKey] boolValue];
}

- (BOOL)isFirstCheck {
	return firstCheck;
}

- (void)saveSkippedVersion:(NSString *)version {
	[[NSUserDefaults standardUserDefaults] setObject:version forKey:SUSkippedVersionKey];
}

- (void)saveLastCheck:(NSDate *)date {
	[[NSUserDefaults standardUserDefaults] setObject:date forKey:SULastCheckTimeKey];
}

- (void)saveShouldCheckAtStartup:(BOOL)flag {
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:flag] forKey:SUCheckAtStartupKey];
}

- (BOOL)DSAEnabled {
	return [SUInfoValueForKey(SUExpectsDSASignatureKey) boolValue];
}

- (NSString *)DSAPublicKey {
	return SUInfoValueForKey(SUPublicDSAKeyKey);
}

@end
