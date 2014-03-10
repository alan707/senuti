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

#import "FSControlledView.h"
#import "FSViewController.h"

@implementation FSControlledView

- (void)dealloc {
	FSDLog(@"");
	[super dealloc];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
	if (newWindow) {
		[[self viewController] viewWillActivate];
	} else {
		[[self viewController] viewWillInactivate];		
	}
}

- (void)viewDidMoveToWindow {
	if ([self window]) {
		[[self viewController] viewDidActivate];
	} else {
		[[self viewController] viewDidInactivate];		
	}
}

- (FSViewController *)viewController {
	return viewController;
}

- (void)setViewController:(FSViewController *)newController {
	viewController = newController;
}


@end
