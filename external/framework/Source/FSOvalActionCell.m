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

#import "FSOvalActionCell.h"

@implementation FSOvalActionCell

- (id)copyWithZone:(NSZone *)zone {
	FSOvalActionCell *newCell = [super copyWithZone:zone];
	
	newCell->oval_color = nil;
	[newCell setOvalColor:oval_color];
	
	newCell->border_color = nil;
	[newCell setBorderColor:border_color];
	
	[newCell setDrawsOval:draws_oval];
	[newCell setDrawsRightOval:right_oval];
	[newCell setDrawsLeftOval:left_oval];
	[newCell setBorderWidth:border_width];
	[newCell setConstrainText:constrain_text];
	
	return newCell;
}

- (id)init {
	self = [super init];
	draws_oval = FALSE;
	right_oval = TRUE;
	left_oval = TRUE;
	oval_color = nil;
	border_color = nil;
	border_width = 1.0;
	constrain_text = TRUE;
	return self;
}

- (void)dealloc {
	[oval_color release];
	[border_color release];
	[super dealloc];
}

- (void)setDrawsOval:(BOOL)flag {
	draws_oval = flag;
}
- (void)setDrawsLeftOval:(BOOL)flag {
	left_oval = flag;
}
- (void)setDrawsRightOval:(BOOL)flag {
	right_oval = flag;
}

- (void)setConstrainText:(BOOL)flag {
	constrain_text = flag;
}

- (void)setOvalColor:(NSColor *)color {
	if (oval_color != color)
	{
		[oval_color release];
		oval_color = [color retain];
	}
}

- (void)setBorderColor:(NSColor *)color {
	if (border_color != color)
	{
		[border_color release];
		border_color = [color retain];
	}
}

- (void)setBorderWidth:(float)width {
	border_width = width;
}

- (BOOL)drawsOval {
	return draws_oval;
}
- (BOOL)drawsLeftOval {
	return left_oval;
}
- (BOOL)drawsRightOval {
	return right_oval;
}

- (NSColor *)ovalColor {
	return oval_color;
}
- (NSColor *)borderColor {
	return border_color;
}
- (float)borderWidth {
	return border_width;
}
- (BOOL)constrainText {
	return constrain_text;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSRect inner = cellFrame;
	// draw the left
	if (left_oval) {
		NSRect left;
		NSDivideRect(inner, &left, &inner, inner.size.height, NSMinXEdge);
		if (border_color) {
			if (![self isHighlighted] && draws_oval) { [border_color set]; [[NSBezierPath bezierPathWithOvalInRect:left] fill]; }
			left.size.width -= (border_width * 2); left.size.height -= (border_width * 2); left.origin.x += border_width; left.origin.y += border_width;
		}
		if (![self isHighlighted] && draws_oval) { [oval_color set]; [[NSBezierPath bezierPathWithOvalInRect:left] fill]; }
		inner = NSMakeRect(inner.origin.x - (inner.size.height / 2), inner.origin.y, inner.size.width + (inner.size.height / 2), inner.size.height);
	}
	
	// draw the right
	if (right_oval) {
		NSRect right;
		NSDivideRect(inner, &right, &inner, inner.size.height, NSMaxXEdge);
		if (border_color) {
			if (![self isHighlighted] && draws_oval) { [border_color set]; [[NSBezierPath bezierPathWithOvalInRect:right] fill]; }
			right.size.width -= (border_width * 2); right.size.height -= (border_width * 2); right.origin.x += border_width; right.origin.y += border_width;
		}
		if (![self isHighlighted] && draws_oval) { [oval_color set]; [[NSBezierPath bezierPathWithOvalInRect:right] fill]; }
		inner = NSMakeRect(inner.origin.x, inner.origin.y, inner.size.width + (inner.size.height / 2), inner.size.height);
	}
	
	// draw interior
	if (border_color) {
		if (![self isHighlighted] && draws_oval) { [border_color set]; [NSBezierPath fillRect:inner]; }
		inner.size.height -= (border_width * 2); inner.origin.y += border_width;
	}
	if (![self isHighlighted] && draws_oval) { [oval_color set]; [NSBezierPath fillRect:inner]; }

	if ([self constrainText])
	{
		[super drawWithFrame:inner inView:controlView];
	} else {
		[super drawWithFrame:cellFrame inView:controlView];
	}
}

@end
