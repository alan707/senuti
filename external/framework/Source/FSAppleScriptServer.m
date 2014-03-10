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

#import "FSAppleScriptServer.h"
#import "FSAppleScriptAdditions.h"
#import "FSMacros.h"

#define SECONDS_INACTIVITY_BEFORE_AUTOMATIC_QUIT 600 /* 10 minutes */

@interface FSAppleScriptServer (PRIVATE)
- (void)resetAutomaticQuitTimer;
@end

@implementation FSAppleScriptServer

- (id)init {
	if ((self = [super init])) {
		server = [NSConnection defaultConnection];
		scripts = [[NSMutableDictionary alloc] init];
		[server setRootObject:self];
		[server registerName:@"org.fadingred.AppleScript"];
		[self resetAutomaticQuitTimer];
	}
	return self;
}

- (void)dealloc {
	[scripts release];
	[super dealloc];
}

- (NSDictionary *)run:(NSString *)scriptPath
 executeFunction:(NSString *)functionName
   withArguments:(NSArray *)argumentArray {

	NSAppleScript *script = [scripts objectForKey:scriptPath];
	if (!script) {
		// load the script
		NSDictionary *errorInfo = nil;
		script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorInfo];
		if (errorInfo) { FSLog(@"AppleScript loaded with error: %@", errorInfo); }
		
		if (![script isCompiled]) {
			[script compileAndReturnError:&errorInfo];
			if (errorInfo) { FSLog(@"AppleScript compiled with error: %@", errorInfo); }
		}

		[scripts setObject:script forKey:scriptPath];
	}
	
	NSDictionary *errorInfo = nil;
	NSAppleEventDescriptor *result = [script executeFunction:functionName withArguments:argumentArray error:&errorInfo];
	[self resetAutomaticQuitTimer];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if (result) { [dict setObject:result forKey:@"result"]; }
	if (errorInfo) { [dict setObject:errorInfo forKey:@"error"]; }
	return [dict copy];
}

- (void)quit:(NSNotification *)inNotification {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	exit(0);
}

- (void)resetAutomaticQuitTimer {
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(quit:)
											   object:nil];
	[self performSelector:@selector(quit:)
			   withObject:nil
			   afterDelay:SECONDS_INACTIVITY_BEFORE_AUTOMATIC_QUIT];
}

@end

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	FSAppleScriptServer *server = [[FSAppleScriptServer alloc] init];
	[[NSRunLoop currentRunLoop] run];
	[server quit:nil];
	[server release];
	[pool release];
}
