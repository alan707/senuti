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

#import "FSCalendarWindowController.h"

@interface FSCalendarWindowController (PRIVATE)
- (void)checkEvent:(NSEvent *)event;
@end

@implementation FSCalendarWindowController

+ (NSString *)nibName {
	return @"CalendarWindow";
}

- (void)awakeFromNib {
	[[self window] setAlphaValue:.90];
	[datePicker setTarget:self];
	[datePicker setAction:@selector(updateValue:)];
}

- (void)runForDate:(NSDate *)date
			target:(id)t
			action:(SEL)a {
	target = t;
	action = a;
	[datePicker setDateValue:date];
	[self showWindow:nil];
	[self checkEvent:[[self window] nextEventMatchingMask:NSAnyEventMask]];
}

- (void)updateValue:(id)sender {
	if ([[self window] isVisible]) {
		[target performSelector:action withObject:[datePicker dateValue]];
		[self closeWindow:nil];
	}
}

- (void)checkEvent:(NSEvent *)event {
	NSEventType type = [event type];
	if ((type == NSLeftMouseDown || type == NSRightMouseDown) && [event window] != [self window]) {
		[self closeWindow:nil];
	} else {
		[NSApp sendEvent:event];
		[self checkEvent:[[self window] nextEventMatchingMask:NSAnyEventMask]];
	}
}

@end
