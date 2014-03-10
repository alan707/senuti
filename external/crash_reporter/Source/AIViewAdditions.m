//
//  AIViewAdditions.m
//  CrashReporter
//
//  Created by Whitney Young on 8/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIViewAdditions.h"


@implementation NSView (AIViewAdditions)

- (float)resizeViewToHeight:(float)height
			   expandToward:(unsigned)edge
				  moveViews:(NSArray *)moveViews
				shrinkViews:(NSArray *)shrinkViews {
	
	NSEnumerator *enumer;
	NSView *view;
	NSRect frame;
	float curHeight, expand;
	int direction;

	frame = [self frame];
	curHeight = frame.size.height;
	expand = height - curHeight;
	if (edge == AIExpandTowardMinYMask) { direction = -1; }
	else { direction = 1; }
	
	[self setFrame:NSMakeRect(frame.origin.x, frame.origin.y - (edge == AIExpandTowardMinYMask ? expand : 0), frame.size.width, frame.size.height + expand)];
	
	// move any views that have been requested to be moved
	if (moveViews) {
		enumer = [moveViews objectEnumerator];
		while (view = [enumer nextObject]) {
			NSRect viewFrame = [view frame];
			[view setFrame:NSMakeRect(viewFrame.origin.x, viewFrame.origin.y + direction * expand, viewFrame.size.width, viewFrame.size.height)];
		}		
	}
	
	// shrink any views that have been requested to be moved
	if (shrinkViews) {
		enumer = [shrinkViews objectEnumerator];
		while (view = [enumer nextObject]) {
			NSRect viewFrame = [view frame];
			[view setFrame:NSMakeRect(viewFrame.origin.x, viewFrame.origin.y + (edge == AIExpandTowardMinYMask ? expand : 0), viewFrame.size.width, viewFrame.size.height - expand)];
		}		
	}
	
	return expand;
}

- (float)resizeViewToWidth:(float)width
			  expandToward:(unsigned)edge
				 moveViews:(NSArray *)moveViews
			   shrinkViews:(NSArray *)shrinkViews {
	
	NSEnumerator *enumer;
	NSView *view;
	NSRect frame;
	float curWidth, expand;
	int direction;
	
	frame = [self frame];
	curWidth = frame.size.width;
	expand = width - curWidth;
	if (edge == AIExpandTowardMinXMask) { direction = -1; }
	else { direction = 1; }
	
	[self setFrame:NSMakeRect(frame.origin.x - (edge == AIExpandTowardMinXMask ? expand : 0), frame.origin.y, frame.size.width + expand, frame.size.height)];

	// move any views that have been requested to be moved
	if (moveViews) {
		enumer = [moveViews objectEnumerator];
		while (view = [enumer nextObject]) {
			NSRect viewFrame = [view frame];
			[view setFrame:NSMakeRect(viewFrame.origin.x + direction * expand, viewFrame.origin.y, viewFrame.size.width, viewFrame.size.height)];
		}		
	}

	// shrink any views that have been requested to be moved
	if (shrinkViews) {
		enumer = [shrinkViews objectEnumerator];
		while (view = [enumer nextObject]) {
			NSRect viewFrame = [view frame];
			[view setFrame:NSMakeRect(viewFrame.origin.x + (edge == AIExpandTowardMinXMask ? expand : 0), viewFrame.origin.y, viewFrame.size.width - expand, viewFrame.size.height)];
		}		
	}
	
	return expand;
}

