//
//  SUUpdater.m
//  Sparkle
//
//  Created by Andy Matuschak on 1/4/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUBaseUpdater.h"
#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SUUnarchiver.h"
#import "SUUtilities.h"
#import "SUSampler.h" // July 2006 Whitney Young (Interface)

#import "SUAutomaticUpdateAlert.h"

#import "NSFileManager+Authentication.h"
#import "NSFileManager+Verification.h"
#import "NSApplication+AppCopies.h"
#import "NSString+extras.h" // July 2006 Whitney Young (Interface)

#import <stdio.h>
#import <sys/stat.h>
#import <unistd.h>
#import <signal.h>
#import <dirent.h>

@interface SUBaseUpdater (Private)
- (void)checkForUpdatesAndNotify:(BOOL)verbosity;
- (void)showUpdateErrorAlertWithInfo:(NSString *)info;
- (IBAction)remindMeLater:(id)sender;
- (void)beginDownload;
- (void)abandonUpdate;
- (void)extractUpdate;
// July 2006 Whitney Young (Ease of Use)
//- (IBAction)installAndRestart:sender;
- (IBAction)install:sender;
- (IBAction)restart:sender;

// July 2006 Whitney Young (Memory Management)
- (void)setUpdateItem:(SUAppcastItem *)anUpdateItem;
- (void)setStatusController:(SUStatusController *)aStatusController;
- (void)setUpdateAlert:(SUUpdateAlert *)anUpdateAlert;
- (void)setDownloader:(NSURLDownload *)aDownloader;
- (void)setDownloadPath:(NSString *)aDownloadPath;
- (void)setSampler:(SUSampler *)aSampler;
- (void)setCheckTimer:(NSTimer *)aCheckTimer;
@end

@implementation SUBaseUpdater

+ (NSComparisonResult)compareVersion:(NSString *)first toVersion:(NSString *)second
{
	return SUStandardVersionComparison(first, second);
	// Want straight-up string comparison like Sparkle 1.0b3 and earlier? Uncomment the line below and comment the one above.
	// return ![first isEqualToString:second];
}

- (id)init
{
	[super init];
	shouldCheckAtStartup = FALSE;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:@"NSApplicationDidFinishLaunchingNotification" object:NSApp];	
	return self;
}

- (void)dealloc
{
	[updateItem release];
    [updateAlert release];
	
	[downloadPath release];
	[statusController release];
	[downloader release];
	
	if (checkTimer)
		[checkTimer invalidate];
    [checkTimer release]; // July 2006 Whitney Young (Memory Management)
    [sampler release]; // July 2006 Whitney Young (Interface)
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark initial action

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
	// If there's a scheduled interval, we see if it's been longer than that interval since the last
	// check. If so, we perform a startup check; if not, we don't.	
	if ([self checkInterval])
	{
		NSTimeInterval interval = [self checkInterval];
		NSTimeInterval intervalSinceCheck = [[NSDate date] timeIntervalSinceDate:[self lastCheck]];
		if (intervalSinceCheck < interval)
		{
			// Hasn't been long enough; schedule a check for the future.
			[self performSelector:@selector(checkForUpdatesInBackground) withObject:nil afterDelay:intervalSinceCheck];
			[self performSelector:@selector(scheduleCheckWithIntervalObject:) withObject:[NSNumber numberWithLong:interval] afterDelay:intervalSinceCheck];
		}
		else
		{
			[self scheduleCheckWithInterval:interval];
			[self checkForUpdatesInBackground];
		}
	}
	else
	{
		// There's no scheduled check, so let's see if we're supposed to check on startup.
		BOOL checkAtStartup = FALSE;
		if ([self isFirstCheck])
		{
			SUFirstCheckType action = [self firstCheckAction];
			if (action == SUFirstRunAsk)
			{
				checkAtStartup = NSRunAlertPanel(SULocalizedString(@"Check for updates on startup?", nil),
												 [NSString stringWithFormat:
													 SULocalizedString(@"Would you like %@ to check for updates on startup? If not, you can initiate the check manually from the application menu.", nil),
													 [self applicationDisplayName]],
												 SULocalizedString(@"Yes", nil),
												 SULocalizedString(@"No", nil),
												 nil) == NSAlertDefaultReturn;
			}
			else if (action == SUFirstRunPerformCheck)
			{
				checkAtStartup = TRUE;
			}
			else if (action == SUFirstRunNoCheck)
			{
				checkAtStartup = FALSE;
			}
			[self saveShouldCheckAtStartup:checkAtStartup];
		} else {
			checkAtStartup = [self shouldCheckAtStartup];
		}
		
		if ([self shouldCheckAtStartup])
			[self checkForUpdatesInBackground];
	}
}

