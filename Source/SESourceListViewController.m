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

#import "SESourceListViewController.h"

#import "SELibraryController.h"
#import "SECopyController.h"
#import "SETrackListViewController.h"

#import "SEIPodLibrary.h"
#import "SEITunesLibrary.h"
#import "SELibrary.h"
#import "SEPlaylist.h"
#import "SEGradientTableView.h"

NSString *SEPlaylistPboardType = @"SEPlaylistPboardType";
static void *SESourceListContentChangeContext = @"SESourceListContentChangeContext";
static void *SELibrariresAvailableChangeContext = @"SELibrariresAvailableChangeContext";

@interface SESourceListViewController (PRIVATE)
- (void)noteSelectionChange;
- (void)updateData;
- (void)reloadData;
- (NSArray *)iPodPlaylists;
- (id)tableView:(NSTableView *)tableView itemAtIndex:(int)row;
- (int)tableView:(NSTableView *)tableView indexOfItem:(id)item;

- (void)setSelectedObject:(id)object;
- (void)setSelectionType:(SESourceSelectionTpe)type;
- (void)setSelectedPlaylist:(id <SEPlaylist>)playlist;
@end

@implementation SESourceListViewController

+ (NSString *)nibName {
	return @"SourceList";
}

- (id)init {
	if ((self = [super init])) {
		data = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[self removeControllerObservers];

	[data release];
	[selectedPlaylist release];	
	[super dealloc];
}

- (void)removeControllerObservers {
	if ([self isViewLoaded]) {
		[[senuti libraryController] removeObserver:self forKeyPath:@"iPodLibraries"];
		[[senuti libraryController] removeObserver:self forKeyPath:@"iTunesLibrary.playlists"];
	}
}

- (void)awakeFromNib {	
	[[[sourceList tableColumns] objectAtIndex:0] setDataCell:[[[FSButtonImageTextCell alloc] init] autorelease]];
	[sourceList registerForDraggedTypes:[NSArray arrayWithObjects:SETrackPboardType, SEPlaylistPboardType, nil]];
	
	[[senuti libraryController] addObserver:self forKeyPath:@"iPodLibraries" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:SELibrariresAvailableChangeContext];
	[[senuti libraryController] addObserver:self forKeyPath:@"iTunesLibrary.playlists" options:0 context:SESourceListContentChangeContext];
	
	[sourceList setAutosaveTableColumns:YES];
	[sourceList sizeLastColumnToFit];
	[sourceList setTrackMouseEvents:TRUE];
	
	[self reloadData];
}

- (void)setAutosaveName:(NSString *)name {
	[sourceList setAutosaveName:name];
}

- (NSString *)autosaveName {
	return [sourceList autosaveName];
}

#pragma mark data changes
// ----------------------------------------------------------------------------------------------------
// data changes
// ----------------------------------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SESourceListContentChangeContext) {
		[self reloadData];
	} else if (context == SELibrariresAvailableChangeContext) {
		id playlist;

		NSEnumerator *oldLibraryEnumerator = [[change objectForKey:NSKeyValueChangeOldKey] objectEnumerator];
		while (playlist = [oldLibraryEnumerator nextObject]) {
			[playlist removeObserver:self forKeyPath:@"playlists"];
		}

		NSEnumerator *newLibraryEnumerator = [[change objectForKey:NSKeyValueChangeNewKey] objectEnumerator];
		while (playlist = [newLibraryEnumerator nextObject]) {
			[playlist addObserver:self forKeyPath:@"playlists" options:0 context:SESourceListContentChangeContext];
		}
		
		[self reloadData];
	}
}

- (void)noteSelectionChange {
	[self setSelectedObject:[self tableView:sourceList itemAtIndex:[sourceList selectedRow]]];
}

- (void)reloadData {
	[self updateData];
	[sourceList reloadData];
	
	if (![self tableView:sourceList shouldSelectRow:[sourceList selectedRow]]) {
		int counter;
		for (counter = 0; counter < [self numberOfRowsInTableView:sourceList]; counter++) {
			if ([self tableView:sourceList shouldSelectRow:counter]) {
				[sourceList selectRow:counter byExtendingSelection:NO];
				break;
			}
		}
	}
	
	// make sure the selection is up to date as well
	[self noteSelectionChange];
}

- (void)updateData {
	[data removeAllObjects];
	NSEnumerator *libraryEnumerator = [[[senuti libraryController] iPodLibraries] objectEnumerator];
	id <SELibrary> library;
	while (library = [libraryEnumerator nextObject]) {
		[data addObject:library];
		[data addObjectsFromArray:[library playlists]];
	}
	
	if ((library = [[senuti libraryController] iTunesLibrary]) && [library masterPlaylist]) {
		[data addObject:library];
		[data addObjectsFromArray:[library playlists]];
	}
}


#pragma mark properties
// ----------------------------------------------------------------------------------------------------
// properties
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

- (void)setSelectionType:(SESourceSelectionTpe)type {
	if (selectionType != type) {
		selectionType = type;
	}
}

