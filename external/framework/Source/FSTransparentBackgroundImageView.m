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

#import "FSTransparentBackgroundImageView.h"
#import "AIImageAdditions.h"

@implementation FSTransparentBackgroundImageView

- (id)initWithFrame:(NSRect)inFrame
{
	if ((self = [super initWithFrame:inFrame])) {
		transparentRect = NSZeroRect;
		opacity = 0.30;
	}
	
	return self;
}

- (void)setBackgroundImage:(NSImage *)inImage
{
	if (backgroundImage != inImage) {
		[backgroundImage release];
		backgroundImage = [inImage retain];	
	}
	
	[self setNeedsDisplay:YES];
}

- (void)setTransparentRect:(NSRect)inTransparentRect
{
	transparentRect = inTransparentRect;
	
	[self setNeedsDisplay:YES];
}

- (void)setOpacity:(float)value {
	opacity = value;
}

- (float)opacity {
	return opacity;
}

/*
 * @brief Draw our background image
 *
 * The image is drawn faded behind our content view and solid elsewhere.
 *
 * Random Things I Remembered note: Unless you have a good reason, you always want to use -[NSBezierPath addClip], not -[NSBezierPath setClip],
 * so you take into account the existing clip rect.
 */
- (void)drawRect:(NSRect)rect {
	NSRect		 imageDrawingRect = NSInsetRect([self bounds], 0, 0);
	
	if (backgroundImage && NSIntersectsRect(imageDrawingRect, rect)) {
		NSSize		 imageSize = [backgroundImage size];
		NSBezierPath *path;
		
		imageDrawingRect.size.height -= 30;
		
		//Clip to our content view and draw faded if we're supposed to draw in that area
		path = [NSBezierPath bezierPathWithRect:transparentRect];
		if (NSIntersectsRect(transparentRect, rect)) {
			[NSGraphicsContext saveGraphicsState];
			[path addClip];
			
			[backgroundImage drawInRect:imageDrawingRect
								 atSize:imageSize
							   position:IMAGE_POSITION_LEFT
							   fraction:opacity];
			[NSGraphicsContext restoreGraphicsState];
		}		
		
		//Now clip to everywhere that isn't our content view and draw non-faded
		[path appendBezierPathWithRect:NSInsetRect([self bounds], -1, -1)];
		[path setWindingRule:NSEvenOddWindingRule];
		
		[NSGraphicsContext saveGraphicsState];
		[path addClip];
		
		[backgroundImage drawInRect:imageDrawingRect
							 atSize:imageSize
						   position:IMAGE_POSITION_LEFT
						   fraction:1.0];
		[NSGraphicsContext restoreGraphicsState];
	}
}

@end
