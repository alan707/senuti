/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
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

#import "AICrashReporter.h"
#import "AITextViewWithPlaceholder.h"
#import "AIStringAdditions.h"
#import "AIFileManagerAdditions.h"
#import "AIViewAdditions.h"
#import <Sparkle/Sparkle.h>

#define CRLocalizedString(key, comment) \
	NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:[self class]], comment)

#define RELATIVE_PATH_FROM_CRASH_REPORTER		@"../../../../../../../"

#define KEY_CRASH_EMAIL_ADDRESS			@"CrashReporterEmailAddress"
#define KEY_CRASH_AIM_ACCOUNT			@"CrashReporterAIMAccount"

#define CRASH_LOG_WAIT_ATTEMPTS			300
#define CRASH_LOG_WAIT_INTERVAL			0.2

#define UNABLE_TO_SEND				CRLocalizedString(@"Unable to send crash report",nil)

@interface AICrashReporter (PRIVATE)
- (void)performVersionChecking;
- (void)localize;
- (void)loadBuildInformation;
- (NSString *)crashedApplicationName;
- (NSString *)crashedApplicationPath;
- (NSBundle *)crashedApplicationBundle;
@end

@implementation AICrashReporter

//
- (void)dealloc
{
	[buildInfo release];
	[crashLog release];
	[statusChecker release];
	[newVersionString release];
	[crashedApplicationName release];
	[crashedApplicationPath release];
	[crashedApplicationBundle release];

	[super dealloc];
}


//
- (void)awakeFromNib
{
	//Search for an exception log
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSString stringWithFormat:@"~/Library/Logs/CrashReporter/%@.exception.log", [self crashedApplicationName]] stringByExpandingTildeInPath]]) {
        [self reportCrashForLogAtPath:[[NSString stringWithFormat:@"~/Library/Logs/CrashReporter/%@.exception.log", [self crashedApplicationName]] stringByExpandingTildeInPath]];
    } else {  
        //Kill the apple crash reporter
		//Actively tries to kill Apple's "Report this crash" dialog
		system("/bin/bash -c '{\n"
			   "  KILLED=0\n"
			   "  WAITED=0\n"
			   "  for ((i = 0; i < 300 && (((KILLED == 1)) || (($WAITED < 600))); i++)); do\n"
			   "    if (($(echo $(killall UserNotificationCenter 2>&1|wc -l)) == 0)); then\n"
			   "      let KILLED=1;\n"
			   "      let WAITED=0;\n"
			   "    fi\n"
			   "    /bin/sleep .1;\n"
			   "    let WAITED=WAITED+1;\n"
			   "  done\n"
			   "} &>/dev/null &'");
		
		//Wait for a valid crash log to appear
		//Wait until now to start looking because until now there was no way to know the app name
		[NSTimer scheduledTimerWithTimeInterval:CRASH_LOG_WAIT_INTERVAL
										 target:self
									   selector:@selector(delayedCrashLogDiscovery:)
									   userInfo:nil
										repeats:YES];
		
    }
	
	//Restore the user's email address and account if they've entered it previously
    NSString	*emailAddress;
	if ((emailAddress = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_CRASH_EMAIL_ADDRESS])) {
		[textField_emailAddress setStringValue:emailAddress];
	}	
	
	[self localize];
	
	if ([progress_sending respondsToSelector:@selector(setHidden:)]) {
		[progress_sending setHidden:YES];
	}
}

