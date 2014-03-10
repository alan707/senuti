/* 
 * The FadingRed Shared Framework (FSFramework) is the legal property of its developers, whose names
 * are listed in the copyright file included with this source distribution.
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

/*
 * This code is orinally from Adium.
 * Visit http://www.adiumx.com/ for more information.
 */

#import "FSAppleScriptClient.h"
#import "FSAppleScriptServer.h"

@implementation FSAppleScriptClient

- (void)dealloc {
	[client release];
	[super dealloc];
}

- (void)launchServer {
	NSString *serverPath = [[NSBundle mainBundle] pathForResource:@"FSAppleScriptServer"
														   ofType:nil
													  inDirectory:nil];
	
	//Houston, we are go for launch.
	if (serverPath) {
		LSLaunchFSRefSpec spec;
		FSRef appRef;
		OSStatus err = FSPathMakeRef((UInt8 *)[serverPath fileSystemRepresentation], &appRef, NULL);
		if (err == noErr) {
			spec.appRef = &appRef;
			spec.numDocs = 0;
			spec.itemRefs = NULL;
			spec.passThruParams = NULL;
			spec.launchFlags = kLSLaunchDontAddToRecents | kLSLaunchDontSwitch | kLSLaunchNoParams | kLSLaunchAsync;
			spec.asyncRefCon = NULL;
			err = LSOpenFromRefSpec(&spec, NULL);
			
			if (err != noErr) {
				NSLog(@"Could not launch %@", serverPath);
			}
		}
	} else {
		NSLog(@"Could not find FSAppleScriptServer...");
	}
}

- (NSAppleEventDescriptor *)run:(NSString *)scriptPath
					   function:(NSString *)function
					  arguments:(NSArray *)arguments
						  error:(NSDictionary **)error {
	
	BOOL success = FALSE;
	NSDictionary *result;
	
	while (!success) {
		if (![client isValid]) {
			[client release];
			client = [[NSConnection connectionWithRegisteredName:@"org.fadingred.AppleScript" host:nil] retain];
			if (![client isValid]) {
				[self launchServer];
				while (!client) {
					[client release];
					client = [[NSConnection connectionWithRegisteredName:@"org.fadingred.AppleScript" host:nil] retain];
				}		
			}
		}
		
		/* it's still possible that even though the above checks for the client's
		 * validity passed, that the socket could close in the mean time or that
		 * some other exception would happen, so we'll just continue trying untill
		 * succeeding */
		@try {
			FSAppleScriptServer *proxy = (FSAppleScriptServer *)[client rootProxy];
			result = [proxy run:scriptPath
				executeFunction:function
				  withArguments:arguments];
			success = TRUE;
		} @catch (NSException *exception) {
			// try again for all exceptions
		}
	}
	
	if (error) {
		*error = [result objectForKey:@"error"];
	}
	return [result objectForKey:@"result"];
}

@end
