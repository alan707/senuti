//
//  SUExternalStatusChecker.m
//  Sparkle
//
//  Created by Whitney Young on 8/8/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SUExternalStatusChecker.h"
#import "SUAppcast.h"
#import "SUAppcastItem.h"

@interface SUExternalStatusChecker (Private)
- (id)initFor:(NSString *)path delegate:(id<SUExternalStatusCheckerDelegate>)inDelegate;
- (void)checkForUpdatesAndNotify:(BOOL)flag;
- (void)beginDownload;
- (BOOL)newVersionAvailable;
@end;

@implementation SUExternalStatusChecker

+ (SUExternalStatusChecker *)statusCheckerFor:(NSString *)path delegate:(id<SUExternalStatusCheckerDelegate>)inDelegate;
{
	SUExternalStatusChecker *statusChecker = [[self alloc] initFor:path delegate:inDelegate];
	
	return [statusChecker autorelease];
}

- (id)initFor:(NSString *)path delegate:(id<SUExternalStatusCheckerDelegate>)inDelegate
{
	[super initWithAppPath:path];
	
	scDelegate = [inDelegate retain];
	
	[self checkForUpdatesAndNotify:NO];
	
	return self;
}

- (void)dealloc
{
	[scDelegate release]; scDelegate = nil;
	
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
	//Take no action when the application finishes launching
}

- (void)appcastDidFinishLoading:(SUAppcast *)ac
{
	@try
	{
		if (!ac) { [NSException raise:@"SUAppcastException" format:@"Couldn't get a valid appcast from the server."]; }
		
		updateItem = [ac newestItem];		
		if (![updateItem fileVersion])
		{
			[NSException raise:@"SUAppcastException" format:@"Can't extract a version string from the appcast feed. The filenames should look like YourApp_1.5.tgz, where 1.5 is the version number."];
		}
		
		[scDelegate statusChecker:self
					 foundVersion:[updateItem fileVersion]
					 isNewVersion:[self newVersionAvailable]];
	}
	@catch (NSException *e)
	{
		NSLog([e reason]);
		[scDelegate statusChecker:self foundVersion:nil isNewVersion:NO];	
	}
	
	updateInProgress = NO;
}

@end
