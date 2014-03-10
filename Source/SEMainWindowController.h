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
#import "SEAutosave.h"
#import "SEControllerObserver.h"

typedef enum _SESearchFieldLimitingType {
	SESearchFieldNoLimit,
	SESearchFieldArtistLimit,
	SESearchFieldAlbumLimit,
	SESearchFieldComposterLimit,
	SESearchFieldSongLimit
} SESearchFieldLimitingType;

@protocol
	SEPlaylist,
	SEContentController;
@class
	SESplitViewHandleHelper,
	SEViewController,
	SESourceListViewController,
	SECopyProgressViewController,
	SEVisualViewController,
	SEEmptySelectionViewController;

@interface SEMainWindowController : SEWindowController <SEAutosave, SEControllerObserver> {
	
	IBOutlet NSView *standardView;
	IBOutlet SEEmptySelectionViewController *noIPodsView;
	
	IBOutlet NSView *rightView;
	IBOutlet NSView *leftView;
	IBOutlet NSView *leftBottomView;
	
	SEViewController <SEAutosave, SEControllerObserver, SEContentController> *rightViewController;
	SESourceListViewController <SEAutosave, SEControllerObserver> *sourceListViewController;
	SECopyProgressViewController <SEControllerObserver> *copyProgressViewController;
	
	id <SEPlaylist> selectedPlaylist;
	
	IBOutlet FSSplitView *splitView;
	IBOutlet SESplitViewHandleHelper *handleHelper;
	NSToolbar *toolbar;
	NSSearchField *searchField;
	NSString *searchWords;
	SESearchFieldLimitingType searchLimit;
		
	NSArray *visibleTableColumns;
	NSArray *availableTableColumns;
}

- (void)eject:(id)sender;
- (BOOL)canEject;

- (void)copy:(id)sender;
- (BOOL)canCopy;

- (void)search:(NSString *)words limitedTo:(SESearchFieldLimitingType)limited;
- (void)filterLibraries:(NSSet *)libraries;

- (NSArray *)visibleTableColumns;
- (NSArray *)availableTableColumns;
- (void)toggleTableColumnVisibility:(NSTableColumn *)column; // column must be in the availableTableColumns array

- (id <SEPlaylist>)selectedPlaylist;
- (id <SEContentController>)contentController;

@end