- (SESourceSelectionTpe)selectionType {
	return selectionType;
}

- (void)setSelectedObject:(id)object {
	if (selectedObject != object) {
		
		SESourceSelectionTpe type;
		id <SEPlaylist> playlist = nil;
		
		if ([object conformsToProtocol:@protocol(SEPlaylist)]) {
			type = SESourcePlaylistSelection;
			playlist = object;
		} else {
			type = SESourceEmptySelection;
		}
		
		[self setSelectedPlaylist:playlist];
		[self setSelectionType:type];
	}
}


#pragma mark actions
// ----------------------------------------------------------------------------------------------------
// actions
// ----------------------------------------------------------------------------------------------------

- (void)eject:(id)sender {
	if (!sender) {
		id library = [[self selectedPlaylist] library];
		if ([library isKindOfClass:[SEIPodLibrary class]]) {
			[[senuti libraryController] eject:library];
		} else {
			NSBeep();
		}
	} else if ([sender isKindOfClass:[NSCell class]]) {
		[[senuti libraryController] eject:[(NSCell *)sender representedObject]];
	}
}

- (BOOL)canEject {
	id library = [[self selectedPlaylist] library];
	return [library isKindOfClass:[SEIPodLibrary class]];
}

#pragma mark tableview delegate and data source
// ----------------------------------------------------------------------------------------------------
// tableview delegate and data source
// ----------------------------------------------------------------------------------------------------

- (NSArray *)iPodPlaylists {
	return data;
}

- (id)tableView:(NSTableView *)tableView itemAtIndex:(int)row {
	if (row < [[self iPodPlaylists] count]) { return [[self iPodPlaylists] objectAtIndex:row]; }
	else { return nil; }
}

