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

/* This code is taken from Sean Patrick O'Brien's iLife Controls
 * and has been minimally modified.  It is published under an MIT
 * license, and that license holds for this file. */

//
//  FSHUDFrame.m
//  iLife HUD Window
//
//  Created by Sean Patrick O'Brien on 9/23/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "FSHUDBorderlessFrame.h"

@interface FSHUDBorderlessFrame (PRIVATE)
+ (NSBezierPath*)_clippingPathForFrame:(NSRect)aRect;
@end

@implementation FSHUDBorderlessFrame

- (id)initWithFrame:(NSRect)frame styleMask:(unsigned int)style owner:(id)owner
{
	//frame.size.height -= [super _titlebarHeight];
	if([super initWithFrame:frame styleMask:style owner:owner])
	{		
		// get the regular controls out of the picture
		[closeButton setHidden:YES];
		[minimizeButton setHidden:YES];
		[zoomButton setHidden:YES];
		
		// according to Andy Matuschak, the superclass doesn't do it's job here...
		[[self window] setShowsResizeIndicator:(style & NSResizableWindowMask)];
		
		return self;
	}
	
	return nil;
}

+ (struct _NSRect)frameRectForContentRect:(struct _NSRect)fp8 styleMask:(unsigned int)fp24 {
	fp8.size.width += 2;
	fp8.size.height += 2;
	return fp8;
}
+ (struct _NSRect)contentRectForFrameRect:(struct _NSRect)fp8 styleMask:(unsigned int)fp24 {
	fp8.size.width -= 2;
	fp8.size.height -= 2;
	return fp8;
}

+ (NSBezierPath*)_clippingPathForFrame:(NSRect)aRect
{
	float radius = 6.5;
	NSBezierPath *path = [NSBezierPath alloc];
	NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
	NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
	NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
	NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));

	[path moveToPoint: topMid];
	[path appendBezierPathWithArcFromPoint: topRight
		toPoint: bottomRight
		radius: radius];
	[path appendBezierPathWithArcFromPoint: bottomRight
		toPoint: aRect.origin
		radius: radius];
	[path appendBezierPathWithArcFromPoint: aRect.origin
		toPoint: topLeft
		radius: radius];
	[path appendBezierPathWithArcFromPoint: topLeft
		toPoint: topRight
		radius: radius];
	[path closePath];
	
	return path;
}

- (void)drawRect:(NSRect)_rect
{
	NSRect rect = [self frame];
	[[NSColor clearColor] set];
	NSRectFill(rect);
	NSRectFill(_rect);
	
	NSBezierPath *path = [[self class] _clippingPathForFrame: rect];
	[path addClip];
	
	[[NSColor colorWithCalibratedWhite:32/255.0 alpha:213/255.0] set];
	
	NSRectFill(rect);
}

- (NSRect)contentRectForFrameRect:(NSRect)frameRect styleMask:(unsigned int)aStyle
{
	frameRect.size.width -= 2;
	frameRect.origin.x += 1;
    return frameRect;
}


- (NSRect)frameRectForContentRect:(NSRect)windowContent styleMask:(unsigned int)aStyle
{
	windowContent.size.width += 2;
	windowContent.origin.x -= 1;
    return windowContent;
}

- (NSRect)titlebarRect {
	return NSZeroRect;
}

// Taken directly from Andy Matuschak's implementation
- (void)_drawResizeIndicators:(NSRect)rect
{
	if (![[self window] showsResizeIndicator])
		return;
	NSPoint resizeOrigin = NSMakePoint(NSMaxX([self frame]) - 3, 3);
	NSBezierPath *resizeGrip = [NSBezierPath bezierPath];
	[resizeGrip moveToPoint:NSMakePoint(resizeOrigin.x, resizeOrigin.y + 2)];
	[resizeGrip lineToPoint:NSMakePoint(resizeOrigin.x - 3, resizeOrigin.y)];
	[resizeGrip moveToPoint:NSMakePoint(resizeOrigin.x, resizeOrigin.y + 6)];
	[resizeGrip lineToPoint:NSMakePoint(resizeOrigin.x - 7, resizeOrigin.y)];
	[resizeGrip moveToPoint:NSMakePoint(resizeOrigin.x, resizeOrigin.y + 10)];
	[resizeGrip lineToPoint:NSMakePoint(resizeOrigin.x - 11, resizeOrigin.y)];		
	[resizeGrip setLineWidth:1.0];
	
	[[NSColor lightGrayColor] set];
	[resizeGrip stroke];	
}

@end
