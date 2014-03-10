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

@interface FSTableView : NSTableView {
	NSMutableArray *hidden;
	
	BOOL select;
	NSMutableString *select_string;
	NSTimer *select_timer;
}

- (void)setAutosaveName:(NSString *)name;

- (NSArray *)tableColumns;
- (int)numberOfColumns;

- (NSArray *)visibleTableColumns;
- (int)numberOfVisibleColumns;

- (void)addTableColumn:(NSTableColumn *)column visible:(BOOL)visible;
- (void)removeTableColumn:(NSTableColumn *)column;
- (void)hideTableColumn:(NSTableColumn *)column;
- (void)showTableColumn:(NSTableColumn *)column;

- (NSTableColumn *)tableColumnWithIdentifier:(id)identifier;

- (void)setSelectStringOnKeyDown:(BOOL)flag;
- (BOOL)selectStringOnKeyDown;

@end

@interface NSObject (FSTableViewDelegate)

- (NSString *)tableView:(NSTableView *)tableView compareValueForRow:(int)row;

@end