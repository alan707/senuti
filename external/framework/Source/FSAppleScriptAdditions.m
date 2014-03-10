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

#import "FSAppleScriptAdditions.h"
#import <Carbon/Carbon.h>

@implementation NSAppleScript (FSAppleScriptAdditions)

- (NSAppleEventDescriptor *)executeFunction:(NSString *)functionName error:(NSDictionary **)errorInfo {
	return [self executeFunction:functionName withArguments:nil error:errorInfo];
}

+ (NSAppleEventDescriptor *)descriptorForArray:(NSArray *)argumentArray {
	NSAppleEventDescriptor  *arguments = [[[NSAppleEventDescriptor alloc] initListDescriptor] autorelease];
	NSEnumerator			*enumerator = [argumentArray objectEnumerator];
	NSString				*object;
	
	while((object = [enumerator nextObject])) {
		NSAppleEventDescriptor *descriptor;
		if ([object isKindOfClass:[NSString class]]) {
			descriptor = [NSAppleEventDescriptor descriptorWithString:object];
		} else if ([object isKindOfClass:[NSNumber class]]) {
			descriptor = [NSAppleEventDescriptor descriptorWithInt32:[object intValue]];
		} else if ([object isKindOfClass:[NSDate class]]) {
			descriptor = [NSAppleEventDescriptor descriptorWithDate:(NSDate *)object];
		} else if ([object isKindOfClass:[NSArray class]]) {
			descriptor = [NSAppleScript descriptorForArray:(NSArray *)object];
		}
		[arguments insertDescriptor:descriptor
							atIndex:[arguments numberOfItems]+1]; //This +1 seems wrong... but it's not :)
		}

	return arguments;
}

- (NSAppleEventDescriptor *)executeFunction:(NSString *)functionName withArguments:(NSArray *)argumentArray error:(NSDictionary **)errorInfo {
	NSAppleEventDescriptor	*thisApplication;
	NSAppleEventDescriptor	*containerEvent;

	//Get a descriptor for ourself
	int pid = [[NSProcessInfo processInfo] processIdentifier];
	thisApplication = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID
																	 bytes:&pid
																	length:sizeof(pid)];
	
	//Create the container event
	containerEvent = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
															  eventID:kASSubroutineEvent
													 targetDescriptor:thisApplication
															 returnID:kAutoGenerateReturnID
														transactionID:kAnyTransactionID];
	
	//Set the target function
	[containerEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:functionName]
							forKeyword:keyASSubroutineName];
	
	//Pass arguments - arguments is expecting an NSArray with only NSString objects
	if([argumentArray count]){
		NSAppleEventDescriptor *arguments = [NSAppleScript descriptorForArray:argumentArray];
		[containerEvent setParamDescriptor:arguments forKeyword:keyDirectObject];
	}
	
	//Execute the event
	return [self executeAppleEvent:containerEvent error:errorInfo];
}

@end


@implementation NSAppleEventDescriptor (FSAppleScriptAdditions)

+ (NSAppleEventDescriptor *)descriptorWithDate:(NSDate *)date {
	return [[[[self class] alloc] initWithDate:date] autorelease];
}

- (id)initWithDate:(NSDate *)date {
	LongDateTime ldt;	
	UCConvertCFAbsoluteTimeToLongDateTime(CFDateGetAbsoluteTime((CFDateRef)date), &ldt);
	return [self initWithDescriptorType:typeLongDateTime
								  bytes:&ldt
								 length:sizeof(ldt)];
}

@end
