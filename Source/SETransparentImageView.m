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

#import "SETransparentImageView.h"
#define GRAY_COLOR 0.64705882

@interface SETransparentImageCell : NSImageCell
@end

@implementation SETransparentImageView

+ (void)initialize {
	[self setCellClass:[SETransparentImageCell class]];
}

- (void)awakeFromNib {
	NSImageCell *cell = [[[SETransparentImageCell alloc] initImageCell:[self image]] autorelease];
	[self setCell:cell];
}

- (void)setImage:(NSImage *)anImage {
	if (image != anImage) {
		[image release];
		image = [anImage retain];
		[[self cell] setImage:image];
	}
}

- (NSImage *)image {
	return image;
}

@end

@implementation SETransparentImageCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	[NSGraphicsContext saveGraphicsState];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	
	[[self image] drawRoundedInRect:cellFrame
							 atSize:cellFrame.size
						   position:IMAGE_POSITION_LEFT
						   fraction:0.65
							 radius:3];
				
	
	[NSGraphicsContext restoreGraphicsState];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end