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

#import "FSQuickChangeDateCell.h"
#import "AIImageAdditions.h"
#import "FSCalendarWindowController.h"

static FSCalendarWindowController *singleController = nil;

@interface FSQuickChangeDateCell (PRIVATE)
- (void)_quickChangeDateCellInitialize;
- (FSCalendarWindowController *)controller;
- (void)showDatePanel:(id)sender;
@end

@implementation FSQuickChangeDateCell

- (id)init {
	if ((self = [super init])) {
		[self _quickChangeDateCellInitialize];
	}
	return self;
}

- (void)awakeFromNib {
	[self _quickChangeDateCellInitialize];
}

- (void)_quickChangeDateCellInitialize {
	[self setButtonImage:[NSImage imageNamed:@"quick_change" forClass:[self class]]];
	[self setInactiveOpacity:0.1];
}

- (void)buttonClickAtPoint:(NSPoint)point inFrame:(NSRect)cellFrame controlView:(NSControl *)cv {
	controlView = cv;
	if ([cv isKindOfClass:[NSTableView class]]) {
		col = [(NSTableView *)cv columnAtPoint:point];
		row = [(NSTableView *)cv rowAtPoint:point];
	}
	[self showDatePanel:nil];
	[super buttonClickAtPoint:point inFrame:cellFrame controlView:controlView];
}

- (void)showDatePanel:(id)sender {
	NSEvent *event = [NSApp currentEvent];
	NSWindow *window = [[self controller] window];
	NSPoint origin = [event locationInWindow];
	origin = [[event window] convertBaseToScreen:origin];
	origin.y -= [window frame].size.height;
	origin.x += 2;
	[window setFrameOrigin:origin];
	[[self controller] runForDate:[self objectValue] target:self action:@selector(setDate:)];
	
}

- (void)setDate:(NSDate *)date {
	if (controlView) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NSControlTextDidBeginEditingNotification
															object:controlView];
		if ([controlView isKindOfClass:[NSTableView class]]) {
			NSTableView *tableView = (NSTableView *)controlView;
			NSTableColumn *column = [[tableView tableColumns] objectAtIndex:col];
			NSDictionary *info = [column infoForBinding:@"value"];
			if (info) {
				
				NSString *path = [info objectForKey:@"NSObservedKeyPath"];
				NSArrayController *controller = [info objectForKey:@"NSObservedObject"];
				NSArray *parts = [path componentsSeparatedByString:@"."];
				
				if (![controller isKindOfClass:[NSArrayController class]]) {
					[NSException raise:@"Invalid binding" format:@"FSQuickChangeDateCell cannot handle binding setup"];
				}
				
				if ([parts count] != 2) {
					[NSException raise:@"Invalid binding" format:@"FSQuickChangeDateCell cannot handle binding setup"];
				}
				
				id objects = [controller valueForKey:[parts objectAtIndex:0]];
				id object = [objects objectAtIndex:row];
				[object setValue:date forKey:[parts objectAtIndex:1]];
				
			} else {
				[[tableView delegate] tableView:tableView setObjectValue:date forTableColumn:column row:row];
			}
		} else {
			[self setObjectValue:date];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:NSControlTextDidEndEditingNotification
															object:controlView];
	}
}

- (FSCalendarWindowController *)controller {
	if (!singleController) {
		singleController = [[FSCalendarWindowController alloc] init];
	}
	return singleController;
}

@end
