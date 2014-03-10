//
//  SUDelegatedUpdater.h
//  Sparkle
//
//  Created by Whitney Young on 8/21/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SUUpdater.h"

// This class provides a bunch of delegate calls to an object to controll how the updater will work
@interface SUDelegatedUpdater : SUUpdater {
	id delegate;
}

- (id)initWithDelegate:(id)delegate;

@end


@interface NSObject (SUUpdaterDelegate)

- (BOOL)updater:(id)updater shouldContinueAfterExtractingUpdateAtPath:(NSString *)path;
- (BOOL)updater:(id)updater shouldContinueAfterDownloadingFileToPath:(NSString *)path;
- (BOOL)updater:(id)updater shouldContinueAfterRecievingVersion:(NSString *)versionString isNew:(BOOL)flag;
- (BOOL)updaterShouldContinueAfterFailingToRecievingVersion:(id)updater;

- (NSString *)titleTextForUpdateAlert:(id)alert;
- (NSString *)descriptionTextForUpdateAlert:(id)alert;
- (BOOL)showReleaseNotesForUpdateAlert:(id)alert;
- (BOOL)allowAutomaticUpdateForUpdateAlert:(id)alert;
- (BOOL)displayCancelButtonForUpdateAlert:(id)alert;

// if the delegate implements any of these, they override the
// default settings
- (NSString *)appcastURLForUpdater:(SUDelegatedUpdater *)updater;
- (SUFirstCheckType)firstCheckActionForUpdater:(SUDelegatedUpdater *)updater;
- (BOOL)automaticallyUpdatesForUpdater:(SUDelegatedUpdater *)updater;
- (NSTimeInterval)checkIntervalForUpdater:(SUDelegatedUpdater *)updater;
- (NSString *)skippedVersionForUpdater:(SUDelegatedUpdater *)updater;
- (NSDate *)lastCheckForUpdater:(SUDelegatedUpdater *)updater;
- (BOOL)shouldCheckAtStartupForUpdater:(SUDelegatedUpdater *)updater;
- (BOOL)DSAEnabledForUpdater:(SUDelegatedUpdater *)updater;
- (NSString *)DSAPublicKeyForUpdater:(SUDelegatedUpdater *)updater;

// if the delegate implements any of these, they override the
// save methods for the default settings
- (void)saveSkippedVersion:(NSString *)version forUpdater:(SUDelegatedUpdater *)updater;
- (void)saveLastCheck:(NSDate *)lastCheck forUpdater:(SUDelegatedUpdater *)updater;
- (void)saveShouldCheckAtStartup:(BOOL)flag forUpdater:(SUDelegatedUpdater *)updater;

@end