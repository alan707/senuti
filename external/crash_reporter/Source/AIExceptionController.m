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
#import "AIExceptionController.h"
#import "AIFileManagerAdditions.h"
#import "AIStringAdditions.h"
#import <ExceptionHandling/NSExceptionHandler.h>
#include <unistd.h>
#include <execinfo.h>

#define EXCEPTIONS_PATH				[[NSString stringWithFormat:@"~/Library/Logs/CrashReporter/%@.exception.log", \
	[[NSProcessInfo processInfo] processName]] stringByExpandingTildeInPath]

void AIExceptionHandler(NSException *exception);
@interface AIExceptionController (PRIVATE)
+ (BOOL)exceptionCatchingEnabled;
@end

/*
 * @class AIExceptionController
 * @brief Catches application exceptions and forwards them to the crash reporter application
 *
 * Once configured, sets itself as the NSExceptionHandler delegate to decode the stack traces
 * generated via NSExceptionHandler, write them to a file, and launch the crash reporter.
 */
@implementation AIExceptionController

//Enable exception catching for the crash reporter
static BOOL catchExceptions = NO;

+ (BOOL)exceptionCatchingEnabled {
	return catchExceptions;
}

+ (void)enableExceptionCatching
{
    //Log and Handle all exceptions
	NSExceptionHandler *exceptionHandler = [NSExceptionHandler defaultExceptionHandler];
    [exceptionHandler setExceptionHandlingMask:(NSHandleUncaughtExceptionMask |
												NSHandleUncaughtSystemExceptionMask | 
												NSHandleUncaughtRuntimeErrorMask)];
	NSSetUncaughtExceptionHandler(AIExceptionHandler);
	
	catchExceptions = YES;

	//Remove any existing exception logs
    [[NSFileManager defaultManager] trashFileAtPath:EXCEPTIONS_PATH];
}

@end

void AIExceptionHandler(NSException *exception) {

	BOOL shouldLaunchCrashReporter = YES;
	if ([AIExceptionController exceptionCatchingEnabled]) {
		NSString	*theReason = [exception reason];
		NSString	*theName   = [exception name];
		NSString	*backtrace = [exception decodedExceptionStackTrace];

		NSLog(@"Caught exception: %@ - %@",theName,theReason);
		
		if (!theReason) { shouldLaunchCrashReporter = NO; }
			   
		if (shouldLaunchCrashReporter) {
			NSString	*bundlePath = [[NSBundle mainBundle] bundlePath];
			NSString	*crashReporterPath = [bundlePath stringByAppendingPathComponent:RELATIVE_PATH_TO_CRASH_REPORTER];
			NSString	*versionString = [[NSProcessInfo processInfo] operatingSystemVersionString];
			NSString	*preferredLocalization = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
	
			NSLog(@"Launching the Crash Reporter because an exception of type %@ occurred:\n%@", theName,theReason);

			//Pass the exception to the crash reporter and close this application
			[[NSString stringWithFormat:@"OS Version:\t%@\nLanguage:\t%@\nException:\t%@\nReason:\t%@\nStack trace:\n%@\n",
				versionString,preferredLocalization,theName,theReason,(backtrace ? backtrace : @"(Unavailable)")] writeToFile:EXCEPTIONS_PATH atomically:YES];

			[[NSWorkspace sharedWorkspace] launchApplication:crashReporterPath];

			exit(-1);
		} else {
			NSLog(@"The following unhandled exception was ignored: %@ (%@)\nStack trace:\n%@",
				  theName,
				  theReason,
				  (backtrace ? backtrace : @"(Unavailable)"));
		}
	}
}

@interface NSException (AIExceptionControllerAdditionsPrivate)
- (NSString *)decodedStackTraceFromReturnAddresses;
- (NSString *)decodedStackTraceFromUserInfo;
@end

@implementation NSException (AIExceptionControllerAdditions)

- (NSString *)decodedExceptionStackTrace {
	NSString *trace = nil;
	if (!trace) { trace = [self decodedStackTraceFromReturnAddresses]; }
	if (!trace) { trace = [self decodedStackTraceFromUserInfo]; }
	return trace;
}

