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

#import "FSEventTableView.h"
#import "FSEventWindow.h"

@interface FSEventTableView (PRIVATE)
- (void)resetCursorRects;
- (void)exitPreviousCell;
@end

@implementation FSEventTableView

- (void)configureTracking {
	trackingTag = -1;
	lastMouseRow = -1;
	lastMouseCol = -1;
	[self resetCursorRects];			
}

- (id)initWithFrame:(NSRect)inFrame {
	if ((self = [super initWithFrame:inFrame])) {
		[self configureTracking];
	}
	return self;
}

- (void)awakeFromNib {
	if ([[FSEventTableView superclass] instancesRespondToSelector:@selector(awakeFromNib)]) {
        [super awakeFromNib];
	}
	[self configureTracking];
}

- (void)dealloc {
	if (trackingTag != -1) {
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
	}	
	[super dealloc];
}

- (BOOL)trackMouseEvents {
	return trackMouseEvents;
}

- (void)setTrackMouseEvents:(BOOL)flag {
	trackMouseEvents = flag;
	[self resetCursorRects];
}


#pragma mark tracking rects
// ----------------------------------------------------------------------------------------------------
// tracking rects
// ----------------------------------------------------------------------------------------------------

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
	if (trackingTag != -1) {
		// remove old tracking rects when we change superviews
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
		[[self window] setAcceptsMouseMovedEvents:previousState];
		[(FSEventWindow *)[self window] removeMouseMovedResponder:self];
	}
	
	[super viewWillMoveToSuperview:newSuperview];
}

- (void)viewDidMoveToSuperview {
	[super viewDidMoveToSuperview];
	[self resetCursorRects];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
	if (trackingTag != -1) {
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
		[[self window] setAcceptsMouseMovedEvents:previousState];
		[(FSEventWindow *)[self window] removeMouseMovedResponder:self];
	}
	
	[super viewWillMoveToWindow:newWindow];
}

- (void)viewDidMoveToWindow {
	[super viewDidMoveToWindow];
	[self resetCursorRects];
}

- (void)frameDidChange:(NSNotification *)inNotification {
	[self resetCursorRects];
}

//Reset our cursor tracking
- (void)resetCursorRects
{
	//Stop any existing tracking
	if (trackingTag != -1) {
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
		[[self window] setAcceptsMouseMovedEvents:previousState];
		[(FSEventWindow *)[self window] removeMouseMovedResponder:self];
	}
	
	//Add a tracking rect if our superview and window are ready
	if (trackMouseEvents && [self superview] && [self window]) {		
		if (![[self window] isKindOfClass:[FSEventWindow class]]) {
			[NSException raise:@"Invalid Use" format:@"FSEventTable must be used on a window that derives from FSEventWindow"];
		}
		
		NSRect trackingRect = [self bounds];
		NSPoint	mouseLocation = [self convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil];
		BOOL mouseInside = [self mouse:mouseLocation inRect:trackingRect];
		
		trackingTag = [self addTrackingRect:trackingRect owner:self userData:nil assumeInside:mouseInside];
		if (mouseInside) { [self mouseEntered:nil]; }
	}
}

- (void)mouseEntered:(NSEvent *)theEvent {
	previousState = [[self window] acceptsMouseMovedEvents];
	[[self window] setAcceptsMouseMovedEvents:YES];
	[(FSEventWindow *)[self window] addMouseMovedResponder:self];
	[super mouseEntered:theEvent];
}


- (void)mouseExited:(NSEvent *)theEvent {
	[[self window] setAcceptsMouseMovedEvents:previousState];
	[(FSEventWindow *)[self window] removeMouseMovedResponder:self];
	[self mouseMoved:theEvent]; // easier to clean up... row/col should be invalid
	[super mouseExited:theEvent];
}

