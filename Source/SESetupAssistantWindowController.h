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

#import "SEWindowController.h"

@class SECopyLocationViewController;
@interface SESetupAssistantWindowController : SEWindowController {
	id delegate;
	SEL didEndSelector;
	SEL didDismissSelector;
	BOOL releaseWhenComplete;
	int selectedIndex;
	BOOL copyLocationSet;
			
	IBOutlet NSButton *cancelButton;
	IBOutlet NSButton *goBackButton;
	IBOutlet NSButton *continueButton;
	
	IBOutlet FSTransparentBackgroundImageView *backgroundView;
	IBOutlet NSTabView *tabView;
	
	IBOutlet NSTextView *licenseText;
	IBOutlet NSView *copyLocationView;
	IBOutlet SECopyLocationViewController *copyLocationViewController;
	IBOutlet NSTextView *setupText;
}

+ (void)runSetupAssistantWithDelegate:(id)delegate
					   didEndSelector:(SEL)didEndSelector
				   didDismissSelector:(SEL)didDismissSelector;


- (IBAction)continueClick:(id)sender;
- (IBAction)goBackClick:(id)sender;
- (IBAction)cancelClick:(id)sender;

- (IBAction)moreInformationClick:(id)sender;

@end
