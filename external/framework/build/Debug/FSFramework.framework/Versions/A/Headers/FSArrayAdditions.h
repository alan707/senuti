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

@interface NSArray (FSArrayExtensions)

/* Returns the first object or nil if
 * the array is empty */
- (id)firstObject;

- (NSArray *)arrayByPerformingSelectorOnObjects:(SEL)selector;
- (NSArray *)arrayByPerformingSelectorWithObjects:(SEL)selector onTarget:(id)target;

/* Filters the array by performing the selector on each object
 * only objects whose value is equal to the value in the where
 * clause are returned in the result */
- (NSArray *)filter:(SEL)selector where:(id)value;
@end