#pragma mark public interface methods

- (void)scheduleCheckWithInterval:(NSTimeInterval)interval
{
	if (checkTimer)
	{
		[checkTimer invalidate];
		//checkTimer = nil;
        [self setCheckTimer:nil]; // July 2006 Whitney Young (Memory Management)
	}
	
	checkInterval = interval;
	if (interval > 0)
		//checkTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(checkForUpdatesInBackground) userInfo:nil repeats:YES];
        [self setCheckTimer:[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(checkForUpdatesInBackground) userInfo:nil repeats:YES]]; // July 2006 Whitney Young (Memory Management)
}

- (void)checkForUpdatesInBackground
{
	[self checkForUpdatesAndNotify:NO];
}

- (IBAction)checkForUpdates:(id)sender
{
	[self checkForUpdatesAndNotify:YES]; // if we're coming from IB, then we want to be more verbose.
}

#pragma mark convenience methods

- (void)scheduleCheckWithIntervalObject:(NSNumber *)interval
{
	[self scheduleCheckWithInterval:[interval doubleValue]];
}

#pragma mark actions

- (IBAction)remindMeLater:(id)sender
{
	// Clear out the skipped version so the dialog will actually come back if it was already skipped.
	[self saveSkippedVersion:nil];
	
	if (checkInterval)
		[self scheduleCheckWithInterval:checkInterval];
	else
	{
		// If the host hasn't provided a check interval, we'll use the default minutes.
		[self scheduleCheckWithInterval:[self remindMeLaterDefaultInterval]];
	}
}

- (void)showUpdateErrorAlertWithInfo:(NSString *)info
{
	if ([self isAutomaticallyUpdating]) { return; }
	NSRunAlertPanel(SULocalizedString(@"Update Error", nil), info, SULocalizedString(@"Cancel", nil), nil, nil);
}

#pragma mark starting up a check

