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

#import "FSButtonImageTextCell.h"

#define MAX_IMAGE_WIDTH			24.0f
#define IMAGE_TEXT_PADDING		6.0f

typedef enum _FSButtonImageTextCellState {
	FSButtonImageTextCellInactiveState,
	FSButtonImageTextCellHoverState,
	FSButtonImageTextCellPressedState
} FSButtonImageTextCellState;

@interface FSButtonImageTextCell (PRIVATE)
- (NSRect)buttonRectForFrame:(NSRect)cellFrame;
- (void)_buttonImageTextCellInitialize;
@end

@implementation FSButtonImageTextCell

- (id)init {
	if ((self = [super init])) {
		[self _buttonImageTextCellInitialize];
	}
	return self;	
}

- (id)initTextCell:(NSString *)text {
	if ((self = [super initTextCell:text])) {
		[self _buttonImageTextCellInitialize];
	}
	return self;	
}

- (id)initImageCell:(NSImage *)image {
	if ((self = [super initImageCell:image])) {
		[self _buttonImageTextCellInitialize];
	}
	return self;
}

- (void)awakeFromNib {
	[self _buttonImageTextCellInitialize];
}

- (void)_buttonImageTextCellInitialize {
	inactiveOpacity = 0.5;
	hoverOpacity = 0.75;
	pressedOpacity = 1.0;
}

- (id)copyWithZone:(NSZone *)zone
{
	FSButtonImageTextCell *newCell = [super copyWithZone:zone];
	
	newCell->buttonImage = nil;
	[newCell setButtonImage:buttonImage];
	
	newCell->target = nil;
	[newCell setTarget:target];
	
	newCell->action = action;
	newCell->inactiveOpacity = inactiveOpacity;
	newCell->hoverOpacity = hoverOpacity;
	newCell->pressedOpacity = pressedOpacity;
	
	return newCell;
}

- (void)dealloc {
	[buttonImage release];
	[target release];
	[super dealloc];
}


#pragma mark responding to update messages from the table view
// ----------------------------------------------------------------------------------------------------
// responding to update messages from the table view
// ----------------------------------------------------------------------------------------------------

- (BOOL)mouseExitedInvalidatesForFrame:(NSRect)cellFrame { return buttonImage != nil; }
- (BOOL)mouseMoveToPoint:(NSPoint)point invalidatesForFrame:(NSRect)cellFrame { return buttonImage != nil; }

- (BOOL)mouseUpAtPoint:(NSPoint)point invalidatesForFrame:(NSRect)cellFrame controlView:(NSControl *)controlView {
	// if point inside, call the action
	if (NSPointInRect(point, [self buttonRectForFrame:cellFrame])) {
		[self buttonClickAtPoint:point inFrame:cellFrame controlView:controlView];
	}
	return TRUE;
}

- (void)buttonClickAtPoint:(NSPoint)point inFrame:(NSRect)cellFrame controlView:(NSControl *)controlView {
	[target performSelector:action withObject:self];
}

- (BOOL)trackMouseAtPoint:(NSPoint)point cellFrame:(NSRect)cellFrame controlView:(NSControl *)controlView {
	return buttonImage && NSPointInRect(point, [self buttonRectForFrame:cellFrame]);
}

- (BOOL)continueTrackingMouseAtPoint:(NSPoint)point cellFrame:(NSRect)cellFrame controlView:(NSControl *)controlView { return TRUE; }

#pragma mark properties
// ----------------------------------------------------------------------------------------------------
// properties
// ----------------------------------------------------------------------------------------------------

- (NSImage *)buttonImage {
	return buttonImage;
}

- (void)setButtonImage:(NSImage *)image {
	if (image != buttonImage) {
		[buttonImage release];
		buttonImage = [image retain];
	}
}

- (id)target {
	return target;
}

- (void)setTarget:(id)tar {
	if (tar != target) {
		[target release];
		target = [tar retain];
	}
}

- (SEL)action {
	return action;
}

