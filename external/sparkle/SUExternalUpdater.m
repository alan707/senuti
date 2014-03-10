//
//  SUUpdater.m
//  Sparkle
//
//  Created by Whitney Young on 8/8/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SUExternalUpdater.h"
#import "SUUtilities.h"
#import "SUUtilities.h"

@interface SUExternalUpdater (PRIVATE)
- (NSString *)applicationIdentifier;
@end

@implementation SUExternalUpdater

- (id)init {
	[NSException raise:@"SUExternalUpdaterCannotInit" format:@"SUExternalUpdater requires that you call initWithAppPath: and not init"];
	return nil;
}

- (id)initWithAppPath:(NSString *)path {
	if ((self = [super init])) {
		// if the user default for SUCheckAtStartupKey hasn't been set, then this is the first check
		appPath = [path retain];
		firstCheck = ![[[NSUserDefaults standardUserDefaults] persistentDomainForName:[self applicationIdentifier]] objectForKey:SUCheckAtStartupKey];
	}
	return self;
}

- (void)dealloc {
	[appPath release];
	[appIdent release];
	[super dealloc];
}

- (NSString *)applicationIdentifier {
	if (!appIdent) { appIdent = [[[NSBundle bundleWithPath:appPath] objectForInfoDictionaryKey:@"CFBundleIdentifier"] retain]; }
	return appIdent;
}

- (NSString *)applicationName
{
	return SUForeignAppName(appPath);
}

- (NSString *)applicationDisplayName
{
	return SUForeignAppDisplayName(appPath);
}

- (NSString *)applicationPath
{
	return appPath;
}

- (NSString *)applicationVersion
{
	return SUForeignAppVersion(appPath);
}

- (NSString *)applicationVersionString
{
	return SUForeignAppVersionString(appPath);
}

- (NSString *)CFBundleName
{
	return SUForeignInfoValueForKey(appPath, @"CFBundleName");
}

- (NSImage *)applicationIcon {
	NSString *imageName = SUForeignInfoValueForKey(appPath, @"CFBundleIconFile");
	NSString *imagePath = [[NSBundle bundleWithPath:appPath] pathForImageResource:imageName];
	return [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
}

- (BOOL)showReleaseNotesForUpdateAlert:(id)alert
{
	id value = SUForeignInfoValueForKey(appPath, SUShowReleaseNotesKey);
	if (!value) { return YES; } // defaults to YES
	return [value boolValue];
}

- (BOOL)allowAutomaticUpdateForUpdateAlert:(id)alert
{
	id expectsDSAValue = SUForeignInfoValueForKey(appPath, SUExpectsDSASignatureKey);
	id allowsAutoUpdateValue = SUForeignInfoValueForKey(appPath, SUAllowsAutomaticUpdatesKey);
	if (!expectsDSAValue) { return NO; } // automatic updating requires DSA-signed updates
	if (!allowsAutoUpdateValue) { return YES; } // defaults to YES
	return [allowsAutoUpdateValue boolValue];
}

- (NSString *)appcastURL {
	// A value in the user defaults overrides one in the Info.plist (so preferences panels can be created wherein users choose between beta / release feeds).
	NSString *appcastString = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:[self applicationIdentifier]] objectForKey:SUFeedURLKey];
	if (!appcastString) { appcastString = SUForeignInfoValueForKey(appPath, SUFeedURLKey); }
	if (!appcastString) { [NSException raise:@"SUNoFeedURL" format:@"No feed URL is specified in the Info.plist or the user defaults!"]; }	
	return appcastString;
}

- (SUFirstCheckType)firstCheckAction {
	NSNumber *pref = SUForeignInfoValueForKey(appPath, SUCheckAtStartupKey);
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
	id value = SUForeignInfoValueForKey(appPath, SUAllowsAutomaticUpdatesKey);
	if (![value boolValue] && [value boolValue]) { return NO; }
	if (![[[NSUserDefaults standardUserDefaults] persistentDomainForName:[self applicationIdentifier]] objectForKey:SUAutomaticallyUpdateKey]) { return NO; } // defaults to NO
	return [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:[self applicationIdentifier]] objectForKey:SUAutomaticallyUpdateKey] boolValue];
}

- (NSTimeInterval)checkInterval {
	id value;
	
	value = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:[self applicationIdentifier]] objectForKey:SUScheduledCheckIntervalKey];
	if (value) {
		long interval = [value longValue];
		if (interval > 0) { return interval; }
	}
	
	value = SUForeignInfoValueForKey(appPath, SUScheduledCheckIntervalKey);
	if (value) { return [value longValue]; }
	
	return 0;
}

- (NSString *)skippedVersion {
	return [[[NSUserDefaults standardUserDefaults] persistentDomainForName:[self applicationIdentifier]] objectForKey:SUSkippedVersionKey];
}

- (NSDate *)lastCheck {
	NSDate *date = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:[self applicationIdentifier]] objectForKey:SULastCheckTimeKey];
	return (date ? date : [NSDate date]);
}

- (BOOL)shouldCheckAtStartup {
	return [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:[self applicationIdentifier]] objectForKey:SUCheckAtStartupKey] boolValue];
}

- (BOOL)isFirstCheck {
	return firstCheck;
}

- (void)saveSkippedVersion:(NSString *)version {
	// Take no action.  Not going to set preferences for another application.
}

- (void)saveLastCheck:(NSDate *)date {
	// Take no action.  Not going to set preferences for another application.
}

- (void)saveShouldCheckAtStartup:(BOOL)flag {
	// Take no action.  Not going to set preferences for another application.
}

- (BOOL)DSAEnabled {
	return [SUForeignInfoValueForKey(appPath, SUExpectsDSASignatureKey) boolValue];
}

- (NSString *)DSAPublicKey {
	return SUForeignInfoValueForKey(appPath, SUPublicDSAKeyKey);
}

@end
