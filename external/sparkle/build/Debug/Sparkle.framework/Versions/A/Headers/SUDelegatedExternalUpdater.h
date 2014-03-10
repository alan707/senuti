//
//  SUDelegatedExternalUpdater.h
//  Sparkle
//
//  Created by Whitney Young on 8/8/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SUExternalUpdater.h"

// This class provides a bunch of delegate calls to an object to controll how the updater will work
@interface SUDelegatedExternalUpdater : SUExternalUpdater {
	id delegate;
}

- (id)initWithAppPath:(NSString *)path delegate:(id)delegate;

@end


@interface NSObject (SUExternalUpdaterDelegate)

- (BOOL)updater:(SUDelegatedExternalUpdater *)updater shouldContinueAfterExtractingUpdateAtPath:(NSString *)path;
- (BOOL)updater:(SUDelegatedExternalUpdater *)updater shouldContinueAfterDownloadingFileToPath:(NSString *)path;
- (BOOL)updater:(SUDelegatedExternalUpdater *)updater shouldContinueAfterRecievingVersion:(NSString *)versionString isNew:(BOOL)flag;
- (BOOL)updaterShouldContinueAfterFailingToRecievingVersion:(id)updater;

- (NSString *)titleTextForUpdateAlert:(id)alert;
- (NSString *)descriptionTextForUpdateAlert:(id)alert;
- (BOOL)showReleaseNotesForUpdateAlert:(id)alert;
- (BOOL)allowAutomaticUpdateForUpdateAlert:(id)alert;
- (BOOL)displayCancelButtonForUpdateAlert:(id)alert;

@end