- (int)tableView:(NSTableView *)tableView indexOfItem:(id)item {
	return [[self iPodPlaylists] indexOfObjectIdenticalTo:item];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	if (sourceList == [notification object]) {
		[self noteSelectionChange];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row {
	id item = [self tableView:tableView itemAtIndex:row];	
	if ([item conformsToProtocol:@protocol(SELibrary)]) {
		return NO;
	} else {
		return YES;
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[self iPodPlaylists] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	id item = [self tableView:tableView itemAtIndex:row];	
	if ([item conformsToProtocol:@protocol(SEPlaylist)]) {
		if ([[item library] masterPlaylist] == item) {
			return FSLocalizedString(@"Library", @"Name of library in source list");
		} else {
			return [item name];
		}
	} else if ([item conformsToProtocol:@protocol(SELibrary)]) {
		return [[item name] uppercaseString];
	}
	return nil;	
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	id item = [self tableView:tableView itemAtIndex:row];
	
	[cell setButtonImage:nil];
	[cell setTarget:nil];
	[cell setAction:NULL];
	
	if ([item conformsToProtocol:@protocol(SEPlaylist)]) {
		if ([[item library] masterPlaylist] == item) {
			[cell setImage:[NSImage imageNamed:@"library"]];
		} else if ([(id <SEPlaylist>)item type] == SEMusicPlaylistType) {	
			if ([item library] == [[senuti libraryController] iTunesLibrary]) {
				[cell setImage:[NSImage imageNamed:@"itunes_music"]];
			} else {
				[cell setImage:[NSImage imageNamed:@"library"]];
			}
		} else if ([(id <SEPlaylist>)item type] == SEMoviePlaylistType) {
			[cell setImage:[NSImage imageNamed:@"library"]];			
		} else if ([(id <SEPlaylist>)item type] == SETVShowPlaylistType) {
			[cell setImage:[NSImage imageNamed:@"library"]];			
		} else if ([(id <SEPlaylist>)item type] == SEPurchasedMusicPlaylistType) {
			[cell setImage:[NSImage imageNamed:@"library"]];			
		} else if ([(id <SEPlaylist>)item type] == SEAudiobookPlaylistType) {
			[cell setImage:[NSImage imageNamed:@"library"]];			
		} else if ([(id <SEPlaylist>)item type] == SEPodcastPlaylistType) {
			[cell setImage:[NSImage imageNamed:@"library"]];			
		} else if ([(id <SEPlaylist>)item type] == SEPartyShufflePlaylistType) {
			[cell setImage:[NSImage imageNamed:@"library"]];			
		} else if ([(id <SEPlaylist>)item type] == SESmartPlaylistType) {
			[cell setImage:[NSImage imageNamed:@"smart_playlist"]];			
		} else {
			[cell setImage:[NSImage imageNamed:@"playlist"]];
		}
		[cell setFont:[NSFont systemFontOfSize:[[cell font] pointSize]]];
		[cell setTextColor:nil];
	} else if ([item conformsToProtocol:@protocol(SELibrary)]) {
		[cell setImage:nil];
		[cell setFont:[NSFont boldSystemFontOfSize:[[cell font] pointSize]]];
		[cell setTextColor:[NSColor colorWithCalibratedWhite:0.3 alpha:1]];
		if ([item isKindOfClass:[SEIPodLibrary class]]) {
			[cell setButtonImage:[NSImage imageNamed:@"eject"]];
			[cell setTarget:self];
			[cell setAction:@selector(eject:)];
			[cell setRepresentedObject:item];
		}
	} else {
		[cell setImage:nil];
		[cell setFont:[NSFont systemFontOfSize:[[cell font] pointSize]]];
		[cell setTextColor:nil];
	}
}

#pragma mark drag and drop
// ----------------------------------------------------------------------------------------------------
// drag and drop
// ----------------------------------------------------------------------------------------------------

- (NSDragOperation)tableView:(NSTableView*)tableView
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)op {
	
	if (op == NSTableViewDropOn) {
		NSString *type = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SETrackPboardType, SEPlaylistPboardType, nil]];
		BOOL allowPlaylist = FALSE;
		BOOL allowLibrary = FALSE;
		
		if ([type isEqualToString:SETrackPboardType]) { allowPlaylist = allowLibrary = TRUE; }
		else if ([type isEqualToString:SEPlaylistPboardType]) { allowLibrary = TRUE; }

		if (allowPlaylist || allowLibrary) {
			id item = [self tableView:tableView itemAtIndex:row];
			
			id <SELibrary> library;
			if (allowPlaylist &&
				[item conformsToProtocol:@protocol(SEPlaylist)] &&
				(library = [(id <SEPlaylist>)item library]) == [[senuti libraryController] iTunesLibrary]) {

				if ([(id <SEPlaylist>)item type] == SEStandardPlaylistType) { return NSDragOperationGeneric; }
				else {
					[tableView setDropRow:[self tableView:tableView indexOfItem:library] dropOperation:NSTableViewDropOn];
					return NSDragOperationGeneric;
				}
			} else if (allowLibrary && [item conformsToProtocol:@protocol(SELibrary)]) {
				if (item == [[senuti libraryController] iTunesLibrary]) { return NSDragOperationGeneric; }
				else { return NSDragOperationNone; }
			}
		}
	}
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)tableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)op {

	
	if (op == NSTableViewDropOn) {
		NSString *type = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:SETrackPboardType, SEPlaylistPboardType, nil]];
		id item = [self tableView:tableView itemAtIndex:row];

		if ([type isEqualToString:SETrackPboardType]) {
			id <SELibrary> library;
			if ([item conformsToProtocol:@protocol(SEPlaylist)] &&
				(library = [(id <SEPlaylist>)item library]) == [[senuti libraryController] iTunesLibrary]) {
				
				if ([(id <SEPlaylist>)item type] == SEStandardPlaylistType) {
					[[senuti copyController] copyTracks:[[info draggingPasteboard] dataFromDelegateForType:type]
													 to:item];
					return YES;
				}
			} else if ([item conformsToProtocol:@protocol(SELibrary)]) {
				if (item == [[senuti libraryController] iTunesLibrary]) {
					[[senuti copyController] copyTracks:[[info draggingPasteboard] dataFromDelegateForType:type]
													 to:[(id <SELibrary>)item masterPlaylist]];
					return YES;
				}
			}
		} else if ([type isEqualToString:SEPlaylistPboardType]) {
			if ([item conformsToProtocol:@protocol(SELibrary)]) {
				if (item == [[senuti libraryController] iTunesLibrary]) {
					id <SEPlaylist> playlist = [[info draggingPasteboard] dataFromDelegateForType:type];
					
					if ([[playlist library] masterPlaylist] == playlist) {
						// if dragging to the master playlist for the device,
						// just copy the songs in to the library
						[[senuti copyController] copyTracks:[playlist tracks]
														 to:[(id <SELibrary>)item masterPlaylist]];
					} else {
						// otherwise copy the songs of the playlist into a new
						// playlist with the name of the dragged playlist
						[[senuti copyController] copyTracks:[playlist tracks]
											toPlaylistNamed:[playlist name]];
					}
					return YES;
				}
			}
		}
	}
	
	return NO;
}


#pragma mark drag and drop source
// ----------------------------------------------------------------------------------------------------
// drag and drop source
// ----------------------------------------------------------------------------------------------------

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard  {
	if ([rowIndexes count] == 1) {
		id playlist = [self tableView:sourceList itemAtIndex:[rowIndexes firstIndex]];
		if ([playlist conformsToProtocol:@protocol(SEPlaylist)] &&
			[playlist library] != [[senuti libraryController] iTunesLibrary]) {
			[pboard declareTypes:[NSArray arrayWithObject:SEPlaylistPboardType] owner:self];
			[pboard setDataDelegate:self withContext:[NSNumber numberWithInt:[rowIndexes firstIndex]] forType:SEPlaylistPboardType];
			return YES;		
		}
	}	
	return NO;
}

- (id)pasteboard:(NSPasteboard *)pboard dataForContext:(NSNumber *)context {
	return [self tableView:sourceList itemAtIndex:[context intValue]];
}

@end
