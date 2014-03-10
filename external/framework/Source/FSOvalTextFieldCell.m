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

#import "FSOvalTextFieldCell.h"

@implementation FSOvalTextFieldCell

- (id)copyWithZone:(NSZone *)zone {
	FSOvalTextFieldCell *newCell = [super copyWithZone:zone];
	
	newCell->oval_color = nil;
	[newCell setOvalColor:oval_color];
		
	[newCell setDrawsRightOval:right_oval];
	[newCell setDrawsLeftOval:left_oval];
	[newCell setConstrainText:constrain_text];
	
	return newCell;
}

- (id)init {
	if (self = [super init]) {
		right_oval = TRUE;
		left_oval = TRUE;
		oval_color = nil;
		constrain_text = TRUE;		
	}
	return self;
}

- (void)awakeFromNib {
	right_oval = TRUE;
	left_oval = TRUE;
	constrain_text = TRUE;		
}

- (void)dealloc {
	[oval_color release];
	[super dealloc];
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
	if (oval_color != color) {
		[oval_color release];
		oval_color = [color retain];
	}
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
- (BOOL)constrainText {
	return constrain_text;
}

- (NSSize)cellSizeForBounds:(NSRect)aRect {
	NSSize size = [super cellSizeForBounds:aRect];
	if ([self constrainText]) {
		if (left_oval) { size.width += (size.height / 2); }
		if (right_oval) { size.width += (size.height / 2); }
	}
	return size;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSRect inner = cellFrame;
	
	// set the color
	if (oval_color) { [oval_color set]; }
	
	// draw the left
	if (left_oval) {
		NSRect left;
		NSDivideRect(inner, &left, &inner, inner.size.height, NSMinXEdge);
		if (oval_color && ![self isHighlighted]) {
			[[NSBezierPath bezierPathWithOvalInRect:left] fill];
		}
		inner.origin.x -= (inner.size.height / 2);
		inner.size.width += (inner.size.height / 2);
	}

	// draw the right
	if (right_oval) {
		NSRect right;
		NSDivideRect(inner, &right, &inner, inner.size.height, NSMaxXEdge);
		if (oval_color && ![self isHighlighted]) {
			[[NSBezierPath bezierPathWithOvalInRect:right] fill];
		}
	   inner.size.width += (inner.size.height / 2);
	}

	// draw interior
	if (oval_color && ![self isHighlighted]) { [NSBezierPath fillRect:inner]; }
	
	if ([self constrainText]) { [super drawWithFrame:inner inView:controlView]; }
	else { [super drawWithFrame:cellFrame inView:controlView]; }
}

@end