// If the verbosity flag is YES, Sparkle will say when it can't reach the server and when there's no new update.
// This is generally useful for a menu item--when the check is explicitly invoked.
- (void)checkForUpdatesAndNotify:(BOOL)verbosity
{	
	if (updateInProgress)
	{
		if (verbosity)
		{
			NSBeep();
			if ([[statusController window] isVisible])
				[statusController showWindow:self];
			else if ([[updateAlert window] isVisible])
				[updateAlert showWindow:self];
			else
				[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An update is already in progress", nil)];
		}
		return;
	}
	verbose = verbosity;
	updateInProgress = YES;
	
	NSString *appcastString = [self appcastURL];
    [SUAppcast fetchAppcastFromURL:[NSURL URLWithString:appcastString] delegate:self]; // July 2006 Whitney Young (Memory Management)
}

#pragma mark update alert

- (void)showUpdatePanel
{
	//updateAlert = [[SUUpdateAlert alloc] initWithAppcastItem:updateItem];
    [self setUpdateAlert:[[[SUUpdateAlert alloc] initWithAppcastItem:updateItem delegate:self] autorelease]]; // July 2006 Whitney Young (Memory Management)
	[updateAlert showWindow:self];
}

- (void)updateAlert:(SUUpdateAlert *)alert finishedWithChoice:(SUUpdateAlertChoice)choice
{
	//[alert release];
    // this isn't completely necessary, but now that we know that the alret isn't
    // being used it can be released.  if it's not released here it won't cause any leaks, though
    [self setUpdateAlert:nil]; // July 2006 Whitney Young (Memory Management)
	
	switch (choice)
	{
		case SUInstallUpdateChoice:
			// Clear out the skipped version so the dialog will come back if the download fails.
			[self saveSkippedVersion:nil];
			[self beginDownload];
			break;
			
		case SURemindMeLaterChoice:
			updateInProgress = NO;
			[self remindMeLater:nil];
			break;
			
		case SUSkipThisVersionChoice:
			updateInProgress = NO;
			[self saveSkippedVersion:[updateItem fileVersion]];
			break;

		case SUCancelChoice:
			updateInProgress = NO;
			break;
	}			
}

- (NSString *)titleTextForUpdateAlert:(id)alert
{
	if ([alert isKindOfClass:[SUAutomaticUpdateAlert class]]) {
		return [NSString stringWithFormat:
			SULocalizedString(@"A new version of %@ has been installed", nil),
			[self applicationName]];
	} else {
		return [NSString stringWithFormat:
			SULocalizedString(@"A new version of %@ is available", nil),
			[self applicationName]];		
	}
}

- (NSString *)descriptionTextForUpdateAlert:(id)alert
{
	if ([alert isKindOfClass:[SUAutomaticUpdateAlert class]]) {
		return [NSString stringWithFormat:
			SULocalizedString(@"%@ %@ has been installed and will be ready to use next time %@ starts. Would you like to relaunch now?", nil),
			[self applicationName],
			[updateItem fileVersion],
			[self applicationName]];		
	} else {
		return [NSString stringWithFormat:
			SULocalizedString(@"%@ %@ is now available (you have %@ %@). Would you like to download it now?", nil),
			[self applicationName],
			[updateItem versionString],
			[self applicationName],
			[self applicationVersionString]];		
	}
}

- (BOOL)showReleaseNotesForUpdateAlert:(id)alert
{
	return YES;
}

- (BOOL)allowAutomaticUpdateForUpdateAlert:(id)alert
{
	return NO;
}

- (BOOL)displayCancelButtonForUpdateAlert:(id)alert {
	return NO;
}

- (NSString *)windowTitleForStatusController:(SUStatusController *)alert {
	return [NSString stringWithFormat:SULocalizedString(@"Updating %@", nil), [self applicationName]];
}

- (NSImage *)applicationIconForUpdateAlert:(id)alert {
	return [self applicationIcon];
}

- (NSImage *)applicationIconForStatusController:(SUStatusController *)controller {
	return [self applicationIcon];	
}

#pragma mark information (for subclassers)

- (BOOL)isAutomaticallyUpdating
{
	return [self automaticallyUpdates] && !verbose;
}

- (NSString *)downloadPath {
	return downloadPath;
}

- (BOOL)newVersionAvailable
{
	return [[self class] compareVersion:[updateItem fileVersion] toVersion:[self applicationVersion]] == NSOrderedAscending;
}

#pragma mark appcast

- (void)appcastDidFinishLoading:(SUAppcast *)ac
{
	@try
	{
		if (!ac) { [NSException raise:@"SUAppcastException" format:@"Couldn't get a valid appcast from the server."]; }
		
		//updateItem = [[ac newestItem] retain];
        [self setUpdateItem:[ac newestItem]]; // July 2006 Whitney Young (Memory Management)        
											  // July 2006 Whitney Young (Memory Management)
											  //[ac autorelease];
		
		// Record the time of the check for host app use and for interval checks on startup.
		[self saveLastCheck:[NSDate date]];
		
		if (![updateItem fileVersion])
		{
			[NSException raise:@"SUAppcastException" format:@"Can't extract a version string from the appcast feed. The filenames should look like YourApp_1.5.tgz, where 1.5 is the version number."];
		}
		
		if (!verbose && [[self skippedVersion] isEqualToString:[updateItem fileVersion]]) { updateInProgress = NO; return; }
		
		if ([self newVersionAvailable])
		{
			if (checkTimer)	// There's a new version! Let's disable the automated checking timer unless the user cancels.
			{
				[checkTimer invalidate];
				//checkTimer = nil;
                [self setCheckTimer:nil]; // July 2006 Whitney Young (Memory Management)
			}
			
			if ([self isAutomaticallyUpdating])
			{
				[self beginDownload];
			}
			else
			{
				[self showUpdatePanel];
			}
		}
		else
		{
			if (verbose) // We only notify on no new version when we're being verbose.
			{
				NSRunAlertPanel(SULocalizedString(@"You're up to date", nil), [NSString stringWithFormat:SULocalizedString(@"%@ %@ is currently the newest version available.", nil), [self applicationDisplayName], [self applicationVersionString]], SULocalizedString(@"OK", nil), nil, nil);
			}
			updateInProgress = NO;
		}
	}
	@catch (NSException *e)
	{
		NSLog([e reason]);
		updateInProgress = NO;
		if (verbose)
			[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred in retrieving update information. Please try again later.", nil)];
	}
}

- (void)appcastDidFailToLoad:(SUAppcast *)ac
{
    // July 2006 Whitney Young (Memory Management)
	//[ac autorelease];
	updateInProgress = NO;
	if (verbose)
		[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred in retrieving update information; are you connected to the internet? Please try again later.", nil)];
}

#pragma mark download

- (void)beginDownload
{
	if (![self isAutomaticallyUpdating])
	{
		//statusController = [[SUStatusController alloc] init];
        [self setStatusController:[[[SUStatusController alloc] initWithDelegate:self] autorelease]];
		[statusController beginActionWithTitle:SULocalizedString(@"Downloading update...", nil) maxProgressValue:0 statusText:@""];  // July 2006 Whitney Young (Interface)
		[statusController setButtonTitle:SULocalizedString(@"Cancel", nil) target:self action:@selector(cancelDownload:) isDefault:NO];
		[statusController showWindow:self];
	}
	
	//downloader = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:[updateItem fileURL]] delegate:self];	
    [self setDownloader:[[[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:[updateItem fileURL]] delegate:self] autorelease]];  // July 2006 Whitney Young (Memory Management)
}

// download delegate
- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	[statusController setMaxProgressValue:[response expectedContentLength]];
}

// download delegate
- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)name
{
	// If name ends in .txt, the server probably has a stupid MIME configuration. We'll give
	// the developer the benefit of the doubt and chop that off.
	if ([[name pathExtension] isEqualToString:@"txt"])
		name = [name stringByDeletingPathExtension];
	
	// We create a temporary directory in /tmp and stick the file there.
	NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:tempDir attributes:nil];
	if (!success)
	{
		[NSException raise:@"SUFailTmpWrite" format:@"Couldn't create temporary directory in /tmp"];
		[download cancel];
		[download release];
	}
	
	//[downloadPath autorelease];
	//downloadPath = [[tempDir stringByAppendingPathComponent:name] retain];
    [self setDownloadPath:[tempDir stringByAppendingPathComponent:name]]; // July 2006 Whitney Young (Memory Management)
	[download setDestination:downloadPath allowOverwrite:YES];
}

