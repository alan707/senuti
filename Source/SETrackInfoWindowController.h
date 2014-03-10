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
#import "SEControllerObserver.h"

@class SETransparentImageView, SEMultiImageView;
@interface SETrackInfoWindowController : SEWindowController <SEControllerObserver> {
	IBOutlet SETransparentImageView *image;
	IBOutlet NSTextField *title;
	IBOutlet NSTextField *artist;
	IBOutlet NSTextField *album;
	IBOutlet NSTextField *genre;
	IBOutlet NSTextField *year;
	IBOutlet NSTextField *length;
	IBOutlet NSTextField *start;
	IBOutlet NSTextField *end;
	IBOutlet NSTextField *size;
	IBOutlet NSTextField *type;
	IBOutlet NSTextField *bitRate;
	IBOutlet NSTextField *playCount;
	IBOutlet NSTextField *comment;
	IBOutlet NSTextField *location;
	IBOutlet NSTextField *disc;
	IBOutlet NSTextField *trackNumber;
	IBOutlet NSTextField *created;
	IBOutlet NSTextField *lastPlayed;
	IBOutlet NSTextField *lastModified;
	IBOutlet SEMultiImageView *rating;
	IBOutlet NSTabView *tabView;
	IBOutlet NSTextField *invalidTextField;
}

@end
