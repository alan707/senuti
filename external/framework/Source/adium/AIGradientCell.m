//
//  AIGradientCell.m
//  Adium
//
//  Created by Chris Serino on Wed Jan 28 2004.
//

#import "AIGradientCell.h"
#import "AIGradient.h"

@interface AIGradientCell (PRIVATE)
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
@end

@implementation AIGradientCell

- (id)init
{
	if ((self = [super init])) {
		drawsGradient = NO;
		ignoresFocus = NO;
	}

	return self;
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	[newCell setDrawsGradientHighlight:drawsGradient];
	[newCell setIgnoresFocus:ignoresFocus];

	return newCell;
}

//Draw Gradient
- (void)setDrawsGradientHighlight:(BOOL)inDrawsGradient{
	drawsGradient = inDrawsGradient;
}
- (BOOL)drawsGradientHighlight{
	return drawsGradient;
}

//Ignore focus (Draw as active regardless of focus)
- (void)setIgnoresFocus:(BOOL)inIgnoresFocus{
	ignoresFocus = inIgnoresFocus;
}
- (BOOL)ignoresFocus{
	return ignoresFocus;
}

//Draw with the selected-control colours.
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ([self drawsGradientHighlight]) {
		//Draw the gradient
		AIGradient *gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
		[gradient drawInRect:cellFrame];
	
		//Draw a line at the light side, to make it look a lot cleaner
		cellFrame.size.height = 1;
		[[NSColor alternateSelectedControlColor] set];
		NSRectFillUsingOperation(cellFrame,NSCompositeSourceOver);
		
	} else {
		//Draw the regular selection, ignoring focus if desired
		if (ignoresFocus) {
			[[NSColor alternateSelectedControlColor] set];
			NSRectFillUsingOperation(cellFrame,NSCompositeSourceOver);
		} else {
			[(id)super _drawHighlightWithFrame:cellFrame inView:controlView]; 
		}
	}
	
}

@end