- (void)localize {
	//Load the build information
	[self loadBuildInformation];
	
	[window_MainWindow setTitle:[NSString stringWithFormat:CRLocalizedString(@"%@ Crash Reporter", nil), [self crashedApplicationName]]];
	
	NSString *extraBuildInfo = (buildInfo ? [NSString stringWithFormat:CRLocalizedString(@" and information specific to your build of %@", nil), [self crashedApplicationName]] : @"");
	[textField_privacyInfo setStringValue:
		[NSString stringWithFormat:CRLocalizedString(@"Information sent through the crash reporter is used for debugging purposes only."
													 "  Please do not submit confidential information or passwords.\n\n"
													 "The following crash log will be sent to the %@ developers with the information you've entered%@.", nil), [self crashedApplicationName], extraBuildInfo]];
	[button_closeSheet setTitle:CRLocalizedString(@"OK", nil)];
	

	[textField_title setStringValue:[NSString stringWithFormat:CRLocalizedString(@"The application %@ has unexpectedly quit", nil), [self crashedApplicationName]]];
	[textField_info setStringValue:[NSString stringWithFormat:CRLocalizedString(@"Please take a moment to send us this crash report.  It will help make %@ as stable and reliable as possible.", nil), [self crashedApplicationName]]];
	[textField_contactInfo setStringValue:CRLocalizedString(@"Contact information: (Required)", nil)];
	[textField_emailLabel setStringValue:CRLocalizedString(@"Your Email:", nil)];
	[[textField_emailAddress cell] setPlaceholderString:CRLocalizedString(@"Your email address", nil)];
	[textField_additionalInfo setStringValue:CRLocalizedString(@"Additional crash details: (Optional)", nil)];
	[textField_descriptionLabel setStringValue:CRLocalizedString(@"Description:", nil)];
	[[textField_description cell] setPlaceholderString:CRLocalizedString(@"A short description of the crash", nil)];
	[textField_explanationLabel setStringValue:CRLocalizedString(@"Description:", nil)];
	[textView_details setPlaceholderString:[NSString stringWithFormat:CRLocalizedString(@"A detailed explanation of what you were doing when %@ crashed (optional)",nil), [self crashedApplicationName]]];
	[button_send setTitle:[NSString stringWithFormat:CRLocalizedString(@"Send report and relaunch %@", nil), [self crashedApplicationName]]];
	[button_close setTitle:CRLocalizedString(@"Close", nil)];
	[button_privacy setTitle:[CRLocalizedString(@"Privacy Information", nil) stringByAppendingEllipsis]];
	
	
	[textField_privacyInfo resizeViewToSize:NSMakeSize([textField_privacyInfo frame].size.width, [textField_privacyInfo heightForText])
							   expandToward:AIExpandTowardMinYMask
								  moveViews:[NSArray arrayWithObjects:[[textView_crashLog superview] superview], nil]
								shrinkViews:[NSArray arrayWithObjects:[[textView_crashLog superview] superview], nil]];

	NSSize change = [textField_info resizeViewToSize:NSMakeSize([textField_info frame].size.width, [textField_info heightForText])
										expandToward:AIExpandTowardMinYMask
										   moveViews:nil
										 shrinkViews:nil];
	[window_MainWindow setFrame:NSMakeRect([window_MainWindow frame].origin.y, [window_MainWindow frame].origin.x, [window_MainWindow frame].size.width + change.width, [window_MainWindow frame].size.height + change.height)
						display:NO];

	[button_privacy sizeToFitWithPadding:NSMakeSize(20, 0) expandToward:AIExpandTowardMinXMask moveViews:[NSArray arrayWithObject:textField_emailAddress] shrinkViews:[NSArray arrayWithObject:textField_emailAddress]];
	[button_send sizeToFitWithPadding:NSMakeSize(20, 0) expandToward:AIExpandTowardMinXMask moveViews:[NSArray arrayWithObject:button_close] shrinkViews:nil];
	[button_close sizeToFitWithPadding:NSMakeSize(20, 0) expandToward:AIExpandTowardMinXMask moveViews:nil shrinkViews:nil];
	[button_closeSheet sizeToFitWithPadding:NSMakeSize(20, 0) expandToward:AIExpandTowardMinXMask moveViews:nil shrinkViews:nil];
}

#pragma mark Crash log loading
//Waits for a crash log to be written
- (void)delayedCrashLogDiscovery:(NSTimer *)inTimer
{
	static int 		countdown = CRASH_LOG_WAIT_ATTEMPTS;
	
	//Waits for a crash log to be written
	if (countdown-- == 0 || 
		[self reportCrashForLogInDir:[@"~/Library/Logs/CrashReporter/" stringByExpandingTildeInPath] withPrefix:[self crashedApplicationName]]) {
		[inTimer invalidate];
	}
}

