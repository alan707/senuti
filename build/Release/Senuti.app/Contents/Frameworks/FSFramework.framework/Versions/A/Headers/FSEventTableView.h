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

/* Must be used in an FSEventWindow */

@interface FSEventTableView : NSTableView {
	NSTrackingRectTag trackingTag;
	BOOL previousState;
	BOOL trackMouseEvents;
	int lastMouseRow;
	int lastMouseCol;
}

- (BOOL)trackMouseEvents;
- (void)setTrackMouseEvents:(BOOL)flag;

@end

@interface NSCell (FSEventTable)
- (BOOL)mouseEnteredInvalidatesForFrame:(NSRect)cellFrame;
- (BOOL)mouseExitedInvalidatesForFrame:(NSRect)cellFrame;
- (BOOL)mouseMoveToPoint:(NSPoint)point invalidatesForFrame:(NSRect)cellFrame;
- (BOOL)mouseUpAtPoint:(NSPoint)point invalidatesForFrame:(NSRect)cellFrame controlView:(NSControl *)controlView;
- (BOOL)trackMouseAtPoint:(NSPoint)point cellFrame:(NSRect)cellFrame controlView:(NSControl *)controlView; // invalidate implied when return value is true
- (BOOL)continueTrackingMouseAtPoint:(NSPoint)point cellFrame:(NSRect)cellFrame controlView:(NSControl *)controlView;  // invalidate implied when return value is true
@end