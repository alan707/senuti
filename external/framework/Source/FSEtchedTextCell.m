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

/* This code is taken from Sean Patrick O'Brien's iLife Controls
 * and has been minimally modified.  It is published under an MIT
 * license, and that license holds for this file. */

#import "FSEtchedTextCell.h"

@implementation FSEtchedTextCell

-(void)setShadowColor:(NSColor *)color
{
	mShadowColor = [color retain];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(id)controlView
{
	[NSGraphicsContext saveGraphicsState]; 
	NSShadow* theShadow = [[NSShadow alloc] init]; 
	[theShadow setShadowOffset:NSMakeSize(0, -1)]; 
	[theShadow setShadowBlurRadius:0.3]; 

	[theShadow setShadowColor:mShadowColor]; 
	
	[theShadow set];

	[super drawInteriorWithFrame:cellFrame inView:controlView];
	
	[NSGraphicsContext restoreGraphicsState];
	[theShadow release]; 
}

@end
