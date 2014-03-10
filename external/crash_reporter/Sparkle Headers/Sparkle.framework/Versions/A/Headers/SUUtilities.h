//
//  SUUtilities.h
//  Sparkle
//
//  Created by Andy Matuschak on 3/12/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

id SUInfoValueForKey(NSString *key);
NSString *SUHostAppName();
NSString *SUHostAppDisplayName();
NSString *SUHostAppVersion();
NSString *SUHostAppVersionString();

id SUForeignInfoValueForKey(NSString *appPath, NSString *key);
NSString *SUForeignAppName(NSString *appPath);
NSString *SUForeignAppDisplayName(NSString *appPath);
NSString *SUForeignAppVersion(NSString *appPath);
NSString *SUForeignAppVersionString(NSString *appPath);

NSComparisonResult SUStandardVersionComparison(NSString * versionA, NSString * versionB);

// If running make localizable-strings for genstrings, ignore the error on this line.
NSString *SULocalizedString(NSString *key, NSString *comment);