// download delegate
- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
	[statusController setProgressValue:[statusController progressValue] + length];
    
    NSString *speed = nil;
    float received = [statusController progressValue];
    float max = [statusController maxProgressValue];
    
    if (!sampler)
        [self setSampler:[[[SUSampler alloc] initWithSampleLength:3 interval:0.5] autorelease]];
    
    [sampler recieveBytes:length];
    if ([sampler hasCurrentSample])
    {
        float bytesPerSec = [sampler bytesInCurrentSample] / [sampler lengthOfCurrentSample];
        float time = (max - received) / bytesPerSec;
        NSString *timeIndicator = [NSString displayIndicatorForSeconds:&time];
        NSString *sizeIndicator = [NSString displayIndicatorForBytes:&bytesPerSec];
        
        char dash[4] = { 0xe2, 0x80, 0x94, 0x00 };
        NSString *format = SULocalizedString(@"(%0.1lf %@/sec) %@ %i %@ remaining", nil);
        speed = [NSString stringWithFormat:format, bytesPerSec, SULocalizedString(sizeIndicator, nil), [NSString stringWithUTF8String:dash], (int)ceil(time), SULocalizedString(timeIndicator, nil)];
    }
    
    NSString *received_indicator = [NSString stringWithFormat:@" %@", SULocalizedString([NSString displayIndicatorForBytes:&received], nil)];
    NSString *max_indicator = [NSString stringWithFormat:@" %@", SULocalizedString([NSString displayIndicatorForBytes:&max], nil)];
        
    BOOL display_first = ![max_indicator isEqualToString:received_indicator];

    //[statusController setStatusText:[NSString stringWithFormat:SULocalizedString(@"%.0lfk of %.0lfk", nil), [statusController progressValue] / 1024.0, [statusController maxProgressValue] / 1024.0]];
    NSString *statusString = [NSString stringWithFormat:SULocalizedString(@"%.1lf%@ of %.1lf%@", nil), received, (display_first ? received_indicator : @""), max, max_indicator];
    if (speed) { statusString = [statusString stringByAppendingFormat:@" %@", speed]; }
	[statusController setStatusText:statusString];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	//[download release];
	//downloader = nil;
    [self setDownloader:nil]; // July 2006 Whitney Young (Memory Management)
    [self setSampler:nil]; // July 2006 Whitney Young (Interface)
	[self extractUpdate];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    [self setSampler:nil]; // July 2006 Whitney Young (Interface)
	[self abandonUpdate];
	
	NSLog(@"Download error: %@", [error localizedDescription]);
	[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred while trying to download the file. Please try again later.", nil)];
}

