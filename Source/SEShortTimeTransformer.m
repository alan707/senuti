/* 
 * Senuti is the legal property of its developers, whose names are listed in the copyright file included
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

#import "SEShortTimeTransformer.h"

@implementation SEShortTimeTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;   
}

- (id)transformedValue:(id)value {
	
    int seconds = 0;
	if (value == nil) return nil;
	if ([value respondsToSelector:@selector(intValue)]) { seconds = [value intValue]; }
	else { [NSException raise:NSInternalInconsistencyException format:@"Value (%@) does not respond to -intValue.", [value class]]; }
	
	float time = seconds;
	NSString *label = FSLocalizedString(@"seconds", nil);
	if (time > 60) {
		time = time / 60;
		label = FSLocalizedString(@"minutes", nil);
		
		if (time > 60) {
			time = time / 60;
			label = FSLocalizedString(@"hours", nil);
			
			if (time > 24) {
				time = time / 24;
				label = FSLocalizedString(@"days", nil);
				
				if (time > 365) {
					time = time / 365;
					label = FSLocalizedString(@"years", nil);
				}
			}
		}
	}
	
	return [NSString stringWithFormat:FSLocalizedString(@"%.1f %@", nil), time, label];
}

@end
