//
//  AIGradientCell.h
//  Adium
//
//  Created by Chris Serino on Wed Jan 28 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

/*
 * @class AIGradientCell
 * @brief An <tt>NSCell</tt> which can draw its highlight as a gradient
 *
 * This <tt>NSCell</tt> can draw its highlight as a gradient across the selectedControlColor. It can also be set to ignore focus for purposes of highlight drawing.
 */
@interface AIGradientCell : NSCell {
	BOOL			drawsGradient;
	BOOL			ignoresFocus;
}

/*
 * @brief Set if the highlight should be drawn as a gradient
 *
 * Set if the highlight should be drawn as a gradient across the selectedControlColor. Defaults to NO.
 * @param inDrawsGradient YES if the highlight should be drawn as a gradient
 */
- (void)setDrawsGradientHighlight:(BOOL)inDrawsGradient;

/*
 * @brief Returns if the highlight is drawn as a gradient
 *
 * Returns if the highlight is drawn as a gradient
 * @return YES if the highlight is drawn as a gradient
 */
- (BOOL)drawsGradientHighlight;

/*
 * @brief Set if the cell should ignore focus for purposes of highlight drawing.
 *
 * Set if the cell should ignore focus for purposes of highlight drawing.  If it ignores focus, it will look the same regardless of whether it has focus or not. The default is NO.
 * @param inIgnoresFocus YES if focus is ignored.
 */
- (void)setIgnoresFocus:(BOOL)inIgnoresFocus;
- (BOOL)ignoresFocus;

@end
