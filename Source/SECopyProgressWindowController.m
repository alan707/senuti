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

#import "SECopyProgressWindowController.h"
#import "SECopyController.h"

#define COPYING_NAME		FSLocalizedString(@"Copying %@", nil)
#define ADDING_NAME			FSLocalizedString(@"Adding %@", nil)
#define COPYING_REMAINING	FSLocalizedString(@"%i remaining", nil)
#define ADDING_REMAINING	FSLocalizedString(@"%i remaining", nil)


static void *SECopyChangeContext = @"SECopyChangeContext";
static void *SEAddChangeContext = @"SEAddChangeContext";

@interface SECopyProgressWindowController (PRIVATE)
- (void)updateCopyName:(NSNumber *)hasRun;
- (void)updateAddName:(NSNumber *)hasRun;
@end

@implementation SECopyProgressWindowController

+ (NSString *)nibName {
	return @"CopyProgressWindow";
}

- (void)dealloc {
	[self removeControllerObservers];
	[super dealloc];
}

- (void)removeControllerObservers {
	if ([self isWindowLoaded]) {
		[[senuti copyController] removeObserver:self forKeyPath:@"copyCompleted"];
		[[senuti copyController] removeObserver:self forKeyPath:@"copyInProgress"];
		[[senuti copyController] removeObserver:self forKeyPath:@"addCompleted"];
		[[senuti copyController] removeObserver:self forKeyPath:@"addInProgress"];
	}
}

- (void)awakeFromNib {
	[background setDrawsBackground:YES];
	[background setBackgroundColor:[NSColor whiteColor]];
	
	[self updateAddName:[NSNumber numberWithBool:FALSE]];
	[self updateCopyName:[NSNumber numberWithBool:FALSE]];

	[[senuti copyController] addObserver:self forKeyPath:@"copyCompleted" options:0 context:SECopyChangeContext];
	[[senuti copyController] addObserver:self forKeyPath:@"copyInProgress" options:0 context:SECopyChangeContext];
	[[senuti copyController] addObserver:self forKeyPath:@"addCompleted" options:0 context:SEAddChangeContext];
	[[senuti copyController] addObserver:self forKeyPath:@"addInProgress" options:0 context:SEAddChangeContext];
}

- (void)updateCopyName:(NSNumber *)numFlag {
	BOOL hasRun = [numFlag boolValue];
	int inProgress = [[senuti copyController] copyInProgress];
	if (inProgress) {
		[copyingProgress setDoubleValue:[[senuti copyController] copyCompleted]];
		[copyingProgress setMaxValue:inProgress];
		[copyingName setStringValue:[NSString stringWithFormat:COPYING_NAME, [NSString stringWithStringOrNil:[[senuti copyController] nameOfCopyTrackInProgress]]]];
		[copyingRemaining setStringValue:
			[NSString stringWithFormat:COPYING_REMAINING, inProgress - [[senuti copyController] copyCompleted]]];
		[copyingProgress setHidden:FALSE];
		[copyingRemaining setHidden:FALSE];
	} else {
		if (hasRun) { [copyingName setStringValue:FSLocalizedString(@"Copying completed", nil)]; }
		else { [copyingName setStringValue:FSLocalizedString(@"Waiting to copy", nil)]; }
		if (![copyingProgress isHidden]) {
			[copyingProgress setHidden:TRUE];
			[copyingRemaining setHidden:TRUE];
			[[self window] display];
		}
	}
}

- (void)updateAddName:(NSNumber *)numFlag {
	BOOL hasRun = [numFlag boolValue];
	int inProgress = [[senuti copyController] addInProgress];
	if (inProgress) {
		[addingProgress setDoubleValue:[[senuti copyController] addCompleted]];
		[addingProgress setMaxValue:inProgress];
		[addingName setStringValue:[NSString stringWithFormat:ADDING_NAME, [NSString stringWithStringOrNil:[[senuti copyController] nameOfAddTrackInProgress]]]];
		[addingRemaining setStringValue:
			[NSString stringWithFormat:ADDING_REMAINING, inProgress - [[senuti copyController] addCompleted]]];
		[addingProgress setHidden:FALSE];
		[addingRemaining setHidden:FALSE];
	} else {
		if (hasRun) { [addingName setStringValue:FSLocalizedString(@"Adding completed", nil)]; }
		else { [addingName setStringValue:FSLocalizedString(@"Waiting to add", nil)]; }
		if (![addingProgress isHidden]) {
			[addingProgress setHidden:TRUE];
			[addingRemaining setHidden:TRUE];
			[[self window] display];
		}
	}
}

#pragma mark observing changes
// ----------------------------------------------------------------------------------------------------
// observing changes
// ----------------------------------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SECopyChangeContext) {
		[self performSelectorOnMainThread:@selector(updateCopyName:) withObject:[NSNumber numberWithBool:TRUE] waitUntilDone:NO];
	} else if (context == SEAddChangeContext) {
		[self performSelectorOnMainThread:@selector(updateAddName:) withObject:[NSNumber numberWithBool:TRUE] waitUntilDone:NO];
	}
}

@end
