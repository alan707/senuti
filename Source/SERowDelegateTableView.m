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

#import "SERowDelegateTableView.h"

@interface NSTableView (Undocumented)
- (id)_highlightColorForCell:(NSCell *)cell;
@end

@implementation SERowDelegateTableView

//Draw alternating colors
- (void)drawRow:(int)row clipRect:(NSRect)rect {
	
	NSColor *color = [[self delegate] tableView:self backgroundColorForRow:row selected:[self isRowSelected:row]];
	if (color) {
		[color set];
		[NSBezierPath fillRect:[self rectOfRow:row]];
	}
	
    [super drawRow:row clipRect:rect];
}

- (id)_highlightColorForCell:(NSCell *)cell {
	NSColor *color = [[self delegate] tableView:self highlightColorForCell:cell];
	if (color) {
		return color;
	} else {
		return [super _highlightColorForCell:cell];
	}
}


@end

@implementation NSObject (SERowDelegateTableView)

- (NSColor *)tableView:(NSTableView *)tableView highlightColorForCell:(NSCell *)cell {
	return nil;
}

- (NSColor *)tableView:(NSTableView *)tableView backgroundColorForRow:(int)row selected:(BOOL)selected {
	return nil;
}

@end