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

@interface SERegistrationWindowController : SEWindowController {
	IBOutlet NSImageView *image;
	IBOutlet NSView *registrationView;
	IBOutlet NSView *informationView;
	IBOutlet NSTextField *ownerEntry;
	IBOutlet NSTextField *numberEntry1;
	IBOutlet NSTextField *numberEntry2;
	IBOutlet NSTextField *numberEntry3;
	IBOutlet NSTextField *numberEntry4;
	IBOutlet NSTextField *numberEntry5;
	IBOutlet NSTextField *owner;
	IBOutlet NSTextField *date;
	IBOutlet NSTextField *number;
	IBOutlet NSButton *finishRegistration;
}

- (IBAction)finishRegistration:(id)sender;
- (IBAction)purchase:(id)sender;
- (IBAction)change:(id)sender;

@end