- (NSString *)decodedStackTraceFromReturnAddresses {

	// if using 10.5
	if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_4) {
		int i = 0;
		int count = [[self callStackReturnAddresses] count];
		void *frames[count];
		
		// build frame pointers
		NSEnumerator *addresses = [[self callStackReturnAddresses] objectEnumerator];
		NSNumber *address;
		while (address = [addresses nextObject]) {
			frames[i++] = (void *)[address unsignedIntegerValue];
		}
		
		// Get symbols for the backtrace addresses
		char **frameStrings = backtrace_symbols(frames, count);
		
		NSMutableString *backtrace = [NSMutableString string];
		
		if (frameStrings) {
			for(i = 0; i < count; i++) {
				if(frameStrings[i]) {
					[backtrace appendFormat:@"%s\n", frameStrings[i]];
				}
			}
		}
		
		return backtrace;
	} else {
		return nil;
	}
}

// decode the stack trace within [self userInfo] and return it
- (NSString *)decodedStackTraceFromUserInfo {
	
	NSDictionary    *dict = [self userInfo];
	NSString        *stackTrace = nil;

	//Turn the nonsense of memory addresses into a human-readable backtrace complete with line numbers
	if (dict && (stackTrace = [dict objectForKey:NSStackTraceKey])) {
		NSMutableString		*processedStackTrace;
		NSString			*str;
		
		/* We use several command line apps to decode our exception:
		 * atos -p PID addresses...: converts addresses (hex numbers) to symbol names that we can read.
		 * tail -n +3: strip the first three lines.
		 * head -n +NUM: reduces to the first NUM lines. we pass NUM as the number of addresses minus 4.
		 * cat -n: adds line numbers. fairly meaningless, but fun.
		 */
		
		str = [NSString stringWithFormat:@"%s -p %d %@ | tail -n +3 | head -n +%d | cat -n",
			[[[[NSBundle bundleForClass:[AIExceptionController class]] pathForResource:@"atos" ofType:nil] stringByEscapingForShell] fileSystemRepresentation], //atos arg 0
			[[NSProcessInfo processInfo] processIdentifier], //atos arg 2 (argument to -p)
			stackTrace, //atos arg 3..inf
			([[stackTrace componentsSeparatedByString:@"  "] count] - 4)]; //head arg 3

		FILE *file = popen([str UTF8String], "r");
		NSMutableData *data = [[NSMutableData alloc] init];

		if (file) {
			NSZone	*zone = [self zone];

			size_t	 bufferSize = getpagesize();
			char	*buffer = NSZoneMalloc(zone, bufferSize);
			if (!buffer) {
				buffer = alloca(bufferSize = 512);
				zone = NULL;
			}

			size_t	 amountRead;

			while ((amountRead = fread(buffer, sizeof(char), bufferSize, file))) {
				[data appendBytes:buffer length:amountRead];
			}

			if (zone) NSZoneFree(zone, buffer);

			pclose(file);
		}

		// we use ISO 8859-1 because it preserves all bytes. UTF-8 doesn't (beacuse
		// certain sequences of bytes may get added together or cause the string to be rejected).
		// and it shouldn't matter; we shouldn't be getting high-ASCII in the backtrace anyway. :)
		processedStackTrace = [[[NSMutableString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
		[data release];
		
		// clear out a useless string inserted into some stack traces as of 10.4 to improve crashlog readability
		[processedStackTrace replaceOccurrencesOfString:@"task_start_peeking: can't suspend failed  (ipc/send) invalid destination port"
											 withString:@""
												options:NSLiteralSearch
												  range:NSMakeRange(0, [processedStackTrace length])];
		
		return processedStackTrace;
	}
	
	//If we are unable to decode the stack trace, return the best we have
	return stackTrace;
}

@end

@implementation NSApplication (AIApplicationAdditions)

- (void)reportException:(NSException *)exception {
	if ([AIExceptionController exceptionCatchingEnabled]) {
		(*NSGetUncaughtExceptionHandler())(exception);
	}
	NSLog(@"%@", exception);
}

@end