- (BOOL)reportCrashForLogInDir:(NSString *)inPath withPrefix:(NSString *)prefix {
	logDirectoryFileCount = 0;
	NSArray *contents = [[NSFileManager defaultManager] directoryContentsAtPath:inPath];
	if (logDirectoryFileCount != [contents count]) {
		NSString *file;
		NSEnumerator *enumerator = [contents objectEnumerator];
		while (file = [enumerator nextObject]) {
			if ([file hasPrefix:prefix] && [self reportCrashForLogAtPath:[inPath stringByAppendingPathComponent:file]]) {
				return YES;
			}
		}
		logDirectoryFileCount = [contents count];
	}
	return NO;
}

//Display the report crash window for the passed log
- (BOOL)reportCrashForLogAtPath:(NSString *)inPath
{
    NSRange		binaryRange;
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:inPath]) {
		NSString	*newLog = [NSString stringWithContentsOfFile:inPath];
		if (newLog && [newLog length]) {
			//Hang onto and delete the log
			crashLog = [newLog retain];
			[[NSFileManager defaultManager] trashFileAtPath:inPath];
			
			//Strip off thread state and binary descriptions.. we don't need to send all that
			binaryRange = [crashLog rangeOfString:@"Thread State"];
			if (binaryRange.location != NSNotFound) {
				NSString	*shortLog = [crashLog substringToIndex:binaryRange.location];
				[crashLog release]; crashLog = [shortLog retain];
			}
			
			//Get any info printed to the system log
			NSTask *grep = [[[NSTask alloc] init] autorelease];
			NSPipe *pipe = [NSPipe pipe];
			[grep setLaunchPath:@"/bin/bash"];
			[grep setArguments:[NSArray arrayWithObjects:@"-c", @"tail -n 100 /var/log/system.log | grep Senuti", nil]];
			[grep setStandardOutput:pipe];
			[grep setStandardError:pipe];
			[grep launch];
			[grep waitUntilExit];
			NSString *fullLog = [crashLog stringByAppendingFormat:
								 @"----------------------------------------------------------------------\nSystem Log:\n%@",
								 [[[NSString alloc] initWithData:[[pipe fileHandleForReading] readDataToEndOfFile]
														encoding:NSUTF8StringEncoding] autorelease]];
			[crashLog release]; crashLog = [fullLog retain];
						
			//Highlight the existing details text
			[textView_details setSelectedRange:NSMakeRange(0, [[textView_details textStorage] length])
									  affinity:NSSelectionAffinityUpstream
								stillSelecting:NO];
			
			[window_MainWindow setLevel:NSFloatingWindowLevel];
			[window_MainWindow center];
			[window_MainWindow makeKeyAndOrderFront:nil];			
			
			return YES;
		}
	}
	
	return NO;
}

#pragma mark Privacy Details
//Display privacy information sheet
- (IBAction)showPrivacyDetails:(id)sender
{
	if (crashLog) {
		NSDictionary		*attributes = [NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:11]
																	  forKey:NSFontAttributeName];
		NSAttributedString	*attrLogString = [[[NSAttributedString alloc] initWithString:crashLog
																			  attributes:attributes] autorelease];
		
		//Fill in crash log
		[[textView_crashLog textStorage] setAttributedString:attrLogString];
		
		//Display the sheet
		[NSApp beginSheet:panel_privacySheet
		   modalForWindow:window_MainWindow
			modalDelegate:nil
		   didEndSelector:nil
			  contextInfo:nil];
	} else {
		NSBeep();
	}
}

//Close the privacy details sheet
- (IBAction)closePrivacyDetails:(id)sender
{
    [panel_privacySheet orderOut:nil];
    [NSApp endSheet:panel_privacySheet returnCode:0];
}

#pragma mark Report sending

/*
 * @brief Disable the close button and begin spinning the indeterminate progress indicator
 */
