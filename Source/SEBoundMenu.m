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

#import "SEBoundMenu.h"

@implementation SEBoundMenu

- (id <NSMenuItem>)insertItemWithTitle:(NSString *)title action:(SEL)selector keyEquivalent:(NSString *)keyEquiv atIndex:(int)index {
	
	NSImage *image = nil;
    if ([title isEqual: @""]) {
        NSMenuItem <NSMenuItem> *sep = [NSMenuItem separatorItem];
        [self addItem:sep];
        return sep;
	} else if ([title hasPrefix:@"::"]) {
		NSArray *components = [title componentsSeparatedByString:@"|"];
		if ([components count] == 2) {
			title = [[components objectAtIndex:0] substringFromIndex:2];
			NSString *imageName = [components objectAtIndex:1];
			image = [NSImage imageNamed:imageName];
			[image setScalesWhenResized:YES];
			[image setSize:NSMakeSize(15, 15)];
		}
	}		

	NSMenuItem *menuItem = [super insertItemWithTitle:title action:selector keyEquivalent:keyEquiv atIndex:index];
	if (image) { [menuItem setImage:image]; }
	return (id <NSMenuItem>)menuItem;
}

@end