- (NSSize)resizeViewToSize:(NSSize)newSize
			  expandToward:(unsigned int)expandingMask
				 moveViews:(NSArray *)moveViews
			   shrinkViews:(NSArray *)shrinkViews {
	
	NSRect frame;
	NSEnumerator *enumer;
	NSView *view;
	NSSize origSize, expand;
	int xDirection, yDirection;
	
	frame = [self frame];
	origSize = frame.size;
	expand = NSMakeSize(newSize.width - origSize.width, newSize.height - origSize.height);
	
	if (expandingMask & AIExpandTowardMinXMask) { xDirection = -1; }
	else { xDirection = 1; }
	if (expandingMask & AIExpandTowardMinYMask) { yDirection = -1; }
	else { yDirection = 1; }
	
	[self setFrame:NSMakeRect(frame.origin.x - (expandingMask & AIExpandTowardMinXMask ? expand.width : 0),
							  frame.origin.y - (expandingMask & AIExpandTowardMinYMask ? expand.height : 0),
							  frame.size.width + expand.width,
							  frame.size.height + expand.height)];
	
	// move any views that have been requested to be moved
	if (moveViews) {
		enumer = [moveViews objectEnumerator];
		while (view = [enumer nextObject]) {
			NSRect viewFrame = [view frame];
			[view setFrame:NSMakeRect(viewFrame.origin.x + xDirection * expand.width,
									  viewFrame.origin.y + yDirection * expand.height,
									  viewFrame.size.width,
									  viewFrame.size.height)];
		}		
	}
	
	// shrink any views that have been requested to be moved
	if (shrinkViews) {
		enumer = [shrinkViews objectEnumerator];
		while (view = [enumer nextObject]) {
			NSRect viewFrame = [view frame];
			[view setFrame:NSMakeRect(viewFrame.origin.x + (expandingMask & AIExpandTowardMinXMask ? expand.width : 0),
									  viewFrame.origin.y + (expandingMask & AIExpandTowardMinYMask ? expand.height : 0),
									  viewFrame.size.width - expand.width,
									  viewFrame.size.height - expand.height)];
		}		
	}
	
	[[self superview] setNeedsDisplay:YES];
	return expand;	
}

@end

@implementation NSControl (AIViewAdditions)

- (NSSize)sizeToFitWithPadding:(NSSize)padding
				  expandToward:(unsigned)edge
					 moveViews:(NSArray *)moveViews
				   shrinkViews:(NSArray *)shrinkViews {
	
	NSEnumerator *enumer;
	NSView *view;
	NSSize origSize, expand;
	int xDirection, yDirection;
	
	origSize = [self frame].size;
	[self sizeToFit];
	
	NSRect newFrame = [self frame];
	newFrame.size.width = [self frame].size.width + padding.width * 2;
	newFrame.size.height = [self frame].size.height + padding.height * 2;
	// calculate the amount that the frame is expanded from the original
	expand = NSMakeSize(newFrame.size.width - origSize.width, newFrame.size.height - origSize.height);
	// move the origin of the frame based on the expanding mask
	if ((edge & AIExpandTowardMinXMask) && (edge & AIExpandTowardMaxXMask)) { newFrame.origin.x -= expand.width / 2; }
	else if (edge & AIExpandTowardMinXMask) { newFrame.origin.x -= expand.width; }
	if ((edge & AIExpandTowardMinYMask) && (edge & AIExpandTowardMaxYMask)) { newFrame.origin.y -= expand.height / 2; }
	else if (edge & AIExpandTowardMinYMask) { newFrame.origin.y -= expand.height; }
	
	[self setFrame:newFrame];

	if (edge & AIExpandTowardMinXMask) { xDirection = -1; }
	else { xDirection = 1; }
	if (edge & AIExpandTowardMinYMask) { yDirection = -1; }
	else { yDirection = 1; }
		
	// move any views that have been requested to be moved
	if (moveViews) {
		enumer = [moveViews objectEnumerator];
		while (view = [enumer nextObject]) {
			NSRect viewFrame = [view frame];
			[view setFrame:NSMakeRect(viewFrame.origin.x + xDirection * expand.width,
									  viewFrame.origin.y + yDirection * expand.height,
									  viewFrame.size.width,
									  viewFrame.size.height)];
		}		
	}
	
	// shrink any views that have been requested to be moved
	if (shrinkViews) {
		enumer = [shrinkViews objectEnumerator];
		while (view = [enumer nextObject]) {
			NSRect viewFrame = [view frame];
			[view setFrame:NSMakeRect(viewFrame.origin.x + (edge & AIExpandTowardMinXMask ? expand.width : 0),
									  viewFrame.origin.y + (edge & AIExpandTowardMinYMask ? expand.height : 0),
									  viewFrame.size.width - expand.width,
									  viewFrame.size.height - expand.height)];
		}		
	}
	
	[[self superview] setNeedsDisplay:YES];
	return expand;	
}

@end

@implementation NSTextField (AIViewAdditions)

- (int)heightForText {
	return [[self cell] cellSizeForBounds:NSMakeRect(0, 0, [self frame].size.width, FLT_MAX)].height;
}

@end