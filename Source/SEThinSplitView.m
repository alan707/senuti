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

#import "SEThinSplitView.h"
#define GRAY_COLOR 0.64705882

@implementation SEThinSplitView

- (void)awakeFromNib {
	// since the split view isn't a NSSplitView, make sure all the views fit properly
	NSEnumerator *enumerator = [[self subviews] objectEnumerator];
	NSView *view;
	while (view = [enumerator nextObject]) {
		NSEnumerator *subEnumerator = [[view subviews] objectEnumerator];
		NSView *subview;
		while (subview = [subEnumerator nextObject]) {
			NSSize size;
			if ([self isVertical]) { size = NSMakeSize([view frame].size.width, [subview frame].size.height); }
			else { size = NSMakeSize([subview frame].size.width, [view frame].size.height); }
			[subview setFrameSize:size];
		}
	}
}

- (float)dividerThickness {
	return 1;
}
- (void)drawDividerInRect:(NSRect)aRect {
	[[NSColor colorWithCalibratedRed:GRAY_COLOR green:GRAY_COLOR blue:GRAY_COLOR alpha:1] set];
	[NSBezierPath fillRect:aRect];
}

@end
