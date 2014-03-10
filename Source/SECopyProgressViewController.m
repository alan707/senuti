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

#import "SECopyProgressViewController.h"
#import "SEInterfaceController.h"
#import "SECopyController.h"

#import "SEBottomToolbarView.h"

static void *SECompletedCountChangeContext = @"SECompletedCountChangeContext";
static void *SEInProgressCountChangeContext = @"SEInProgressCountChangeContext";

@implementation SECopyProgressViewController

+ (NSString *)nibName {
	return @"CopyProgress";
}

- (id)init {
	if ((self = [super init])) {
		[[senuti copyController] addObserver:self forKeyPath:@"completed" options:0 context:SECompletedCountChangeContext];
		[[senuti copyController] addObserver:self forKeyPath:@"inProgress" options:0 context:SEInProgressCountChangeContext];
	}
	return self;
}

- (void)dealloc {
	[self removeControllerObservers];
	[super dealloc];
}

- (void)removeControllerObservers {
	[[senuti copyController] removeObserver:self forKeyPath:@"completed"];
	[[senuti copyController] removeObserver:self forKeyPath:@"inProgress"];
}

- (void)awakeFromNib {
	[backgroundView setDarkAreaHeight:0];
	[title setStringValue:@""];
}

- (IBAction)showProgressWindow:(id)sender {
	[[senuti interfaceController] showProgressWindow:nil];
}

#pragma mark observing changes
// ----------------------------------------------------------------------------------------------------
// observing changes
// ----------------------------------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SEInProgressCountChangeContext) {
		[progress setMaxValue:[[senuti copyController] inProgress]];
	} else if (context == SECompletedCountChangeContext) {
		[progress setDoubleValue:[[senuti copyController] completed]];
		[title setStringValue:[NSString stringWithStringOrNil:[[senuti copyController] nameOfATrackInProgress]]];
	}
}

@end