- (void)setAction:(SEL)act {
	action = act;
}


- (float)inactiveOpacity { return inactiveOpacity; }
- (void)setInactiveOpacity:(float)value { inactiveOpacity = value; }

- (float)hoverOpacity { return hoverOpacity; }
- (void)setHoverOpacity:(float)value { hoverOpacity = value; }

- (float)pressedOpacity { return pressedOpacity; }
- (void)setPressedOpacity:(float)value { pressedOpacity = value; }


#pragma mark drawing
// ----------------------------------------------------------------------------------------------------
// drawing
// ----------------------------------------------------------------------------------------------------

- (NSRect)buttonRectForFrame:(NSRect)cellFrame {
	NSRect dest;
	dest.size = [buttonImage size];
	dest.origin = cellFrame.origin;
		
	// Center image vertically, or scale as needed
	if (dest.size.height > cellFrame.size.height) {
		float proportionChange = cellFrame.size.height / [buttonImage size].height;
		dest.size.height = cellFrame.size.height;
		dest.size.width = [buttonImage size].width * proportionChange;
	}
	
	if (dest.size.width > MAX_IMAGE_WIDTH) {
		float proportionChange = MAX_IMAGE_WIDTH / dest.size.width;
		dest.size.width = MAX_IMAGE_WIDTH;
		dest.size.height = dest.size.height * proportionChange;
	}
	
	if (dest.size.height < cellFrame.size.height) {
		dest.origin.y += (cellFrame.size.height - dest.size.height) / 2.0;
	} 
	
	// Adjust the rects
	dest.origin.y += 1;
	dest.origin.x += cellFrame.size.width;
	dest.origin.x -= [buttonImage size].width;
	dest.origin.x -= IMAGE_TEXT_PADDING;
	return dest;
}

- (NSSize)cellSizeForBounds:(NSRect)cellFrame {
	NSSize s = [super cellSizeForBounds:cellFrame];
	s.width += [self buttonRectForFrame:cellFrame].size.width;
	return s;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {

	// Draw the cell's button image
	if (buttonImage != nil) {
		
		NSRect dest = [self buttonRectForFrame:cellFrame];
		
		// Decrease the cell width by the width of the image we drew and its left padding
		cellFrame.size.width -= IMAGE_TEXT_PADDING + dest.size.width;
				
		BOOL flippedIt = NO;
		if (![buttonImage isFlipped]) {
			[buttonImage setFlipped:YES];
			flippedIt = YES;
		}
		
		float fraction = 1.0;
		FSButtonImageTextCellState state;
		NSEvent *event = [NSApp currentEvent];
		NSPoint	mouseLocation = [controlView convertPoint:[event locationInWindow] fromView:[[controlView window] contentView]];
		BOOL inRegion = NSPointInRect(mouseLocation, dest);
		if (([event type] == NSLeftMouseDown || [event type] == NSLeftMouseDragged) &&
			[event clickCount] && inRegion) { state = FSButtonImageTextCellPressedState; }
		else if (inRegion) { state = FSButtonImageTextCellHoverState; }
		else { state = FSButtonImageTextCellInactiveState; }
		switch(state) {
			case FSButtonImageTextCellInactiveState: fraction = inactiveOpacity; break;
			case FSButtonImageTextCellHoverState: fraction = hoverOpacity; break;
			case FSButtonImageTextCellPressedState: fraction = pressedOpacity; break;
			default: break;
		}
		
		if (fraction) {
			[NSGraphicsContext saveGraphicsState];
			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
			[buttonImage drawInRect:NSMakeRect(dest.origin.x,dest.origin.y,dest.size.width,dest.size.height)
						   fromRect:NSMakeRect(0,0,[buttonImage size].width,[buttonImage size].height)
						  operation:NSCompositeSourceOver
						   fraction:fraction];
			[NSGraphicsContext restoreGraphicsState];
		}
		
		if (flippedIt) {
			[buttonImage setFlipped:NO];
		}
	}
	
	// Draw the rest of the cell
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
