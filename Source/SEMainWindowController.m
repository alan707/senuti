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

#import "SEMainWindowController.h"
#import "SEViewController.h"

#import "SECopyController.h"
#import "SETrackListViewController.h"
#import "SESourceListViewController.h"
#import "SECopyProgressViewController.h"
#import "SEEmptySelectionViewController.h"

#import "SEPlaylist.h"
#import "SESplitViewHandleHelper.h"

#define DEFAULT_SONG_TABLE_WIDTH		175
#define MIN_SOURCE_TABLE_WIDTH			100
#define MAX_SOURCE_TABLE_WIDTH			450

static NSString *SESearchItemIdentifier = @"SESearchItemIdentifier";
static NSString *SECopyItemIdentifier = @"SECopyItemIdentifier";

static void *SEVisibleTableColumnContext = @"SEVisibleTableColumnContext";
static void *SEAvailableTableColumnContext = @"SEAvailableTableColumnContext";	
static void *SESourceListSelectionTypeChangeContext = @"SESourceListSelectionTypeChangeContext";
static void *SESourceListPlaylistChangeContext = @"SESourceListPlaylistChangeContext";
static void *SECopyingStatusChangeContext = @"SECopyingStatusChangeContext";
static void *SELibrariresAvailableChangeContext = @"SELibrariresAvailableChangeContext";

@interface SEMainWindowController (PRIVATE)

- (void)updateRightViewController;

- (SEViewController <SEAutosave> *)rightViewController;
- (void)setRightViewController:(SEViewController <SEAutosave> *)controller;
- (void)setSourceListViewController:(SEViewController *)controller;
- (void)setProgressViewController:(SEViewController *)controller;
- (void)setRightViewAutosaveName:(NSString *)name;

- (void)setSelectedPlaylist:(id <SEPlaylist>)playlist;
- (void)setVisibleTableColumns:(NSArray *)columns;
- (void)setAvailableTableColumns:(NSArray *)columns;

// convienience provided for KVC
- (NSView *)contentView;
- (void)setContentView:(NSView *)view;

- (void)setRightView:(NSView *)view;
- (NSView *)rightView;

- (BOOL)canSearch;
- (IBAction)selectSearchLimit:(id)sender;
- (IBAction)performSearch:(id)sender;
- (void)updateSearchChecksInMenu:(NSMenu *)menu;
- (NSString *)searchWords;
- (void)setSearchWords:(NSString *)words;	
- (SESearchFieldLimitingType)searchLimit;
- (void)setSearchLimit:(SESearchFieldLimitingType)limit;

- (void)copySelectedTracks;

- (void)removeTableColumnObservers;
- (void)updateTableColumnsAndObservers;
- (void)updateSearchFieldEnabledness;

- (void)hideLeftBottomtView;
- (void)showLeftBottomView;
- (void)updateDisplayedView;
@end

@implementation SEMainWindowController

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"contentView", @"rightViewController", nil]
		triggerChangeNotificationsForDependentKey:@"contentController"];
}

+ (NSString *)nibName {
	return @"MainWindow";
}

- (id)init {
	if ((self = [super init])) {
		sourceListViewController = [[SESourceListViewController alloc] init];
		copyProgressViewController = [[SECopyProgressViewController alloc] init];
		searchLimit = SESearchFieldNoLimit;
	}
	return self;
}

- (void)dealloc {
	[self removeControllerObservers];
	
	[rightViewController release];
	[sourceListViewController release];
	[copyProgressViewController release];

	[toolbar release];
	[selectedPlaylist release];
	[searchField release];
	
	[visibleTableColumns release];
	[availableTableColumns release];
	
	[super dealloc];
}

- (void)removeControllerObservers {
	if ([self isWindowLoaded]) {
		[[senuti libraryController] removeObserver:self forKeyPath:@"iPodLibraries"];
		[[senuti copyController] removeObserver:self forKeyPath:@"copying"];
		[sourceListViewController removeObserver:self forKeyPath:@"selectionType"];
		[sourceListViewController removeObserver:self forKeyPath:@"selectedPlaylist"];
	}
	
	if ([rightViewController conformsToProtocol:@protocol(SEControllerObserver)]) {
		[rightViewController removeControllerObservers];
	}
	[sourceListViewController removeControllerObservers];
	[copyProgressViewController removeControllerObservers];
}