#pragma mark unarchiver

- (void)extractUpdate
{
	// Now we have to extract the downloaded archive.
	if (![self isAutomaticallyUpdating])
		[statusController beginActionWithTitle:SULocalizedString(@"Extracting update...", nil) maxProgressValue:0 statusText:nil];
	
	@try 
	{
		// If the developer's provided a sparkle:md5Hash attribute on the enclosure, let's verify that.
		if ([updateItem MD5Sum])
		{
            // July 2006 Whitney Young (Interface)
            if (![self isAutomaticallyUpdating])
                [statusController setStatusText:SULocalizedString(@"Verifying MD5 checksum", nil) allowHeightChange:YES];
            
            if (![[NSFileManager defaultManager] validatePath:downloadPath withMD5Hash:[updateItem MD5Sum]])
            {
                [NSException raise:@"SUUnarchiveException" format:@"MD5 verification of the update archive failed."];                
            }
		}
		
		// DSA verification, if activated by the developer
		if ([self DSAEnabled])
		{
			NSString *dsaSignature = [updateItem DSASignature];
			NSString *publicKey = [self DSAPublicKey];
			if (![[NSFileManager defaultManager] validatePath:downloadPath withEncodedDSASignature:dsaSignature publicDSAKey:publicKey])
			{
				[NSException raise:@"SUUnarchiveException" format:@"DSA verification of the update archive failed."];
			}
		}
		
		//		SUUnarchiver *unarchiver = [[SUUnarchiver alloc] init];
		//		[unarchiver setDelegate:self];
		//		[unarchiver unarchivePath:downloadPath]; // asynchronous extraction!
        [SUUnarchiver unarchivePath:downloadPath delegate:self]; // July 2006 Whitney Young (Thread Safety)
	}
	@catch(NSException *e) {
		NSLog([e reason]);
		[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred while extracting the archive. Please try again later.", nil)];
		[self abandonUpdate];
	}	
}

// unarchiver delegate
- (void)unarchiver:(SUUnarchiver *)ua extractedLength:(long)length
{
	if ([self isAutomaticallyUpdating]) { return; }
	if ([statusController maxProgressValue] == 0)
		[statusController setMaxProgressValue:[[[[NSFileManager defaultManager] fileAttributesAtPath:downloadPath traverseLink:NO] objectForKey:NSFileSize] longValue]];
	[statusController setProgressValue:[statusController progressValue] + length];
}

// unarchiver delegate
- (void)unarchiverDidFinish:(SUUnarchiver *)ua
{
    // July 2006 Whitney Young (Thread Safety)
	//[ua autorelease];

    // July 2006 Whitney Young (Ease of Use)
    // The user already clicked a button that said download and install, why ask to
    // them to install and restart?  It seems many users could think that quitting
    // at this point would install the update.  The install processing from being
    // automatic at this point provides little to no additional security benefits.
    // It just makes it so the user has to be involved at this point.  It seems
    // like just installing the application and then giving the user the optoin
    // of restarting now or later is a little nicer.
    [self install:self];
    
//	if ([self isAutomaticallyUpdating])
//	{
//		[self installAndRestart:self];
//	}
//	else
//	{
//		[statusController beginActionWithTitle:SULocalizedString(@"Ready to install", nil) maxProgressValue:1 statusText:text];
//		[statusController setProgressValue:1]; // fill the bar
//		[statusController setButtonTitle:SULocalizedString(@"Install and Relaunch", nil) target:self action:@selector(installAndRestart:) isDefault:YES];
//		[NSApp requestUserAttention:NSInformationalRequest];
//	}
}

// unarchiver delegate
- (void)unarchiverDidFail:(SUUnarchiver *)ua
{
    // July 2006 Whitney Young (Thread Safety)
	//[ua autorelease];
	[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred while extracting the archive. Please try again later.", nil)];
	[self abandonUpdate];
}

#pragma mark stopping update

- (void)abandonUpdate
{
    // July 2006 Whitney Young (Memory Management)
    // These release messages aren't balancing any retain messages.
    // Shouldn't they just be handled by the deallocation of this object?
    // I'm not so sure about this change.  If the goal is to clear these
    // items, then they should be set to nil (which can now be done via
    // [self setUpdateItem:nil];
    // [self setStatusController:nil];
    // and will handle the proper releasing of the objects as well).
    // I'm taking these messages out because I'm pretty sure they
    // shouldn't be here, but a second look should probably be made.
	//[updateItem release];
	[statusController close];
	//[statusController release];
	updateInProgress = NO;	
}

- (IBAction)cancelDownload:sender
{
	if (downloader)
	{
		[downloader cancel];
		//[downloader release];
        [self setDownloader:nil]; // July 2006 Whitney Young (Memory Management)
	}
    if (sampler) // July 2006 Whitney Young (Interface)
    {
        [self setSampler:nil];
    }
	[self abandonUpdate];
	
	if (checkInterval)
	{
		[self scheduleCheckWithInterval:checkInterval];
	}
}

#pragma mark install

- (IBAction)install:(id)sender // July 2006 Whitney Young (Ease of Use)
{
	NSString *currentAppPath = [self applicationPath];
	NSString *cfBundleName = [self CFBundleName];
	NSString *newAppDownloadPath = [[downloadPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[cfBundleName stringByAppendingPathExtension:@"app"]];
	@try 
	{
		if (![self isAutomaticallyUpdating])
		{
			[statusController beginActionWithTitle:SULocalizedString(@"Installing update...", nil) maxProgressValue:0 statusText:nil];
			[statusController setButtonEnabled:NO];
			
			// We have to wait for the UI to update.
			NSEvent *event;
			while((event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES]))
				[NSApp sendEvent:event];			
		}
		
		// We assume that the archive will contain a file named {CFBundleName}.app
		// (where, obviously, CFBundleName comes from Info.plist)
		if (!cfBundleName) { [NSException raise:@"SUInstallException" format:@"This application has no CFBundleName! This key must be set to the application's name."]; }
		
		// Search subdirectories for the application
		NSString *file, *appName = [cfBundleName stringByAppendingPathExtension:@"app"];
		NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:[downloadPath stringByDeletingLastPathComponent]];
		while ((file = [dirEnum nextObject]))
		{
			// Some DMGs have symlinks into /Applications! That's no good!
			if ([file isEqualToString:@"/Applications"])
				[dirEnum skipDescendents];
			if ([[file lastPathComponent] isEqualToString:appName])
				newAppDownloadPath = [[downloadPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:file];
		}
		
		if (!newAppDownloadPath || ![[NSFileManager defaultManager] fileExistsAtPath:newAppDownloadPath])
		{
			[NSException raise:@"SUInstallException" format:@"The update archive didn't contain an application with the proper name: %@. Remember, the updated app's file name must be identical to {CFBundleName}.app", [cfBundleName stringByAppendingPathExtension:@"app"]];
		}
	}
	@catch(NSException *e) 
	{
		NSLog([e reason]);
		[self showUpdateErrorAlertWithInfo:SULocalizedString(@"An error occurred during installation. Please try again later.", nil)];
		[self abandonUpdate];		
	}
	
	if ([self isAutomaticallyUpdating]) // Don't do authentication if we're automatically updating; that'd be surprising.
	{
		int tag = 0;
		BOOL result = [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[currentAppPath stringByDeletingLastPathComponent] destination:@"" files:[NSArray arrayWithObject:[currentAppPath lastPathComponent]] tag:&tag];
		result &= [[NSFileManager defaultManager] movePath:newAppDownloadPath toPath:currentAppPath handler:nil];
		if (!result)
		{
			[self abandonUpdate];
			return;
		}
	}
	else // But if we're updating by the action of the user, do an authenticated move.
	{
		// Outside of the @try block because we want to be a little more informative on this error.
		if (![[NSFileManager defaultManager] movePathWithAuthentication:newAppDownloadPath toPath:currentAppPath])
		{
			[self showUpdateErrorAlertWithInfo:[NSString stringWithFormat:SULocalizedString(@"%@ does not have permission to write to the application's directory. Are you running off a disk image? If not, ask your system administrator for help.", nil), [self applicationName]]];
			[self abandonUpdate];
			return;
		}
	}
		
	// Prompt for permission to restart if we're automatically updating.
	if ([self isAutomaticallyUpdating])
	{
		SUAutomaticUpdateAlert *alert = [[SUAutomaticUpdateAlert alloc] initWithAppcastItem:updateItem delegate:nil];
		if ([NSApp runModalForWindow:[alert window]] == NSAlertAlternateReturn)
		{
			[alert release];
			return;
		}
	} else { // July 2006 Whitney Young (Ease of Use)
        NSString *statusText = [NSString stringWithFormat:SULocalizedString(@"%@ %@ has been installed and will be ready to use next time %@ starts. Would you like to relaunch now?", nil), [self applicationDisplayName], [updateItem fileVersion], [self applicationDisplayName]];
        [statusController beginActionWithTitle:SULocalizedString(@"Installing update...", nil) maxProgressValue:1 statusText:statusText];
		[statusController setProgressValue:1]; // fill the bar
        [statusController setButtonEnabled:YES];
        [statusController setButtonTitle:SULocalizedString(@"Relaunch Now", nil) target:self action:@selector(restart:) isDefault:YES];
        [statusController setAlternateButtonTitle:SULocalizedString(@"Relaunch Later", nil) target:statusController action:@selector(close)];
        [NSApp requestUserAttention:NSInformationalRequest];
        return;
    }
    
    [self restart:sender];
}

- (IBAction)restart:sender { // July 2006 Whitney Young (Ease of Use)

	NSString *currentAppPath = [self applicationPath];
	[[NSNotificationCenter defaultCenter] postNotificationName:SUUpdaterWillRestartNotification object:self];

	// Thanks to Allan Odgaard for this restart code, which is much more clever than mine was.
	setenv("LAUNCH_PATH", [currentAppPath UTF8String], 1);
	setenv("TEMP_FOLDER", [[downloadPath stringByDeletingLastPathComponent] UTF8String], 1); // delete the temp stuff after it's all over
	system("/bin/bash -c '{ for (( i = 0; i < 3000 && $(echo $(/bin/ps -xp $PPID|/usr/bin/wc -l))-1; i++ )); do\n"
		   "    /bin/sleep .2;\n"
		   "  done\n"
		   "  if [[ $(/bin/ps -xp $PPID|/usr/bin/wc -l) -ne 2 ]]; then\n"
		   "    /usr/bin/open \"${LAUNCH_PATH}\"\n"
		   "  fi\n"
		   "  rm -rf \"${TEMP_FOLDER}\"\n"
		   "} &>/dev/null &'");
	[NSApp terminate:self];	
}

#pragma mark for subclassers

- (BOOL)isFirstCheck
{
	return NO;
}

- (void)saveIsFirstCheck:(BOOL)flag { }

- (NSString *)applicationName
{
	return SUHostAppName();
}

- (NSString *)applicationDisplayName
{
	return SUHostAppDisplayName();
}

- (NSString *)applicationPath
{
	return [[NSBundle mainBundle] bundlePath];	
}

- (NSString *)applicationVersion
{
	return SUHostAppVersion();
}

- (NSString *)applicationVersionString
{
	return SUHostAppVersionString();
}

- (NSString *)CFBundleName
{
	return SUInfoValueForKey(@"CFBundleName");
}

- (NSImage *)applicationIcon {
	return [NSApp applicationIconImage];
}

- (BOOL)DSAEnabled
{
	return FALSE;
}

- (NSString *)DSAPublicKey
{
	return nil;
}

- (NSTimeInterval)remindMeLaterDefaultInterval
{
	return 30 * 60;
}

- (NSString *)appcastURL {
	return @"";
}

- (NSString *)skippedVersion
{
	return skippedVersion;
}

- (void)saveSkippedVersion:(NSString *)version
{
	if (version != skippedVersion) {
		[skippedVersion release];
		skippedVersion = [version retain];
	}
}

- (NSDate *)lastCheck {
	return lastCheck;
}

- (void)saveLastCheck:(NSDate *)date {
	if (lastCheck != date) {
		[lastCheck release];
		lastCheck = [date retain];
	}
}

- (SUFirstCheckType)firstCheckAction {
	return SUFirstRunAsk;
}

- (BOOL)shouldCheckAtStartup {
	return shouldCheckAtStartup;
}

- (void)saveShouldCheckAtStartup:(BOOL)flag {
	shouldCheckAtStartup = flag;
}

- (BOOL)automaticallyUpdates {
	return NO;
}

- (NSTimeInterval)checkInterval {
	return 0;
}

#pragma mark private getter and setter methods

// July 2006 Whitney Young (Memory Management)
- (void)setUpdateItem:(SUAppcastItem *)anUpdateItem
{
    if (updateItem != anUpdateItem)
    {
        [updateItem release];
        updateItem = [anUpdateItem retain];
    }
}

- (void)setStatusController:(SUStatusController *)aStatusController
{
    if (statusController != aStatusController)
    {
        [statusController release];
        statusController = [aStatusController retain];
    }    
}

- (void)setUpdateAlert:(SUUpdateAlert *)anUpdateAlert
{
    if (updateAlert != anUpdateAlert)
    {
        [updateAlert release];
        updateAlert = [anUpdateAlert retain];
    }    
}

- (void)setDownloader:(NSURLDownload *)aDownloader
{
    if (downloader != aDownloader)
    {
        [downloader release];
        downloader = [aDownloader retain];
    }    
}

- (void)setDownloadPath:(NSString *)aDownloadPath
{
    if (downloadPath != aDownloadPath)
    {
        [downloadPath release];
        downloadPath = [aDownloadPath retain];
    }    
}

- (void)setSampler:(SUSampler *)aSampler
{
    if (sampler != aSampler)
    {
        [sampler release];
        sampler = [aSampler retain];
    }
}

- (void)setCheckTimer:(NSTimer *)aCheckTimer
{
    if (checkTimer != aCheckTimer)
    {
        [checkTimer release];
        checkTimer = [aCheckTimer retain];
    }    
}

@end