- (void)activateProgressIndicator
{
	[button_close setHidden:YES];
	
	//Display immediately since we need it for this run loop.
	[[button_close superview] display];
	
	[progress_sending setHidden:NO];
	
	//start the progress spinner (using multi-threading)
	[progress_sending setUsesThreadedAnimation:YES];
	[progress_sending startAnimation:nil];
}	

/*
 * @brief User wants to send the report
 */
- (IBAction)send:(id)sender
{
	if ([[textField_emailAddress stringValue] isEqualToString:@""]) {
		NSBeginCriticalAlertSheet(CRLocalizedString(@"Contact Information Required",nil),
								  CRLocalizedString(@"OK",nil), nil, nil, window_MainWindow, nil, nil, nil, NULL,
								  CRLocalizedString(@"Please provide either your email address or IM name in case we need to contact you for additional information (or to suggest a solution).",nil));
	} else {
		//Begin showing progress
		[self activateProgressIndicator];
		
		//Perform version checking; when it is complete or fails, the submission process will continue
		[self performVersionChecking];
	}
}

/*
 * @brief Build the crash report and associated information, then pass it to sendReport:
 */
- (void)buildAndSendReport
{
	NSString	*shortDescription = [textField_description stringValue];
	
	//Truncate description field to 300 characters
	if ([shortDescription length] > 300) {
		shortDescription = [shortDescription substringToIndex:300];
	}
		
	NSMutableDictionary *crashReport = [NSMutableDictionary dictionaryWithDictionary:buildInfo];
	[crashReport addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
		[[self crashedApplicationBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], @"version",
		[textField_emailAddress stringValue], @"email",
		shortDescription, @"short_desc",
		[textView_details string], @"desc",
		crashLog, @"log",
		nil]];
	
	//Send
	[self sendReport:crashReport];
}

/*
 * @brief Send a crash report to the crash reporter web site
 */
- (void)sendReport:(NSDictionary *)crashReport
{
    NSMutableString *reportString = [[[NSMutableString alloc] init] autorelease];
    NSEnumerator	*enumerator;
    NSString		*key;
	id				value;
    NSData 			*data = nil;
    
    //Compact the fields of the report into a long URL string
    enumerator = [[crashReport allKeys] objectEnumerator];
    while ((key = [enumerator nextObject])) {
        if ([reportString length] != 0) [reportString appendString:@"&"];
		value = [crashReport objectForKey:key];

		// convert all values to strings
		if ([value isKindOfClass:[NSDate class]]) {
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d %H:%M:%S" 
																	 allowNaturalLanguage:NO] autorelease];
			value = [dateFormatter stringForObjectValue:value];			
		} else if (![value isKindOfClass:[NSString class]]) { value = [value description]; }
		
        [reportString appendFormat:@"%@=%@", key, [value stringByEncodingURLEscapes]];
    }

    //
    while (!data || [data length] == 0) {
        NSError 			*error;
        NSURLResponse 		*reply;
        NSMutableURLRequest *request;
        
        //Build the URL request
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[self crashedApplicationBundle] objectForInfoDictionaryKey:@"CrashReportURL"]]
                                          cachePolicy:NSURLRequestReloadIgnoringCacheData
                                      timeoutInterval:120];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[reportString dataUsingEncoding:NSUTF8StringEncoding]];

        //Attempt to send report
        data = [NSURLConnection sendSynchronousRequest:request returningResponse:&reply error:&error];
        
        //stop the progress spinner
        [progress_sending stopAnimation:nil];
        
        //Alert on failure, and offer the option to quit or retry
        if (!data || [data length] == 0) {
            if (NSRunAlertPanel(UNABLE_TO_SEND,
								(error ? [error localizedDescription] : CRLocalizedString(@"The server could not handle your request at this time.", nil)),
								CRLocalizedString(@"Try Again", nil),
								[NSString stringWithFormat:CRLocalizedString(@"Relaunch %@", nil), [self crashedApplicationName]],
								nil) == NSAlertAlternateReturn) {
                break;
            }
        }
    }
}

