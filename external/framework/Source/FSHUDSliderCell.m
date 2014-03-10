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
//  FSHUDSliderCell.m
//  iLife HUD Window
//
//  Created by Sean Patrick O'Brien on 9/23/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "FSHUDSliderCell.h"
#import "NSImage+FrameworkImage.h"

@implementation FSHUDSliderCell

- (void)drawBarInside:(NSRect)cellFrame flipped:(BOOL)flipped
{
	NSImage *leftImage = [NSImage frameworkImageNamed:@"HUDSliderTrackLeft.tiff"];
	NSImage *fillImage = [NSImage frameworkImageNamed:@"HUDSliderTrackFill.tiff"];
	NSImage *rightImage = [NSImage frameworkImageNamed:@"HUDSliderTrackRight.tiff"];
				
	NSSize size = [leftImage size];
	float addX = size.width / 2.0;
	float y = NSMaxY(cellFrame) - (cellFrame.size.height-size.height)/2.0 - 1;
	float x = cellFrame.origin.x+addX;
	float fillX = x + size.width;
	float fillWidth = cellFrame.size.width - size.width - addX;
	
	[leftImage compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];

	size = [rightImage size];
	addX = size.width / 2.0;
	x = NSMaxX(cellFrame) - size.width - addX;
	fillWidth -= size.width+addX;
	
	[rightImage compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];
	
	[fillImage setScalesWhenResized:YES];
	[fillImage setSize:NSMakeSize(fillWidth, [fillImage size].height)];
	[fillImage compositeToPoint:NSMakePoint(fillX, y) operation:NSCompositeSourceOver];
}

- (void)drawKnob:(NSRect)rect
{
	NSImage *knob;
	
	if([self numberOfTickMarks] == 0)
		knob = [NSImage frameworkImageNamed:@"HUDSliderKnobRound.tiff"];
	else
		knob = [NSImage frameworkImageNamed:@"HUDSliderKnob.tiff"];
	
	float x = rect.origin.x + (rect.size.width - [knob size].width) / 2;
	float y = NSMaxY(rect) - (rect.size.height - [knob size].height) / 2 ;
	
	[knob compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];
}

-(NSRect)knobRectFlipped:(BOOL)flipped
{
	NSRect rect = [super knobRectFlipped:flipped];
	if([self numberOfTickMarks] > 0){
		rect.size.height+=2;
		return NSOffsetRect(rect, 0, flipped ? 2 : -2);
		}
	return rect;
}

- (BOOL)_usesCustomTrackImage
{
	return YES;
}

@end
