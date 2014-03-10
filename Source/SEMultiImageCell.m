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

#import "SEMultiImageCell.h"

#define PADDING 2

@implementation SEMultiImageCell

- (id)copyWithZone:(NSZone *)zone {
	SEMultiImageCell *newCell = [super copyWithZone:zone];

	newCell->image = nil;
	[newCell setImage:image];

	return newCell;
}

- (void)deallc {
	[image release];
	[super dealloc];
}

- (NSImage *)image {
	return image;
}

- (void)setImage:(NSImage *)img {
	if (img != image) {
		[image release];
		image = [img retain];
	}
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	int total = [[self objectValue] intValue];
	int counter;
	NSRect drawFrame = cellFrame;

	[image setFlipped:[controlView isFlipped]];
	
	[NSGraphicsContext saveGraphicsState];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	for (counter = 0; counter < total; counter++) {
		if (drawFrame.origin.x + [image size].width > cellFrame.origin.x + cellFrame.size.width) { break; }
		[image drawInRect:drawFrame
				   atSize:[image size]
				 position:IMAGE_POSITION_LEFT
				 fraction:1];
		drawFrame.origin.x += [image size].width + PADDING;
	}
		
	[NSGraphicsContext restoreGraphicsState];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
