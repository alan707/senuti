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

#import "SEGripperView.h"

#define GRAY_COLOR  	0.30
#define WHITE_COLOR 	0.97
#define ALPHA   		0.90

@implementation SEGripperView

- (void)drawRect:(NSRect)aRect {
	[[NSColor colorWithCalibratedWhite:GRAY_COLOR alpha:ALPHA] set];

	int middle_x = aRect.origin.x + aRect.size.width / 2;
	int middle_y = aRect.origin.y + aRect.size.height / 2;
	NSRect fill1 = NSMakeRect(middle_x - 3, middle_y - 5, 1, 10);
	NSRect fill2 = NSMakeRect(middle_x, middle_y - 5, 1, 10);
	NSRect fill3 = NSMakeRect(middle_x + 3, middle_y - 5, 1, 10);
	
	[NSBezierPath fillRect:fill1];
	[NSBezierPath fillRect:fill2];
	[NSBezierPath fillRect:fill3];
	
	fill1.origin.x += 1;
	fill1.origin.y -= 1;
	fill2.origin.x += 1;
	fill2.origin.y -= 1;
	fill3.origin.x += 1;
	fill2.origin.y -= 1;
	
	[[NSColor colorWithCalibratedWhite:WHITE_COLOR alpha:ALPHA] set];
	
	[NSBezierPath fillRect:fill1];
	[NSBezierPath fillRect:fill2];
	[NSBezierPath fillRect:fill3];	
}

@end
