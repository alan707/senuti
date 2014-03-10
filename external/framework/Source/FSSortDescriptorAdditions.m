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

#import "FSSortDescriptorAdditions.h"
#import "FSArrayAdditions.h"

@implementation NSSortDescriptor (FSSortDescriptorAdditions)

+ (id)descriptorWithKey:(NSString *)key ascending:(BOOL)flag selector:(SEL)selector {
	return [[[self alloc] initWithKey:key ascending:flag selector:selector] autorelease];
}

+ (id)descriptorWithKey:(NSString *)key ascending:(BOOL)flag {
	return [[[self alloc] initWithKey:key ascending:flag] autorelease];
}

+ (NSArray *)applyStandardOrdering:(NSArray *)keys toDescriptors:(NSArray *)descriptors {
	
	NSParameterAssert([keys count] > 0);
	
	
	NSString *firstKey = [keys objectAtIndex:0];
	NSSortDescriptor *firstDescriptor = [descriptors firstObject];
	
	if ([[firstDescriptor key] isEqualToString:firstKey]) {

		BOOL needsUpdate = FALSE;

		if ([keys count] > [descriptors count]) {
			needsUpdate = TRUE;
		} else {
			int index;
			for (index = 0; index < [keys count]; index++) {
				if (![[[descriptors objectAtIndex:index] key] isEqualToString:[keys objectAtIndex:index]]) {
					needsUpdate = TRUE;
					break;
				}
			}
		}
		
		if (needsUpdate) {
			NSMutableArray *newDescriptors = [NSMutableArray array];
			
			NSEnumerator *keyEnumerator = [keys objectEnumerator];
			NSString *key;
			while (key = [keyEnumerator nextObject]) {
				[newDescriptors addObject:[NSSortDescriptor descriptorWithKey:key ascending:[firstDescriptor ascending]]];
			}
			
			
			NSEnumerator *descriptorEnumerator = [descriptors objectEnumerator];
			NSSortDescriptor *descriptor;
			while (descriptor = [descriptorEnumerator nextObject]) {
				if (![keys containsObject:[descriptor key]]) {
					[newDescriptors addObject:descriptor];
				}
			}
			
			return newDescriptors;
		}
	}	
	return nil;				
}

@end
