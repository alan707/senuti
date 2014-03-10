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

#import "SEBottomToolbarView.h"
#define GRAY_COLOR 0.64705882
#define START 0.99215686
#define END 0.95294118

@implementation SEBottomToolbarView

- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		darkHeight = 12;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if ((self = [super initWithCoder:decoder])) {
		darkHeight = 12;
	}
	return self;
}

- (void)setDarkAreaHeight:(int)height {
	darkHeight = height;
}


- (void)drawRect:(NSRect)aRect {
	aRect.size.height = [self frame].size.height;
	[[NSColor colorWithCalibratedRed:0.90196078 green:0.90196078 blue:0.90196078 alpha:1] set];
	[NSBezierPath fillRect:aRect];
	
	int counter;
	aRect.size.height = 1;
	for (counter = darkHeight; counter < [self frame].size.height - 1; counter++) {
		aRect.origin.y = counter;
		[[NSColor colorWithCalibratedRed:END + (START - END) / 10 green:END + (START - END) / 10 blue:END + (START - END) / 10 alpha:1] set];
		[NSBezierPath fillRect:aRect];		
	}
	
	aRect.origin.y += 1;
	[[NSColor colorWithCalibratedRed:GRAY_COLOR green:GRAY_COLOR blue:GRAY_COLOR alpha:1] set];
	[NSBezierPath fillRect:aRect];
}

@end
