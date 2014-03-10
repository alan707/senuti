//
//  SUUpdater.h
//  Sparkle
//
//  Created by Andy Matuschak on 1/4/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SUUpdateAlert.h"
#import "SUStatusController.h"

typedef enum _SUFirstCheckType
{
	SUFirstRunAsk,
	SUFirstRunPerformCheck,
	SUFirstRunNoCheck
} SUFirstCheckType;

@class SUAppcastItem, SUUpdateAlert, SUStatusController, SUSampler;
@interface SUBaseUpdater : NSObject <SUUpdateAlertDelegateProtocol, SUStatusControllerDelegateProtocol> {
	SUAppcastItem *updateItem;
	
	SUStatusController *statusController;
	SUUpdateAlert *updateAlert;
	
	NSURLDownload *downloader;
	NSString *downloadPath;
    SUSampler *sampler; // Whitney Young (and added SUSampler to @class above)
	NSTimer *checkTimer;
	
	BOOL verbose;
	BOOL updateInProgress;
	NSTimeInterval checkInterval;
	

	NSString *skippedVersion;
	NSDate *lastCheck;
	BOOL shouldCheckAtStartup;
}

+ (NSComparisonResult)compareVersion:(NSString *)first toVersion:(NSString *)second; // Override this to change the new version comparison logic!

// These are the main methods used.  Check SUUpdater for more information.
- (IBAction)checkForUpdates:(id)sender;
- (void)checkForUpdatesInBackground;
- (void)scheduleCheckWithInterval:(NSTimeInterval)interval;



// information for subclassers (only use these if you know how
// sparkle works and you're subclassing SUBaseUpdater)
- (BOOL)isAutomaticallyUpdating;
- (BOOL)newVersionAvailable;
- (NSString *)downloadPath;

// These public methods are not intended for use.  They are provided for subclassers
// and some are required for subclasses to implement.
- (NSString *)appcastURL;
- (SUFirstCheckType)firstCheckAction;
- (BOOL)automaticallyUpdates;
- (NSTimeInterval)checkInterval;
- (NSString *)skippedVersion;
- (NSDate *)lastCheck;
- (BOOL)shouldCheckAtStartup;
- (BOOL)isFirstCheck; // never a first check unless a subclass handles it

- (void)saveSkippedVersion:(NSString *)version;
- (void)saveLastCheck:(NSDate *)lastCheck;
- (void)saveShouldCheckAtStartup:(BOOL)flag;

- (NSString *)applicationName;
- (NSString *)applicationDisplayName;
- (NSString *)applicationPath;
- (NSString *)applicationVersion;
- (NSString *)applicationVersionString;
- (NSString *)CFBundleName;
- (NSImage *)applicationIcon;

- (BOOL)DSAEnabled; // returns FALSE by default
- (NSString *)DSAPublicKey; // returns nil by default

- (NSTimeInterval)remindMeLaterDefaultInterval;
- (BOOL)newVersionAvailable; // Override this to change the new version comparison logic

@end