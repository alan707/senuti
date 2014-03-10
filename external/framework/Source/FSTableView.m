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

/*
 * This code is orinally from Adium.
 * Visit http://www.adiumx.com/ for more information.
 */

#import "FSTableView.h"

NSString *AscendingOrder = @"Ascending Order";
NSString *DescendingOrder = @"Descending Order";

@interface FSTableView (PRIVATE)
- (void)saveHiddenTableColumnsIfNeeded;
- (void)updateToSavedTableColumnsWithAutosaveName:(NSString *)name;
@end

@implementation FSTableView

- (id)init {
	return [self initWithFrame:NSMakeRect(0, 0, 200, 200)];
}

- (id)initWithFrame:(NSRect)frame {
	if (self = [super initWithFrame:frame])
	{
		hidden = [[NSMutableArray alloc] init];
		select_string = [[NSMutableString alloc] init];
	}
	return self;
}

- (void)dealloc {
	[select_string release];
	[hidden release];
	[super dealloc];
}

- (void)setAutosaveName:(NSString *)name {
	// make sure table columns are updated to what they were saved as before calling to super
	// it will be dealing with the correct columns
	
	// don't allow saving of table columns while modifying them in here
	BOOL hold = [self autosaveTableColumns];
	[self setAutosaveTableColumns:NO];
	if (name) { [self updateToSavedTableColumnsWithAutosaveName:name]; }
	
	// go back to the previous setting
	[self setAutosaveTableColumns:hold];
	[super setAutosaveName:name];
}

- (NSArray *)tableColumns {
	return [[super tableColumns] arrayByAddingObjectsFromArray:hidden];
}

- (int)numberOfColumns {
	return [super numberOfColumns] + [hidden count];
}

- (NSArray *)visibleTableColumns {
	return [super tableColumns];
}

- (int)numberOfVisibleColumns {
	return [super numberOfColumns];
}

- (void)addTableColumn:(NSTableColumn *)column {
	[self addTableColumn:column visible:YES];
}
- (void)addTableColumn:(NSTableColumn *)column visible:(BOOL)visible {
	if (visible)
	{
		[super addTableColumn:column];
	} else {
		[hidden addObject:column];
		[self saveHiddenTableColumnsIfNeeded];
	}
}
- (void)removeTableColumn:(NSTableColumn *)column {
	if ([hidden containsObject:column]) {
		[hidden removeObject:column];
		[self saveHiddenTableColumnsIfNeeded];
	} else {
		[super removeTableColumn:column];
	}
}
- (void)hideTableColumn:(NSTableColumn *)column {
	[hidden addObject:column];
	[super removeTableColumn:column];
	[self saveHiddenTableColumnsIfNeeded];
}
- (void)showTableColumn:(NSTableColumn *)column {
	if ([hidden indexOfObject:column] != NSNotFound)
	{
		[super addTableColumn:column];
		[hidden removeObject:column];
	} else {
		[[NSException exceptionWithName:@"Column Not Available" reason:@"The column you want to make visible is not part of the table view.  You must add the table column first." userInfo:nil] raise];
	}
	[self saveHiddenTableColumnsIfNeeded];
}

- (NSTableColumn *)tableColumnWithIdentifier:(id)identifier {
	int counter;
	for (counter = 0; counter < [hidden count]; counter++)
	{
		if ([[[hidden objectAtIndex:counter] identifier] isEqualTo:identifier])
		{
			return [hidden objectAtIndex:counter];
		}
	}
	
	return [super tableColumnWithIdentifier:identifier];;
}



// autosaving

- (void)saveHiddenTableColumnsIfNeeded {
	if ([self autosaveName]) {
		int counter;
		NSMutableArray *save = [[NSMutableArray alloc] init];
		for (counter = 0; counter < [hidden count]; counter++)
		{
			[save addObject:[[hidden objectAtIndex:counter] identifier]];
		}
			
		[[NSUserDefaults standardUserDefaults] setObject:save forKey:[NSString stringWithFormat:@"TableView %@ Hidden Columns", [self autosaveName]]];
		
		[save release];
	}
}

- (void)updateToSavedTableColumnsWithAutosaveName:(NSString *)name {
	// make all calls in here to super, so that columns don't try to save when we're adding and removing them
	int counter;
	for (counter = 0; counter < [hidden count]; counter++)
	{
		[self addTableColumn:[hidden objectAtIndex:counter]];
	}
	
	NSArray *cols = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"TableView %@ Hidden Columns", name]];

	for (counter = 0; counter < [cols count]; counter++)
	{
		[super removeTableColumn:[self tableColumnWithIdentifier:[cols objectAtIndex:counter]]];
	}
}

- (void)passSelectString:(NSTimer *)sender {
	[select_timer invalidate];
	select_timer = nil;

	int row = -1;
	int to_index = 0;
	int smallest_difference = -1;
	int counter;
	NSString *compare = [select_string lowercaseString];
	for (counter = 0; counter < [self numberOfRows]; counter++)
	{
		NSString *object = [[[self delegate] tableView:self compareValueForRow:counter] lowercaseString];
		if (to_index < [object length] && to_index < [compare length] + 1)
		{
			if (object && [[object substringToIndex:to_index] isEqualToString:[compare substringToIndex:to_index]])			
			{
				char one = [compare characterAtIndex:to_index];
				char two = (to_index == [object length])?' ':[object characterAtIndex:to_index];
				int difference = abs(one - two);
				if (difference == 0)
				{
					while (difference == 0)
					{
						to_index++;
						if (to_index == [compare length] || to_index == [object length] + 1) { break; } // if we have an exact match
						one = [compare characterAtIndex:to_index];
						two = (to_index == [object length])?' ':[object characterAtIndex:to_index];
						difference = abs(one - two);
					}
					smallest_difference = -1;
					row = counter;
					if (to_index == [compare length] || to_index == [object length] + 1) { break; } // if we have an exact match
				} else if (smallest_difference == -1 || difference < smallest_difference)
				{
					smallest_difference = difference;
					row = counter;
				}
			}
		}
	}
	if (row != -1) {
		[self selectRow:row byExtendingSelection:NO];
		[self scrollRowToVisible:row];
	}
	
	[select_string setString:@""];
}

- (void)keyDown:(NSEvent *)theEvent {
	NSString *str = [theEvent characters];
	char pressed = [str length]?[str characterAtIndex:0]:'\0';

	if ([self delegate] && [self selectStringOnKeyDown] &&
		([[NSCharacterSet alphanumericCharacterSet] characterIsMember:pressed] || (![[NSCharacterSet controlCharacterSet] characterIsMember:pressed])))
	{
		[select_string appendString:[theEvent charactersIgnoringModifiers]];
		[select_timer invalidate];
		select_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(passSelectString:) userInfo:nil repeats:NO];
	} else {
		[super keyDown:theEvent];
	}
}


- (void)setSelectStringOnKeyDown:(BOOL)flag {
	select = flag;
}

- (BOOL)selectStringOnKeyDown {
	return select;
}

@end

@implementation NSObject (FSTableViewDelegate)

- (NSString *)tableView:(NSTableView *)tableView compareValueForRow:(int)row {
	[[NSException exceptionWithName:@"TableView delegate exception" reason:@"TableView must respond to tableView:(NSTableView *)tableView compareValueForRow:(int)row if selectStringOnKeyDown is set to TRUE." userInfo:nil] raise];
	return nil;
}

@end