- (void)exitPreviousCell {
	if (lastMouseRow != -1 && lastMouseCol != -1) {
		NSTableColumn *column = [[self tableColumns] objectAtIndex:lastMouseCol];
		NSCell *cell = [column dataCell];
		[[self delegate] tableView:self willDisplayCell:cell forTableColumn:column row:lastMouseRow];
		// check for invalidity of cell
		NSRect cellFrame = [self frameOfCellAtColumn:lastMouseCol row:lastMouseRow];
		if ([cell mouseExitedInvalidatesForFrame:cellFrame]) {
			[self setNeedsDisplayInRect:cellFrame];
		}
		lastMouseRow = -1;
		lastMouseCol = -1;
	}
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSEvent *currentEvent = theEvent;
	NSCell *cell;

	NSPoint point = [self convertPoint:[currentEvent locationInWindow] fromView:[[self window] contentView]];		
	int col = [self columnAtPoint:point];
	int row = [self rowAtPoint:point];
	NSRect cellFrame = [self frameOfCellAtColumn:col row:row];

	if (row >= 0 && col >= 0) {
		NSTableColumn *column = [[self tableColumns] objectAtIndex:col];
		cell = [column dataCell];
		
		do {
			NSEventType type = [currentEvent type];
			point = [self convertPoint:[currentEvent locationInWindow] fromView:[[self window] contentView]];		
			BOOL redraw = FALSE;
			BOOL finished = FALSE;
			
			// update the cell according to the delegate
			[[self delegate] tableView:self willDisplayCell:cell forTableColumn:column row:row];

			if (type == NSLeftMouseDown) {
				finished = ![cell trackMouseAtPoint:point cellFrame:cellFrame controlView:self];
				redraw = !finished;
			} else if (type == NSLeftMouseDragged) {
				finished = ![cell continueTrackingMouseAtPoint:point cellFrame:cellFrame controlView:self];
				redraw = !finished;
			} else if (type == NSLeftMouseUp) {
				redraw = [cell mouseUpAtPoint:point invalidatesForFrame:cellFrame controlView:self];
				finished = TRUE;
			} else {
				[NSException raise:@"Invalid Event" format:@"Next event not handled because an unexpected event type was retrieved."];
			}
			
			if (redraw) {
				[self setNeedsDisplayInRect:cellFrame];
			}
			
			if (finished) { break; }
		} while ((currentEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask) untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]));
	}

	// if no events were processed, call the table view implemenation
	if (currentEvent == theEvent) { [super mouseDown:theEvent]; }
}

- (void)mouseMoved:(NSEvent *)theEvent {
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:[[self window] contentView]];
	int col = [self columnAtPoint:point];
	int row = [self rowAtPoint:point];
	
	BOOL redraw = FALSE;
	BOOL cellChange = (lastMouseRow != row || lastMouseCol != col);
	if (cellChange) { [self exitPreviousCell]; }
	
	if (row >= 0 && col >= 0) {
		NSTableColumn *column = [[self tableColumns] objectAtIndex:col];
		NSCell *cell = [column dataCell];
		NSRect cellFrame = [self frameOfCellAtColumn:col row:row];

		// update the cell according to the delegate
		[[self delegate] tableView:self willDisplayCell:cell forTableColumn:column row:row];
		
		// process mouse entered if needed
		if (cellChange) { redraw = [cell mouseEnteredInvalidatesForFrame:cellFrame] || redraw; }
		
		// process mouse move
		redraw = [cell mouseMoveToPoint:point invalidatesForFrame:cellFrame] || redraw;
		
		if (redraw) {
			[self displayRect:cellFrame];
		}
		
		lastMouseRow = row;
		lastMouseCol = col;	
	}
	// since we're not registered as the first responder,
	// calling super would cause an infinite loop to occur
}

@end

@implementation NSCell (FSEventTable)
- (BOOL)mouseEnteredInvalidatesForFrame:(NSRect)cellFrame { return NO; }
- (BOOL)mouseExitedInvalidatesForFrame:(NSRect)cellFrame { return NO; }
- (BOOL)mouseMoveToPoint:(NSPoint)point invalidatesForFrame:(NSRect)cellFrame { return NO; }
- (BOOL)mouseUpAtPoint:(NSPoint)point invalidatesForFrame:(NSRect)cellFrame controlView:(NSControl *)controlView { return NO; }
- (BOOL)trackMouseAtPoint:(NSPoint)point cellFrame:(NSRect)cellFrame controlView:(NSControl *)controlView { return NO; }
- (BOOL)continueTrackingMouseAtPoint:(NSPoint)point cellFrame:(NSRect)cellFrame controlView:(NSControl *)controlView { return NO; }
@end