#pragma mark Closing behavior
//Save some of the information for next time on quit
- (void)windowWillClose:(id)sender
{
    //Remember the user's email address
    [[NSUserDefaults standardUserDefaults] setObject:[textField_emailAddress stringValue]
                                              forKey:KEY_CRASH_EMAIL_ADDRESS];	
}

//Terminate if our window is closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

#pragma mark Build information
//Load the current build date and our svn revision
- (void)loadBuildInformation
{
	buildInfo = [[NSDictionary dictionaryWithContentsOfFile:[[self crashedApplicationBundle] pathForResource:@"BuildInfo" ofType:@"plist"]] retain];
}

/*!
 * @brief Invoked when version information is received
 */
- (void)sendReportAndRestart
{
	[self buildAndSendReport];
	[[NSWorkspace sharedWorkspace] openFile:[self crashedApplicationPath]];
	//Close our window to terminate
	[window_MainWindow performClose:nil];
}

- (NSBundle *)crashedApplicationBundle {
	if (!crashedApplicationBundle) {
		crashedApplicationBundle = [[NSBundle bundleWithPath:[self crashedApplicationPath]] retain];
	}
	return crashedApplicationBundle;
}

- (NSString *)crashedApplicationPath {
	if (!crashedApplicationPath) {
		crashedApplicationPath = [[[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:RELATIVE_PATH_FROM_CRASH_REPORTER] retain];
	}
	return crashedApplicationPath;
}

- (NSString *)crashedApplicationName {
	if (!crashedApplicationName) {
		crashedApplicationName = [[[self crashedApplicationBundle] objectForInfoDictionaryKey:@"CFBundleName"] retain];
	}
	return crashedApplicationName;
}

/*!
 * @brief Returns the date of the most recent Adium build (contacts adiumx.com asynchronously)
 */
- (void)performVersionChecking
{
	NSString *sparklePath = [[[NSBundle bundleForClass:[self class]] privateFrameworksPath] stringByAppendingPathComponent:@"Sparkle.framework"];
	NSBundle *sparkleBundle = [NSBundle bundleWithPath:sparklePath];
	Class delegatedExternalUpdater;
	if ((sparkleBundle) &&
		([sparkleBundle load]) && 
		(delegatedExternalUpdater = [sparkleBundle classNamed:@"SUDelegatedExternalUpdater"])) {
		
		NSLog(@"sparkle support enabled");
		NSString *path = [[self crashedApplicationPath] stringByStandardizingPath];
		statusChecker = [[delegatedExternalUpdater alloc] initWithAppPath:path delegate:self];
		[statusChecker checkForUpdates:nil];
		
	} else {
		// version checking not enabled, just submit
		[self sendReportAndRestart];
	}
}

#pragma mark sparkle delegate methods (SUExternalUpdaterDelegate)

- (BOOL)updater:(id)updater shouldContinueAfterRecievingVersion:(NSString *)versionString isNew:(BOOL)flag {
	if (flag) {
		// it's a bad crash report, close the main window (after a delay to avoid the possibility of the application exiting)
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:window_MainWindow selector:@selector(performClose:) userInfo:nil repeats:NO];
		newVersionString = [versionString retain];
		// and allow the user to update
		return YES;
	} else {
		// complete the report
		[self sendReportAndRestart];
		return NO;
	}
}

- (BOOL)updaterShouldContinueAfterFailingToRecievingVersion:(id)updater {
	// allow the report anyway
	[self sendReportAndRestart];
	return NO;	
}


- (NSString *)titleTextForUpdateAlert:(id)alert {
	return UNABLE_TO_SEND;
	
}

- (NSString *)descriptionTextForUpdateAlert:(id)alert {
	return [NSString stringWithFormat:CRLocalizedString(@"Your version of %@ is out of date, so crash reporting has been disabled. Your version is %@.  The current version is %@. Please update to the latest version, as your crash may have already been fixed.", nil),
		[self crashedApplicationName],
		[[self crashedApplicationBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
		newVersionString];
}

- (BOOL)allowAutomaticUpdateForUpdateAlert:(id)alert {
	return NO;
}

- (BOOL)displayCancelButtonForUpdateAlert:(id)alert {
	return YES;
}

@end
