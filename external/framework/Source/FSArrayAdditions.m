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

#import "FSArrayAdditions.h"

@implementation NSArray (FSArrayExtensions)

- (id)firstObject {
	if ([self count] > 0) { return [self objectAtIndex:0]; }
	else { return nil; }
}

- (NSArray *)arrayByPerformingSelectorOnObjects:(SEL)selector {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
	unsigned int i;
	for (i = 0; i < [self count]; i++) {
		[array addObject:[[self objectAtIndex:i] performSelector:selector]];
	}
	return array;
}

- (NSArray *)arrayByPerformingSelectorWithObjects:(SEL)selector onTarget:(id)target {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
	unsigned int i;
	for (i = 0; i < [self count]; i++) {
		[array addObject:[target performSelector:selector withObject:[self objectAtIndex:i]]];
	}
	return array;	
}

- (NSArray *)filter:(SEL)selector where:(id)value {
	id object;
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
	NSEnumerator *objectEnumerator = [self objectEnumerator];
	while (object = [objectEnumerator nextObject]) {
		if ([[object performSelector:selector] isEqualTo:value]) {
			[array addObject:object];
		}
	}
	return [NSArray arrayWithArray:array];
}

@end
