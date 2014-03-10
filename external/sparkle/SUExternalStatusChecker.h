//
//  SUExternalStatusChecker.h
//  Sparkle
//
//  Created by Whitney Young on 8/8/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SUExternalUpdater.h"

@class SUExternalStatusChecker;

@protocol SUExternalStatusCheckerDelegate <NSObject>
//versionString will be nil and isNewVersion will be NO if version checking fails.
- (void)statusChecker:(SUExternalStatusChecker *)statusChecker foundVersion:(NSString *)versionString isNewVersion:(BOOL)isNewVersion;
@end

@interface SUExternalStatusChecker : SUExternalUpdater {
	id<SUExternalStatusCheckerDelegate> scDelegate;
}

// Create a status checker which will notifiy delegate once the appcast version is determined.
// Notification occurs via the method defined in the SUStatusCheckerDelegate informal protocol.
+ (SUExternalStatusChecker *)statusCheckerFor:(NSString *)appPath delegate:(id<SUExternalStatusCheckerDelegate>)delegate;

@end