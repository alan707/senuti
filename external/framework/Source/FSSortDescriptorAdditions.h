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

@interface NSSortDescriptor (FSSortDescriptorAdditions)

+ (id)descriptorWithKey:(NSString *)key ascending:(BOOL)flag;
+ (id)descriptorWithKey:(NSString *)key ascending:(BOOL)flag selector:(SEL)selector;

/* Will analyize keys and check to make sure that the descriptors keep the ordering
 * specified in keys.  If the first key in keys is different from the first descriptor's
 * key, then standard ordering won't be applied (nil will be returned).  If the descriptors
 * start with all the same keys (proper ordering) then ordering will not be applied (nil
 * will be returned). */
+ (NSArray *)applyStandardOrdering:(NSArray *)keys toDescriptors:(NSArray *)descriptors;

@end
