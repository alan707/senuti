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

/*
 * This code is orinally from Adium.
 * Visit http://www.adiumx.com/ for more information.
 */

#import "FSWindowController.h"

@interface FSAboutBoxController : FSWindowController {
	IBOutlet	NSPanel		*panel_licenseSheet;
	IBOutlet	NSTextView	*textView_license;
	
	IBOutlet	NSButton	*button_version;
	IBOutlet	NSButton	*button_homepage;
	IBOutlet	NSButton	*button_license;
	IBOutlet	NSTextField	*textField_name;
	IBOutlet	NSTextView	*textView_credits;

	//Version clicking
	NSMutableDictionary		*buildInfo;
	NSArray					*buildInfoKeys;
	int						numberOfBuildFieldClicks, numberOfSpaceKeyDowns;

	NSString				*homepage;

	//Scrolling
	NSTimer					*scrollTimer;
	NSTimer					*eventLoopScrollTimer;
	float					scrollLocation;
	int						maxScroll;
	float					scrollRate;
}

+ (FSAboutBoxController *)aboutBoxController;
- (void)setHomepage:(NSString *)string;
- (void)setBuildInfoDisplayKeys:(NSArray *)keys; // an array of (ordered) keys to display from the BuildInfo.plist file

- (IBAction)buildFieldClicked:(id)sender;
- (IBAction)visitHomepage:(id)sender;
- (IBAction)showLicense:(id)sender;
- (IBAction)hideLicense:(id)sender;

@end
