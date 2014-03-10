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

@interface FSOvalActionCell : NSActionCell {
BOOL right_oval;
BOOL left_oval;
BOOL draws_oval;
NSColor *oval_color;
NSColor *border_color;
float border_width;
	BOOL constrain_text;
}

- (void)setDrawsOval:(BOOL)flag;
- (void)setDrawsLeftOval:(BOOL)flag;
- (void)setDrawsRightOval:(BOOL)flag;
- (void)setConstrainText:(BOOL)flag;

- (void)setOvalColor:(NSColor *)color;
- (void)setBorderColor:(NSColor *)color;
- (void)setBorderWidth:(float)width;

- (BOOL)drawsOval;
- (BOOL)drawsLeftOval;
- (BOOL)drawsRightOval;
- (BOOL)constrainText;

- (NSColor *)ovalColor;
- (NSColor *)borderColor;
- (float)borderWidth;

@end
