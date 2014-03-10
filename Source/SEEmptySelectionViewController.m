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

#import "SEEmptySelectionViewController.h"

@implementation SEEmptySelectionViewController

+ (NSString *)nibName {
	return @"EmptySelection";
}

- (void)dealloc {
	[information release];
	[super dealloc];
}

- (void)awakeFromNib {
	[imageView setBackgroundImage:[NSApp applicationIconImage]];
	[imageView setTransparentRect:[backgroundView frame]];
	[imageView setOpacity:0.45];
	[backgroundView setBackgroundColor:[NSColor whiteColor]];
	[backgroundView setDrawsBackground:TRUE];
	if (information) {
		[informationText setStringValue:information];
	}
}

- (NSString *)information {
	return information;
}

- (void)setInformation:(NSString *)info {
	if (info != information) {
		[information release];
		information = [info retain];
		if (information) {
			[informationText setStringValue:information];
		}
	}
}

@end
