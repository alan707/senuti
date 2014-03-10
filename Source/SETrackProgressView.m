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

#import "SETrackProgressView.h"

static NSImage *background = nil;
static NSImage *border = nil;

@implementation SETrackProgressView

- (double)doubleValue {
	return value;	
}

- (void)setDoubleValue:(double)val {
	BOOL display = FALSE;
	if (fabs(val - last) > 0.001) {
		display = TRUE;
		last = val;
	}
	value = val;
	if (display) { [self setNeedsDisplay:TRUE]; }
}

- (id)target {
	return target;
}

- (void)setTarget:(id)t {
	target = t;
}

- (SEL)action {
	return action;
}

- (void)setAction:(SEL)a {
	action = a;
}

- (BOOL)enabled {
	return enabled;
}

- (void)setEnabled:(BOOL)e {
	enabled = e;
}

- (void)drawRect:(NSRect)frameRect {

	NSRect rect = [self bounds];
	NSRect progressRect = rect;
	
	if (!background) { background = [NSImage imageNamed:@"progress_background"]; }
	if (!border) { border = [NSImage imageNamed:@"progress_border"]; }
	
	[background drawInRect:rect atSize:[background size] position:IMAGE_POSITION_LOWER_LEFT fraction:1];
	
	[[NSColor colorWithCalibratedWhite:0.34901961 alpha:0.3] set];
	progressRect.size.width *= value;
	[NSBezierPath fillRect:progressRect];
	
	[border drawInRect:rect atSize:[border size] position:IMAGE_POSITION_LOWER_LEFT fraction:1];
}

- (void)mouseDown:(NSEvent *)theEvent {
	if (enabled) {
		NSEvent *upEvent = [[self window] nextEventMatchingMask:NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
		NSPoint point = [self convertPoint:[upEvent locationInWindow] fromView:[[self window] contentView]];		
		if (point.x > 0 && point.y > 0 && point.x < [self bounds].size.width && point.y < [self bounds].size.height) {
			[self setDoubleValue:point.x / [self bounds].size.width];
			[target performSelector:action withObject:self];
		}
	} else {
		[super mouseDown:theEvent];
	}
}

@end
