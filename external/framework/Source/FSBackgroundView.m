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

#import "FSBackgroundView.h"
#import "AIGradient.h"

@implementation FSBackgroundView

- (void)dealloc {
	[backgroundColor release];
	[borderColor release];
	[backgroundGradient release];
	[super dealloc];
}

- (void)setDrawsBackground:(BOOL)flag {
	drawsBackground = flag;
}

- (BOOL)drawsBackground {
	return drawsBackground;
}

- (void)setBackgroundGradient:(AIGradient *)gradient {
	if (backgroundGradient != gradient) {
		[backgroundGradient release];
		backgroundGradient = [gradient retain];
	}
}
- (AIGradient *)backgroundGradient {
	return backgroundGradient;
}

- (void)setBackgroundColor:(NSColor *)color {
	if (backgroundColor != color) {
		[backgroundColor release];
		backgroundColor = [color retain];
	}
}

- (NSColor *)backgroundColor {
	return backgroundColor;
}

- (void)setDrawsBorder:(BOOL)flag {
	drawsBorder = flag;
}

- (BOOL)drawsBorder {
	return drawsBorder;
}

- (void)setBorderColor:(NSColor *)color {
	if (borderColor != color) {
		[borderColor release];
		borderColor = [color retain];
	}
}

- (NSColor *)borderColor {
	return borderColor;
}

- (void)drawRect:(NSRect)rect {
	
	if ([self drawsBackground] && [self backgroundGradient]) {
		if ([[self backgroundGradient] direction] == AIVertical) {
			rect.origin.y = 0;
			rect.size.height = [self frame].size.height;
		} else {
			rect.origin.x = 0;
			rect.size.width = [self frame].size.width;
		}
		[[self backgroundGradient] drawInRect:rect];
	} else if ([self drawsBackground] && [self backgroundColor]) {
		[[self backgroundColor] set];
		[NSBezierPath fillRect:rect];
	}
	
	if ([self drawsBorder] && [self borderColor]) {
		float height = [self frame].size.height;
		float width = [self frame].size.width;
		NSRect left = NSMakeRect(0, 0, 1, height);
		NSRect right = NSMakeRect(0, width-1, 1, height);
		NSRect top = NSMakeRect(0, height-1, width, 1);
		NSRect bottom = NSMakeRect(0, 0, width, 1);
		
		[[self borderColor] set];
		[NSBezierPath fillRect:left];
		[NSBezierPath fillRect:right];
		[NSBezierPath fillRect:top];
		[NSBezierPath fillRect:bottom];
	}
}

@end
