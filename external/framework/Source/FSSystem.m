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

#import <sys/sysctl.h>
#import "FSSystem.h"

static NSMutableArray *systemProfile = nil;
static NSString *encodedURL = nil;

@implementation FSSystem

+ (NSArray *)systemProfile {
	
	if (!systemProfile) {
		systemProfile = [[NSMutableArray alloc] init];
		int error = 0;
		int value = 0;
		unsigned long length = sizeof(value);
		
		// OS version (Apple recommends using SystemVersion.plist instead of Gestalt() here, don't ask me why).
		NSDictionary *systemVersion = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
		NSString *osVersion = [systemVersion objectForKey:@"ProductVersion"];
		if (osVersion != nil) {
			[systemProfile addObject:[FSProfileItem itemWithName:FSLocalizedString(@"OS Version", nil)
															 key:@"os_version"
														   value:osVersion
													visibleValue:osVersion]];
		}
		
		// CPU type (decoder info for values found here is in mach/machine.h)
		error = sysctlbyname("hw.cputype", &value, &length, NULL, 0);
		int cpuType = -1;
		if (error == 0) {
			cpuType = value;
			NSString *visibleCPUType;
			switch(value) {
				case 7:		visibleCPUType=@"Intel";	break;
				case 18:	visibleCPUType=@"PowerPC";	break;
				default:	visibleCPUType=@"Unknown";	break;
			}
			[systemProfile addObject:[FSProfileItem itemWithName:FSLocalizedString(@"CPU Type", nil)
															 key:@"cpu_type"
														   value:[NSNumber numberWithInt:value]
													visibleValue:visibleCPUType]];
		}
		
		error = sysctlbyname("hw.cpusubtype", &value, &length, NULL, 0);
		if (error == 0) {
			NSString *visibleCPUSubType;
			if (cpuType == 7) {
				// Intel
				visibleCPUSubType = @"Intel";	// If anyone knows how to tell a Core Duo from a Core Solo, please email tph@atomicbird.com
			} else if (cpuType == 18) {
				// PowerPC
				switch(value) {
					case 9:					visibleCPUSubType=@"G3";	break;
					case 10:	case 11:	visibleCPUSubType=@"G4";	break;
					case 100:				visibleCPUSubType=@"G5";	break;
					default:				visibleCPUSubType=@"Other";	break;
				}
			} else {
				visibleCPUSubType = @"Other";
			}
			[systemProfile addObject:[FSProfileItem itemWithName:FSLocalizedString(@"CPU Subtype", nil)
															 key:@"cpu_subtype"
														   value:[NSNumber numberWithInt:value]
													visibleValue:visibleCPUSubType]];
		}
		
		error = sysctlbyname("hw.model", NULL, &length, NULL, 0);
		if (error == 0) {
			char *cpuModel;
			cpuModel = (char *)malloc(sizeof(char) * length);
			error = sysctlbyname("hw.model", cpuModel, &length, NULL, 0);
			if (error == 0) {
				
				NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"FSModelTranslation" ofType:@"plist"];
				if (!path) {
					NSBundle *current = [NSBundle bundleForClass:[self class]];
					NSString *frameworkPath = [[[NSBundle mainBundle] sharedFrameworksPath] stringByAppendingPathComponent:[current bundleIdentifier]];
					NSBundle *framework = [NSBundle bundleWithPath:frameworkPath];
					path = [framework pathForResource:@"FSModelTranslation" ofType:@"plist"];
				}
				
				NSDictionary *modelTranslation = [NSDictionary dictionaryWithContentsOfFile:path];
				
				NSString *rawModelName = [NSString stringWithUTF8String:cpuModel];
				NSString *visibleModelName = [modelTranslation objectForKey:rawModelName];
				if (visibleModelName == nil) { visibleModelName = rawModelName; }
				[systemProfile addObject:[FSProfileItem itemWithName:FSLocalizedString(@"Mac Model", nil)
																 key:@"model"
															   value:rawModelName
														visibleValue:visibleModelName]];
			}
			if (cpuModel != NULL) { free(cpuModel);	}
		}
		
		// Number of CPUs
		error = sysctlbyname("hw.ncpu", &value, &length, NULL, 0);
		if (error == 0) {
			[systemProfile addObject:[FSProfileItem itemWithName:FSLocalizedString(@"Number of CPUs", nil)
															 key:@"cpu_count"
														   value:[NSNumber numberWithInt:value]
													visibleValue:[NSNumber numberWithInt:value]]];
		}
		
		// User preferred language
		NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
		NSArray *languages = [defs objectForKey:@"AppleLanguages"];
		if (languages && ([languages count] > 0)) {
			[systemProfile addObject:[FSProfileItem itemWithName:FSLocalizedString(@"Preferred Language", nil)
															 key:@"lang"
														   value:[languages objectAtIndex:0]
													visibleValue:[languages objectAtIndex:0]]];
		}
		
		// Number of displays?
		// CPU speed
		OSErr err;
		SInt32 gestaltInfo;
		err = Gestalt(gestaltProcClkSpeedMHz,&gestaltInfo);
		if (err == noErr) {
			[systemProfile addObject:[FSProfileItem itemWithName:FSLocalizedString(@"CPU Speed (MHz)", nil)
															 key:@"cpu_speed"
														   value:[NSNumber numberWithInt:gestaltInfo]
													visibleValue:[NSNumber numberWithInt:gestaltInfo]]];
		}
		
		// amount of RAM
		err = Gestalt(gestaltPhysicalRAMSizeInMegabytes,&gestaltInfo);
		if (err == noErr) {
			[systemProfile addObject:[FSProfileItem itemWithName:FSLocalizedString(@"Memory (MB)", nil)
															 key:@"ram"
														   value:[NSNumber numberWithInt:gestaltInfo]
													visibleValue:[NSNumber numberWithInt:gestaltInfo]]];
		}		
	}
	
	return systemProfile;
}

+ (NSString *)encodedProfileURLString {
	if (!encodedURL) {
		NSEnumerator *itemEnumerator = [[self systemProfile] objectEnumerator];
		NSMutableArray *components = [NSMutableArray array];
		FSProfileItem *item;
		while ((item = [itemEnumerator nextObject])) {
			[components addObject:[NSString stringWithFormat:@"%@=%@", [item key], [item value]]];
		}
		// Clean it up so it's a valid URL
		encodedURL = [[[components componentsJoinedByString:@"&"]
			stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] retain];
	}
	return encodedURL;
}

@end


#pragma mark profile item
// ----------------------------------------------------------------------------------------------------
// profile item
// ----------------------------------------------------------------------------------------------------

@implementation FSProfileItem

+ (id)itemWithName:(NSString *)aName key:(NSString *)aKey value:(NSObject *)aValue visibleValue:(NSObject *)aVisibleValue {
	return [[[self alloc] initWithName:aName key:aKey value:aValue visibleValue:aVisibleValue] autorelease];
}

- (id)initWithName:(NSString *)aName key:(NSString *)aKey value:(NSObject *)aValue visibleValue:(NSObject *)aVisibleValue {
	if ((self = [super init])) {
		name = [aName retain];
		key = [aKey retain];
		value = [aValue retain];
		visibleValue = [aVisibleValue retain];
	}
	return self;
}

- (void)dealloc {
	[name release];
	[key release];
	[value release];
	[visibleValue release];
	[super dealloc];
}

- (NSString *)name { return name; }
- (NSString *)key { return key; }
- (id)value { return value; }
- (id)visibleValue { return visibleValue; }

@end
