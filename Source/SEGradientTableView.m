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

#import "SEGradientTableView.h"

@implementation SEGradientTableView
// NSTableView

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
	
	NSIndexSet *selectedRows = [self selectedRowIndexes];
	if ([selectedRows count] == 0) { return; }

	[self lockFocus];

	AIGradient *gradient;
	NSColor *start;
	NSColor *finish;
	unsigned int *buffer;
	BOOL selected;
	int i;
	
	selected = ([[self window] firstResponder] == self) && [[self window] isMainWindow] && [[self window] isKeyWindow];
	if (selected) {
		start = [NSColor colorWithCalibratedRed:0.42745098 green:0.6 blue:0.90196078 alpha:1];
		finish = [NSColor colorWithCalibratedRed:0.29019608 green:0.50196078 blue:0.87843137 alpha:1];
	} else {
		start = [NSColor colorWithCalibratedRed:0.6745098 green:0.72941176 blue:0.81176471 alpha:1];
		finish = [NSColor colorWithCalibratedRed:0.59607843 green:0.66666667 blue:0.76862745 alpha:1];
	}
	
	gradient = [AIGradient gradientWithFirstColor:start secondColor:finish direction:AIVertical];
	buffer = malloc(sizeof(unsigned int) * [selectedRows count]);

	[selectedRows getIndexes:buffer maxCount:[selectedRows count] inIndexRange:nil];
	for (i = 0; i < [selectedRows count]; i++) {
		int row = buffer[i];

		NSRect drawingRect = [self rectOfRow:row];
		if ([self numberOfColumns]) {
			NSRect cellFrame = [self frameOfCellAtColumn:0 row:row];
			drawingRect.origin.y = cellFrame.origin.y;
			drawingRect.size.height = cellFrame.size.height;
		}
		// draw
		if (!NSIsEmptyRect(drawingRect)) { [gradient drawInRect:drawingRect]; }
	}

	free(buffer);

	[self unlockFocus];

}

// NSTableView (private)

- (id)_highlightColorForCell:(NSCell *)cell {
	return nil;
}

@end
