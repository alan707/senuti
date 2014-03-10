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

#import "SEViewController.h"
#import "SEAutosave.h"
#import "SEControllerObserver.h"
#import "SEContentController.h"
#import "SELibraryController.h" // SECrossReferenceObserver
#import "SEMainWindowController.h" // SESearchFieldLimitingType

@protocol SEPlaylist;
@interface SETrackListViewController : SEViewController
	<SEAutosave, SEControllerObserver, SECrossReferenceObserver, SEContentController> {
	
	IBOutlet NSTableView *trackList;
	IBOutlet NSArrayController *tracks;
	id <SEPlaylist> playlist;
	NSArray *staticTableColumns;
	NSArray *availableTableColumns;
	NSString *autosaveName;
	
	NSPredicate *filterDevicesPredicate;
	NSPredicate *searchPredicate;
	NSArray *selectedObjects;
	NSArray *availableObjects;
	
	SEVisualViewController <SEControllerObserver> *visualViewController;
	IBOutlet NSView *bottomView;
}

- (void)setPlaylist:(id <SEPlaylist>)playlist;
- (void)search:(NSString *)words limitedTo:(SESearchFieldLimitingType)limited;
- (void)filterLibraries:(NSSet *)libraries;

- (NSArray *)visibleTableColumns;
- (NSArray *)availableTableColumns;
- (void)toggleTableColumnVisibility:(NSTableColumn *)column; // column must be in the availableTableColumns array

@end

extern NSString *SETrackPboardType;