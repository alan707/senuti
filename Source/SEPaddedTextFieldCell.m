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

#import "SEPaddedTextFieldCell.h"

#define PADDING 5

@implementation SEPaddedTextFieldCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	cellFrame.origin.x += PADDING;
	cellFrame.size.width -= PADDING * 2;
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end


@implementation NSTableHeaderCell (SEPaddedTextFieldCell)

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	if ([controlView isKindOfClass:[NSTableHeaderView class]]) {
		// use a point right in the middle of where the cell's supposed
		// to be drawn to get the column
		NSPoint point = NSMakePoint(cellFrame.origin.x + cellFrame.size.width / 2,
									cellFrame.origin.y + cellFrame.size.height / 2);
		int columnIndex = [(NSTableHeaderView *)controlView columnAtPoint:point];
		NSTableView *tableView = [(NSTableHeaderView *)controlView tableView];
		NSArray *tableColumns = [tableView tableColumns];
		NSTableColumn *column = nil;
		
		if (columnIndex >= 0 && columnIndex < [tableColumns count]) {
			column = [tableColumns objectAtIndex:columnIndex];
		}
		
		if ([[column dataCell] isKindOfClass:[SEPaddedTextFieldCell class]]) {
			cellFrame.origin.x += PADDING;
			cellFrame.size.width -= PADDING * 2;
		}
	}
	
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