- (void)awakeFromNib {
	[[senuti libraryController] addObserver:self forKeyPath:@"iPodLibraries" options:0 context:SELibrariresAvailableChangeContext];
	[sourceListViewController addObserver:self forKeyPath:@"selectionType" options:0 context:SESourceListSelectionTypeChangeContext];
	[sourceListViewController addObserver:self forKeyPath:@"selectedPlaylist" options:0 context:SESourceListPlaylistChangeContext];
	[[senuti copyController] addObserver:self forKeyPath:@"copying" options:0 context:SECopyingStatusChangeContext];

	// create the search field
	searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(0, 0, 150, 30)];
	[searchField setTarget:self];
	[searchField setAction:@selector(performSearch:)];
	NSMenu *cellMenu;
	NSMenuItem *item;
	cellMenu = [[[NSMenu alloc] initWithTitle:@"Search Menu"] autorelease];
	item = [[[NSMenuItem alloc] initWithTitle:FSLocalizedString(@"All", nil) action:@selector(selectSearchLimit:) keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[item setTag:SESearchFieldNoLimit];		
	[cellMenu addItem:item];
	[cellMenu addItem:[NSMenuItem separatorItem]];
	item = [[[NSMenuItem alloc] initWithTitle:FSLocalizedString(@"Artist", nil) action:@selector(selectSearchLimit:) keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[item setTag:SESearchFieldArtistLimit];
	[cellMenu addItem:item];
	item = [[[NSMenuItem alloc] initWithTitle:FSLocalizedString(@"Album", nil) action:@selector(selectSearchLimit:) keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[item setTag:SESearchFieldAlbumLimit];		
	[cellMenu addItem:item];
	item = [[[NSMenuItem alloc] initWithTitle:FSLocalizedString(@"Composer", nil) action:@selector(selectSearchLimit:) keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[item setTag:SESearchFieldComposterLimit];		
	[cellMenu addItem:item];
	item = [[[NSMenuItem alloc] initWithTitle:FSLocalizedString(@"Song", nil) action:@selector(selectSearchLimit:) keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[item setTag:SESearchFieldSongLimit];		
	[cellMenu addItem:item];
	[self updateSearchChecksInMenu:cellMenu];
	[[searchField cell] setSearchMenuTemplate:cellMenu];
	
	[noIPodsView setInformation:FSLocalizedString(@"Insert an iPod to get started", nil)];
}

- (void)windowDidLoad {
	NSView *sourceListView = (NSView *)[sourceListViewController view];
	[sourceListView setFrame:NSMakeRect(0, 0, [leftView frame].size.width, [leftView frame].size.height)];
	[leftView addSubview:sourceListView];
	
	NSView *copyProgressView = [copyProgressViewController view];
	[copyProgressView setFrame:NSMakeRect(0, 0, [leftBottomView frame].size.width, [leftBottomView frame].size.height)];
	[leftBottomView addSubview:copyProgressView];
	
	[splitView setDelegate:self];
	[handleHelper setSplitView:splitView];

	// set the toolbar
	toolbar = [[NSToolbar alloc] initWithIdentifier:@"SenutiWindow"];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[toolbar setDelegate:self];
	[[self window] setToolbar:toolbar];
	
	[[self window] setDelegate:self];
	[self updateRightViewController];
	[self hideLeftBottomtView];

	if ([[senuti libraryController] hasIPods]) { [self setContentView:standardView]; }
	else { [self setContentView:[noIPodsView view]]; }
}

#pragma mark autosavename
// ----------------------------------------------------------------------------------------------------
// autosavename
// ----------------------------------------------------------------------------------------------------

- (void)setAutosaveName:(NSString *)name {
	[[self window] setFrameAutosaveName:name];
	[splitView setPositionAutosaveName:[name stringByAppendingString:@" Split View"]];
	[sourceListViewController setAutosaveName:[name stringByAppendingString:@" Source List"]];
	[self setRightViewAutosaveName:name];
}

- (NSString *)autosaveName {
	return [[self window] frameAutosaveName];
}

- (void)setRightViewAutosaveName:(NSString *)name {
	if (rightViewController && [rightViewController conformsToProtocol:@protocol(SEAutosave)]) {
		[rightViewController setAutosaveName:[name stringByAppendingString:@" Right View"]];
	}	
}

#pragma mark content
// ----------------------------------------------------------------------------------------------------
// content
// ----------------------------------------------------------------------------------------------------

- (NSView *)contentView {
	return [[self window] contentView];
}

- (void)setContentView:(NSView *)view {
	[[self window] setContentView:view];
}

- (void)setSourceListViewController:(SEViewController *)controller {
	if (controller != sourceListViewController) {
		[sourceListViewController release];
		sourceListViewController = [controller retain];
	}
}

- (void)setProgressViewController:(SEViewController *)controller {
	if (controller != copyProgressViewController) {
		[copyProgressViewController release];
		copyProgressViewController = [controller retain];
	}
}

- (void)setRightViewController:(SEViewController <SEAutosave> *)controller {
	if (rightViewController != controller) {
		// remove the observers that were added to watch for table column changes
		[self removeTableColumnObservers];

		[rightViewController release];
		rightViewController = [controller retain];
		
		// update the table columns shown for the window
		// and add ovservers to watch for when they change
		[self updateTableColumnsAndObservers];
		// update the search field
		[self updateSearchFieldEnabledness];
		// set the autosave name for it as well
		[self setRightViewAutosaveName:[self autosaveName]];		
	}
}

- (id <SEContentController>)contentController {
	if ([[self window] contentView] == standardView &&
		[rightViewController conformsToProtocol:@protocol(SEContentController)]) { return rightViewController; }
	else { return nil; }
}

- (SEViewController <SEAutosave> *)rightViewController {
	return rightViewController;
}

- (void)setRightView:(NSView *)view {
	if (rightView != view) {
		[[rightView superview] replaceSubview:rightView with:view];
		rightView = view;
	}
}

- (NSView *)rightView {
	return rightView;
}

- (void)updateRightViewController {
	Class controllerClass = nil;
	SEL selector = NULL;
	id object = nil;
	
	if ([sourceListViewController selectionType] == SESourcePlaylistSelection) {
		controllerClass = [SETrackListViewController class];
		selector =  @selector(setPlaylist:);
		object = [sourceListViewController selectedPlaylist];
	} else if ([sourceListViewController selectionType] == SESourceEmptySelection) {
		controllerClass = [SEEmptySelectionViewController class];
	} else {
		[[NSException exceptionWithName:@"InvalidObject"
								 reason:[NSString stringWithFormat:@"SEMainWindowController tried to set a type from the source list that it can't handle (description - %@)", [object description]]
							   userInfo:nil] raise];
	}
	
	if (![[self rightViewController] isKindOfClass:controllerClass]) {
		[self setRightViewController:[[[controllerClass alloc] init] autorelease]];
		[self setRightView:[[self rightViewController] view]];
	}
	
	if (selector != NULL) { [[self rightViewController] performSelector:selector withObject:object]; }
}


#pragma made available from the source list
// ----------------------------------------------------------------------------------------------------
// made available from the source list
// ----------------------------------------------------------------------------------------------------

- (id <SEPlaylist>)selectedPlaylist {
	return selectedPlaylist;
}

- (void)setSelectedPlaylist:(id <SEPlaylist>)playlist {
	if (selectedPlaylist != playlist) {
		[selectedPlaylist release];
		selectedPlaylist = [playlist retain];
	}
}


#pragma mark copying
// ----------------------------------------------------------------------------------------------------
// copying
// ----------------------------------------------------------------------------------------------------

- (BOOL)canCopy {
	return ([[self window] contentView] == standardView &&
			[rightViewController conformsToProtocol:@protocol(SEContentController)] &&
			[[rightViewController selectedObjects] count] != 0);
}

- (void)copy:(id)sender {
	[self copySelectedTracks];
}

- (void)copySelectedTracks {
	[[senuti copyController] copyTracks:[rightViewController selectedObjects] to:nil];
}


#pragma mark search
// ----------------------------------------------------------------------------------------------------
// search
// ----------------------------------------------------------------------------------------------------

- (BOOL)canSearch {
	return rightViewController && [self isWindowLoaded] &&
	[[self window] contentView] == standardView &&
	[rightViewController respondsToSelector:@selector(search:limitedTo:)];
}

- (IBAction)selectSearchLimit:(id)sender {
	[self setSearchLimit:[(NSMenuItem *)sender tag]];
	[self updateSearchChecksInMenu:[(NSMenuItem *)sender menu]];
}

- (IBAction)performSearch:(id)sender {
	[self setSearchWords:[(NSSearchField *)sender stringValue]];
}

- (void)updateSearchChecksInMenu:(NSMenu *)menu {
	NSMenuItem *item;
	NSEnumerator *itemEnumerator = [[menu itemArray] objectEnumerator];
	while (item = [itemEnumerator nextObject]) {
		[item setState:([self searchLimit] == [item tag]) ? NSOnState : NSOffState];
	}
}

- (NSString *)searchWords {
	return searchWords;
}
- (void)setSearchWords:(NSString *)words {
	if (words != searchWords) {
		[searchWords release];
		searchWords = [words retain];		
		[self search:[self searchWords] limitedTo:[self searchLimit]];
	}
}

- (SESearchFieldLimitingType)searchLimit {
	return searchLimit;
}
- (void)setSearchLimit:(SESearchFieldLimitingType)limit {
	if (searchLimit != limit) {
		searchLimit = limit;
		[self search:[self searchWords] limitedTo:[self searchLimit]];
	}
}


#pragma mark hide/show views
// ----------------------------------------------------------------------------------------------------
// hide/show views
// ----------------------------------------------------------------------------------------------------

- (void)hideLeftBottomtView {
	if (![leftBottomView isHidden]) {
		[leftBottomView setHidden:YES];
		float sizeIncrease = [leftBottomView frame].size.height;
		NSRect leftViewFrame = [leftView frame];
		[leftView setFrame:NSMakeRect(leftViewFrame.origin.x,
									  leftViewFrame.origin.y - sizeIncrease,
									  leftViewFrame.size.width,
									  leftViewFrame.size.height + sizeIncrease)];
	}
}

- (void)showLeftBottomView {
	if ([leftBottomView isHidden]) {
		[leftBottomView setHidden:NO];
		float sizeDecrease = [leftBottomView frame].size.height;
		NSRect leftViewFrame = [leftView frame];
		[leftView setFrame:NSMakeRect(leftViewFrame.origin.x,
									  leftViewFrame.origin.y + sizeDecrease,
									  leftViewFrame.size.width,
									  leftViewFrame.size.height - sizeDecrease)];
	}
}

- (void)updateDisplayedView {
	if ([self isWindowLoaded]) {
		if ([[[senuti libraryController] iPodLibraries] count]) {
			[self setContentView:standardView];
		} else {
			[self setContentView:[noIPodsView view]];
		}
		[self updateSearchFieldEnabledness];
	}
}


#pragma mark forwarded messages
// ----------------------------------------------------------------------------------------------------
// forwarded messages
// ----------------------------------------------------------------------------------------------------

- (void)search:(NSString *)words limitedTo:(SESearchFieldLimitingType)limited {
	if ([self canSearch]) {
		[(id)rightViewController search:words limitedTo:limited];
	}
}

- (void)filterLibraries:(NSSet *)libraries {
	if (rightViewController &&
		[rightViewController respondsToSelector:@selector(filterLibraries:)]) {
		[(id)rightViewController filterLibraries:libraries];
	}

}

- (void)eject:(id)sender {
	if (sourceListViewController &&
		[sourceListViewController respondsToSelector:@selector(eject:)]) {
		[sourceListViewController eject:nil];
	}	
}

- (BOOL)canEject {
	return (sourceListViewController &&
			[sourceListViewController respondsToSelector:@selector(canEject)] &&
			[sourceListViewController canEject]);
}

#pragma mark table columns
// ----------------------------------------------------------------------------------------------------
// table columns
// ----------------------------------------------------------------------------------------------------

- (NSArray *)visibleTableColumns {
	return visibleTableColumns;
}

- (void)setVisibleTableColumns:(NSArray *)columns {
	if (columns != visibleTableColumns) {
		[visibleTableColumns release];
		visibleTableColumns = [columns retain];
	}
}

- (NSArray *)availableTableColumns {
	return availableTableColumns;
}

- (void)setAvailableTableColumns:(NSArray *)columns {
	if (columns != availableTableColumns) {
		[availableTableColumns release];
		availableTableColumns = [columns retain];
	}
}

- (void)toggleTableColumnVisibility:(NSTableColumn *)column {
	if (rightViewController && [rightViewController respondsToSelector:@selector(toggleTableColumnVisibility:)]) {
		[(id)rightViewController toggleTableColumnVisibility:column];
	}	
}

- (void)removeTableColumnObservers {
	// remove base on the same conditions that it was added on
	if (rightViewController && [rightViewController respondsToSelector:@selector(visibleTableColumns)]) {
		[rightViewController removeObserver:self forKeyPath:@"visibleTableColumns"];
	}
	
	// remove base on the same conditions that it was added on
	if (rightViewController && [rightViewController respondsToSelector:@selector(availableTableColumns)]) {
		[rightViewController removeObserver:self forKeyPath:@"availableTableColumns"];
	}
}

- (void)updateTableColumnsAndObservers {
	if (rightViewController && [rightViewController respondsToSelector:@selector(visibleTableColumns)]) {
		[rightViewController addObserver:self forKeyPath:@"visibleTableColumns" options:0 context:SEVisibleTableColumnContext];
		[self setVisibleTableColumns:[rightViewController performSelector:@selector(visibleTableColumns)]];
	} else {
		[self setVisibleTableColumns:nil];
	}
	
	if (rightViewController && [rightViewController respondsToSelector:@selector(availableTableColumns)]) {
		[rightViewController addObserver:self forKeyPath:@"availableTableColumns" options:0 context:SEAvailableTableColumnContext];
		[self setAvailableTableColumns:[rightViewController performSelector:@selector(availableTableColumns)]];
	} else {
		[self setAvailableTableColumns:nil];
	}
}


#pragma mark observing changes
// ----------------------------------------------------------------------------------------------------
// observing changes
// ----------------------------------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SEVisibleTableColumnContext) {
		[self setVisibleTableColumns:[rightViewController performSelector:@selector(visibleTableColumns)]];
	} else if (context == SEAvailableTableColumnContext) {
		[self setAvailableTableColumns:[rightViewController performSelector:@selector(availableTableColumns)]];		
	} else if (context == SESourceListPlaylistChangeContext) {
		[self setSelectedPlaylist:[sourceListViewController selectedPlaylist]];
	} else if (context == SESourceListSelectionTypeChangeContext) {
		[self updateRightViewController];
	} else if (context == SECopyingStatusChangeContext) {
		if ([[senuti copyController] isCopying]) { [self showLeftBottomView]; }
		else { [self hideLeftBottomtView]; }
	} else if (context == SELibrariresAvailableChangeContext) {
		[self updateDisplayedView];
	}
}


#pragma mark split view delegate
// ----------------------------------------------------------------------------------------------------
// split view delegate
// ----------------------------------------------------------------------------------------------------

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedCoord ofSubviewAt:(int)offset {
	return MIN_SOURCE_TABLE_WIDTH;
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedCoord ofSubviewAt:(int)offset {
	return MAX_SOURCE_TABLE_WIDTH;
}

- (float)splitView:(NSSplitView *)sender constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)offset {
	if (abs(proposedPosition - DEFAULT_SONG_TABLE_WIDTH) < 20) { return DEFAULT_SONG_TABLE_WIDTH; }
	return proposedPosition;
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSArray *subviews = [sender subviews];
	NSView *first = [subviews objectAtIndex:0];
	NSView *second = [subviews objectAtIndex:1];
	
	[first setFrameSize:NSMakeSize([first frame].size.width, [sender frame].size.height)];
	[second setFrameSize:NSMakeSize([sender frame].size.width - [first frame].size.width - [sender dividerThickness], [sender frame].size.height)];
	
	[first setNeedsDisplay:TRUE];
	[second setNeedsDisplay:TRUE];
	[sender adjustSubviews];
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subviews {
	return NO;
}

#pragma mark toolbar delegate
// ----------------------------------------------------------------------------------------------------
// toolbar delegate
// ----------------------------------------------------------------------------------------------------

- (NSArray *)toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	return [NSArray arrayWithObjects:
		SECopyItemIdentifier,
		SESearchItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarSeparatorItemIdentifier, nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
	return [NSArray arrayWithObjects:
		SECopyItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		SESearchItemIdentifier, nil];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item {
	if ([[item itemIdentifier] isEqualToString:SESearchItemIdentifier]) {
		return [self canSearch];
	} else if ([[item itemIdentifier] isEqualToString:SECopyItemIdentifier]) {
		return [self canCopy];
	}
	return NO;
}

- (void)updateSearchFieldEnabledness {
	[searchField setEnabled:[self canSearch]];
	[[searchField superview] setNeedsDisplay:YES];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
	if ([itemIdentifier isEqualToString:SESearchItemIdentifier]) {
		[toolbarItem setLabel:FSLocalizedString(@"Search", nil)];
		[toolbarItem setPaletteLabel:FSLocalizedString(@"Search Songs", nil)];
		[toolbarItem setToolTip:FSLocalizedString(@"Search Songs", nil)];
		[toolbarItem setView:searchField];
		[toolbarItem setMinSize:NSMakeSize(100, [searchField frame].size.height)];
		[toolbarItem setMaxSize:NSMakeSize(300, [searchField frame].size.height)];
	} else if ([itemIdentifier isEqualToString:SECopyItemIdentifier]) {
		[toolbarItem setLabel:FSLocalizedString(@"Transfer", nil)];
		[toolbarItem setPaletteLabel:FSLocalizedString(@"Transfer Songs", nil)];
		[toolbarItem setToolTip:FSLocalizedString(@"Transfer Songs", nil)];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(copySelectedTracks)];
		[toolbarItem setImage:[NSImage imageNamed:@"copy"]];
	}
	return toolbarItem;
}

@end
