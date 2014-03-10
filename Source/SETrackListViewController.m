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

#import "SETrackListViewController.h"
#import "SELibrary.h"
#import "SELibraryController.h"
#import "SEAudioController.h"
#import "SEVisualViewController.h"

#import "SEPaddedTextFieldCell.h"
#import "SEMultiImageCell.h"

#import "SEPlaylist.h"
#import "SETrack.h"
#import "SEITunesLibrary.h"

#define TRACK_LIST_AUTOSAVE_NAME [NSString stringWithFormat:@"%@ %@", [self autosaveName], [[self playlist] name]]
#define APPLIED_DEFAULTS_KEY [NSString stringWithFormat:@"NSTableView Columns %@", TRACK_LIST_AUTOSAVE_NAME]
#define TRACK_LIST_RESTORE_AUTOSAVE_NAME @"SERestoreAutosaveName"

NSString *SETrackPboardType = @"SETrackPboardType";
static void *SETrackListSortDescriptorsChangeContext = @"SETrackListSortDescriptorsChangeContext";
static void *SETrackListSelectionChangeContext = @"SETrackListSelectionChangeContext";
static void *SETrackListObjectsChangeContext = @"SETrackListObjectsChangeContext";
static void *SEPlayingTrackChangeContext = @"SEPlayingTrackChangeContext";

@interface SETrackListViewController (PRIVATE)
- (void)showTableColumn:(NSTableColumn *)column;
- (void)hideTableColumn:(NSTableColumn *)column;
- (void)updateTableColumns;
- (NSArray *)staticTableColumns;
- (void)setStaticTableColumns:(NSArray *)cols;
- (void)setAvailableTableColumns:(NSArray *)cols;
- (void)crossReferenceDidFinish:(NSNotification *)notification;

- (void)setFilterDevicesPredicate:(NSPredicate *)predicate;
- (void)setSearchPredicate:(NSPredicate *)predicate;
- (void)applyPredicates;

- (id <SEPlaylist>)playlist;

- (void)setSelectedObjects:(NSArray *)array;
- (void)setAvailableObjects:(NSArray *)array;

- (void)playSelectedSong:(id)sender;
@end

@implementation SETrackListViewController

+ (NSString *)nibName {
	return @"TrackList";
}

- (id)init {
	if ((self = [super init])) {
		visualViewController = [[SEVisualViewController alloc] init];
	}
	return self;
}

- (void)dealloc {
	[self removeControllerObservers];
	
	[self setStaticTableColumns:nil];
	[self setAvailableTableColumns:nil];
	
	[playlist release];
	[autosaveName release];
	
	[filterDevicesPredicate release];
	[searchPredicate release];
	
	[visualViewController release];
	[selectedObjects release];
	
	[super dealloc];
}

- (void)removeControllerObservers {
	if ([self isViewLoaded]) {
		[visualViewController removeControllerObservers];
		[[senuti libraryController] removeCrossReferenceObserver:self];
		[trackList removeObserver:self forKeyPath:@"sortDescriptors"];
		[tracks removeObserver:self forKeyPath:@"selectionIndex"];
		[tracks removeObserver:self forKeyPath:@"arrangedObjects"];
		[[senuti audioController] removeObserver:self forKeyPath:@"playingTrack"];
	}
}

- (void)awakeFromNib {
	[self setStaticTableColumns:[trackList tableColumns]];
	[trackList setAutosaveTableColumns:YES];
	[trackList setAutosaveName:TRACK_LIST_RESTORE_AUTOSAVE_NAME];
	[trackList setIntercellSpacing:NSMakeSize(0, 1)];
	[trackList setTarget:self];
	[trackList setDoubleAction:@selector(playSelectedSong:)];

	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setLenient:YES];
	
	NSEnumerator *enumerator = [[[[trackList tableColumns] copy] autorelease] objectEnumerator];
	NSTableColumn *column;
	while (column = [enumerator nextObject]) {
		if ([[column identifier] isEqualToString:@"libraries"]) { [[column headerCell] setTitle:@""]; }
		else if ([[column identifier] isEqualToString:@"title"]) { [[column headerCell] setTitle:FSLocalizedString(@"Name", @"Header string for track name")]; }
		else if ([[column identifier] isEqualToString:@"album"]) { [[column headerCell] setTitle:FSLocalizedString(@"Album", @"Header string for track album")]; }
		else if ([[column identifier] isEqualToString:@"artist"]) { [[column headerCell] setTitle:FSLocalizedString(@"Artist", @"Header string for track artist")]; }
		else if ([[column identifier] isEqualToString:@"composer"]) { [[column headerCell] setTitle:FSLocalizedString(@"Composer", @"Header string for track composer")]; }
		else if ([[column identifier] isEqualToString:@"genre"]) { [[column headerCell] setTitle:FSLocalizedString(@"Genre", @"Header string for track genre")]; }
		else if ([[column identifier] isEqualToString:@"type"]) { [[column headerCell] setTitle:FSLocalizedString(@"Filetype", @"Header string for track filetype")]; }
		else if ([[column identifier] isEqualToString:@"comment"]) { [[column headerCell] setTitle:FSLocalizedString(@"Comment", @"Header string for track comment")]; }
		else if ([[column identifier] isEqualToString:@"size"]) { [[column headerCell] setTitle:FSLocalizedString(@"Size", @"Header string for track size")]; }
		else if ([[column identifier] isEqualToString:@"length"]) { [[column headerCell] setTitle:FSLocalizedString(@"Time", @"Header string for track time")]; }
		else if ([[column identifier] isEqualToString:@"playCount"]) { [[column headerCell] setTitle:FSLocalizedString(@"Play Count", @"Header string for track play count")]; }
		else if ([[column identifier] isEqualToString:@"lastModified"]) { [[column headerCell] setTitle:FSLocalizedString(@"Last Modified", @"Header string for track last modified")]; [[column dataCell] setFormatter:dateFormatter]; }
		else if ([[column identifier] isEqualToString:@"lastPlayed"]) { [[column headerCell] setTitle:FSLocalizedString(@"Last Played", @"Header string for track last played")]; [[column dataCell] setFormatter:dateFormatter]; }
		else if ([[column identifier] isEqualToString:@"dateAdded"]) { [[column headerCell] setTitle:FSLocalizedString(@"Date Added", @"Header string for track creation date")]; [[column dataCell] setFormatter:dateFormatter]; }
		else if ([[column identifier] isEqualToString:@"year"]) { [[column headerCell] setTitle:FSLocalizedString(@"Year", @"Header string for track year")]; }
		else if ([[column identifier] isEqualToString:@"trackNumber"]) { [[column headerCell] setTitle:FSLocalizedString(@"Track Number", @"Header string for track track number")]; }
		else if ([[column identifier] isEqualToString:@"discNumber"]) { [[column headerCell] setTitle:FSLocalizedString(@"Disc Number", @"Header string for track disc number")]; }
		else if ([[column identifier] isEqualToString:@"bitRate"]) { [[column headerCell] setTitle:FSLocalizedString(@"Bit Rate", @"Header string for track bit rate")]; }
		else if ([[column identifier] isEqualToString:@"rating"]) {
			[[column headerCell] setTitle:FSLocalizedString(@"Rating", @"Header string for track rating")];
			[column setDataCell:[[[SEMultiImageCell alloc] init] autorelease]];
			[[column dataCell] setImage:[NSImage imageNamed:@"star"]];
		}
		
		[column setEditable:NO];
	}
			
	[self setAvailableTableColumns:[[trackList tableColumns] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier != 'libraries'"]]];
	[[senuti libraryController] addCrossReferenceObserver:self];
	[trackList addObserver:self forKeyPath:@"sortDescriptors" options:0 context:SETrackListSortDescriptorsChangeContext];
	[tracks addObserver:self forKeyPath:@"selectionIndex" options:0 context:SETrackListSelectionChangeContext];
	[tracks addObserver:self forKeyPath:@"arrangedObjects" options:0 context:SETrackListObjectsChangeContext];
	[[senuti audioController] addObserver:self forKeyPath:@"playingTrack" options:0 context:SEPlayingTrackChangeContext];
	
	NSView *visualView = [visualViewController view];
	[visualView setFrame:[bottomView frame]];
	[bottomView addSubview:visualView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SETrackListSortDescriptorsChangeContext) {
		NSArray *descriptors = [trackList sortDescriptors];
		NSArray *newDescriptors = nil;
			
		newDescriptors = [NSSortDescriptor applyStandardOrdering:[NSArray arrayWithObjects:@"genre", @"artist", @"album", @"trackNumber", nil]
												toDescriptors:descriptors];
		if (newDescriptors) { [trackList setSortDescriptors:newDescriptors]; return; }
		

		newDescriptors = [NSSortDescriptor applyStandardOrdering:[NSArray arrayWithObjects:@"artist", @"album", @"trackNumber", nil]
												toDescriptors:descriptors];
		if (newDescriptors) { [trackList setSortDescriptors:newDescriptors]; return; }

		newDescriptors = [NSSortDescriptor applyStandardOrdering:[NSArray arrayWithObjects:@"album", @"trackNumber", nil]
												toDescriptors:descriptors];
		if (newDescriptors) { [trackList setSortDescriptors:newDescriptors]; return; }
	} else if (context == SETrackListSelectionChangeContext) {
		[visualViewController setSelectedTrack:[[tracks selectedObjects] firstObject]];
		[self setSelectedObjects:[[tracks selectedObjects] copy]];
	} else if (context == SETrackListObjectsChangeContext) {
		[visualViewController setVisibleTracks:[tracks arrangedObjects]];
		[self setAvailableObjects:[tracks arrangedObjects]];
	} else if (context == SEPlayingTrackChangeContext) {
		[trackList setNeedsDisplay:YES];
	}
}

- (id <SEPlaylist>)playlist {
	return playlist;
}

- (void)setPlaylist:(id <SEPlaylist>)aPlaylist {
	if (playlist != aPlaylist) {
		[playlist release];
		playlist = [aPlaylist retain];

		[tracks setContent:[[[[self playlist] tracks] copy] autorelease]];
		[visualViewController setPlaylist:aPlaylist];
		[self updateTableColumns];
	}
}

- (void)setSelectedObjects:(NSArray *)array {
	if (array != selectedObjects) {
		[selectedObjects release];
		selectedObjects = [array retain];
	}
}

- (void)setAvailableObjects:(NSArray *)array {
	if (array != availableObjects) {
		[availableObjects release];
		availableObjects = [array retain];
	}
}

- (void)playSelectedSong:(id)sender {
	if ([[[self playlist] library] canPlayAudio]) {
		id <SETrack> track = [[tracks selectedObjects] firstObject];
		if (track) { [[senuti audioController] playTrack:track inPlaylist:[self playlist]]; }
	}
}

#pragma mark public information
// ----------------------------------------------------------------------------------------------------
// public information
// ----------------------------------------------------------------------------------------------------

- (id <NSObject>)objectsOwner {
	return playlist;
}

- (NSArray *)selectedObjects {
	return selectedObjects;
}

- (NSArray *)availableObjects {
	return availableObjects;
}

#pragma mark search
// ----------------------------------------------------------------------------------------------------
// search
// ----------------------------------------------------------------------------------------------------

- (void)search:(NSString *)words limitedTo:(SESearchFieldLimitingType)limited {
	NSArray *keys = nil;

	switch (limited) {
		case SESearchFieldNoLimit: keys = [NSArray arrayWithObjects:@"title", @"artist", @"album", @"genre", @"composer", @"comment", nil]; break;
		case SESearchFieldArtistLimit: keys = [NSArray arrayWithObject:@"artist"]; break;
		case SESearchFieldAlbumLimit: keys = [NSArray arrayWithObject:@"album"]; break;
		case SESearchFieldComposterLimit: keys = [NSArray arrayWithObject:@"composer"]; break;
		case SESearchFieldSongLimit: keys = [NSArray arrayWithObject:@"title"]; break;
		default: [NSException raise:@"Invalid type" format:@"Invalid search field limit type"]; break;
	}
	
	NSString *word;
	NSEnumerator *wordEnumerator = [[words componentsSeparatedByString:@" "] objectEnumerator];
	NSMutableArray *wordPredicates = [NSMutableArray array];
	while (word = [wordEnumerator nextObject]) {
		NSString *key;
		NSEnumerator *keyEnumerator = [keys objectEnumerator];
		NSMutableArray *keyPredicates = [NSMutableArray array];
		while (key = [keyEnumerator nextObject]) {
			if ([word length]) {
				[keyPredicates addObject:[NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", key, word]];
			}
		}
		if ([keyPredicates count]) { [wordPredicates addObject:[NSCompoundPredicate orPredicateWithSubpredicates:keyPredicates]]; }
	}
	if ([wordPredicates count]) { [self setSearchPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:wordPredicates]]; }
	else { [self setSearchPredicate:nil]; }
}

- (void)filterLibraries:(NSSet *)devices {
	id <SELibrary> library;
	NSEnumerator *libraryEnumerator = [devices objectEnumerator];
	NSMutableArray *libraryPredicates = [NSMutableArray array];
	while (library = [libraryEnumerator nextObject]) {
		[libraryPredicates addObject:[NSPredicate predicateWithFormat:@"NOT (similarTracks.library CONTAINS %@)", library]];
	}
	if ([libraryPredicates count]) { [self setFilterDevicesPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:libraryPredicates]]; }
	else { [self setFilterDevicesPredicate:nil]; }
}

- (void)setFilterDevicesPredicate:(NSPredicate *)predicate {
	if (filterDevicesPredicate != predicate) {
		[filterDevicesPredicate release];
		filterDevicesPredicate = [predicate retain];
		[self applyPredicates];
	}
}

- (void)setSearchPredicate:(NSPredicate *)predicate {
	if (searchPredicate != predicate) {
		[searchPredicate release];
		searchPredicate = [predicate retain];
		[self applyPredicates];
	}
}

- (void)applyPredicates {
	NSMutableArray *predicates = [NSMutableArray array];
	if (searchPredicate) { [predicates addObject:searchPredicate]; }
	if (filterDevicesPredicate) { [predicates addObject:filterDevicesPredicate]; }
	
	if ([predicates count]) {
		[tracks setFilterPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
	} else {
		[tracks setFilterPredicate:nil];
	}
}


#pragma mark autosavename
// ----------------------------------------------------------------------------------------------------
// autosavename
// ----------------------------------------------------------------------------------------------------

- (void)setAutosaveName:(NSString *)name {
	if (autosaveName != name) {
		[autosaveName release];
		autosaveName = [name retain];

		[self updateTableColumns];
	}
}

- (NSString *)autosaveName {
	return autosaveName;
}


#pragma mark drag and drop
// ----------------------------------------------------------------------------------------------------
// drag and drop
// ----------------------------------------------------------------------------------------------------

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard  {
	if ([[self playlist] library] == [[senuti libraryController] iTunesLibrary]) {
		return NO;
	} else {
		[pboard declareTypes:[NSArray arrayWithObject:SETrackPboardType] owner:self];
		[pboard setDataDelegate:self withContext:rowIndexes forType:SETrackPboardType];
		return YES;		
	}
}

- (id)pasteboard:(NSPasteboard *)pboard dataForContext:(NSIndexSet *)context {
	return [[tracks arrangedObjects] objectsAtIndexes:context];
}

#pragma mark delegate
// ----------------------------------------------------------------------------------------------------
// delegate
// ----------------------------------------------------------------------------------------------------

- (NSString *)tableView:(NSTableView *)tv toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc row:(int)row mouseLocation:(NSPoint)mouseLocation {
	if (tv == trackList) {
		NSMutableString *tip = [NSMutableString string];
		NSSet *similarTracks = [(<SETrack>)[[tracks arrangedObjects] objectAtIndex:row] similarTracks];

		id <SETrack> track;
		NSEnumerator *similarTracksEnumerator = [similarTracks objectEnumerator];
		while (track = [similarTracksEnumerator nextObject]) {
			[tip appendFormat:@"%@, ", [[track library] name]];
		}
		
		if ([tip length] > 2) {
			return [NSString stringWithFormat:FSLocalizedString(@"Track also on: %@", nil), [tip substringToIndex:[tip length] - 2]];
		} else {
			return FSLocalizedString(@"Track not on other devices", nil);
		}
	}
	return nil;
}

- (NSColor *)tableView:(NSTableView *)tableView backgroundColorForRow:(int)row selected:(BOOL)selected {
	id <SETrack> track = [[tracks arrangedObjects] objectAtIndex:row];
	if (!selected && track == [[senuti audioController] playingTrack]) {
		return [NSColor colorWithCalibratedRed:0.67843137 green:0.79215686 blue:0.99607843 alpha:1];
	} else {
		return nil;
	}
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([cell respondsToSelector:@selector(setTextColor:)]) {
		if ([[self playlist] library] == [[senuti libraryController] iTunesLibrary]) {
			[cell setTextColor:[NSColor disabledControlTextColor]];
		} else {
			[cell setTextColor:[NSColor controlTextColor]];
		}
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row {
	if ([[self playlist] library] == [[senuti libraryController] iTunesLibrary]) { return NO; }
	else { return YES; }
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn {
	return YES;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
	if ([[tableColumn identifier] isEqualToString:@"libraries"] &&
		[[self playlist] type] != SETVShowPlaylistType &&
		[[self playlist] type] != SEMoviePlaylistType &&
		[[self playlist] type] != SEMusicPlaylistType &&
		[[self playlist] type] != SEMasterPlaylistType) {

		[tableView setSortDescriptors:nil];
		[tableView setIndicatorImage:[NSImage imageNamed:@"^"] inTableColumn:tableColumn];
		[tableView setHighlightedTableColumn:tableColumn];
		[tracks rearrangeObjects];
	} else {
		[tableView setHighlightedTableColumn:nil];		
	}
}


#pragma mark table columns
// ----------------------------------------------------------------------------------------------------
// table columns
// ----------------------------------------------------------------------------------------------------

- (void)showTableColumn:(NSTableColumn *)column {
	if ([NSApp isOnLeopardOrBetter]) {
		[(id)column setHidden:FALSE];
		return;
	}
	[self willChangeValueForKey:@"visibleTableColumns"];
	[trackList addTableColumn:column];
	[self didChangeValueForKey:@"visibleTableColumns"];
}

- (void)hideTableColumn:(NSTableColumn *)column {
	if ([NSApp isOnLeopardOrBetter]) {
		[(id)column setHidden:TRUE];
		return;
	}
	[self willChangeValueForKey:@"visibleTableColumns"];
	[trackList removeTableColumn:column];
	[self didChangeValueForKey:@"visibleTableColumns"];
}

- (NSArray *)visibleTableColumns {
	return [trackList tableColumns];
}

- (void)toggleTableColumnVisibility:(NSTableColumn *)column {
	if ([NSApp isOnLeopardOrBetter]) {
		[(id)column setHidden:![(id)column isHidden]];
		return;
	}

	if ([[self availableTableColumns] indexOfObjectIdenticalTo:column] != NSNotFound) {
		if ([[self visibleTableColumns] indexOfObjectIdenticalTo:column] == NSNotFound) {
			[trackList sizeLastColumnToFit];
			
			float makeSpace = [column width];
			NSTableColumn *moveColumn;
			NSEnumerator *enumerator = [[trackList tableColumns] reverseObjectEnumerator];
			while (moveColumn = [enumerator nextObject]) {
				if (makeSpace <= 0) { break; } // made enough space
				
				float currentWidth = [moveColumn width]; // width of last column
				float minWidth = [moveColumn minWidth]; // min width that last column allows
				float changeWidth = currentWidth - minWidth; // max change that the last column could do
				
				// resize either the max (if we need that)
				// or less (if we don't need that much space)
				if (changeWidth > makeSpace) { changeWidth = makeSpace; }
				
				makeSpace -= changeWidth; // we made some space
				[moveColumn setWidth:currentWidth - changeWidth]; // resize the column
			}
			
			[column setWidth:0];			 // the width will now change
			[self showTableColumn:column];	 // after showing the table column
			[trackList sizeLastColumnToFit]; // which will force an autosave
		} else {
			[self hideTableColumn:column];
			[trackList sizeLastColumnToFit];
		}
	}
}

- (NSArray *)staticTableColumns {
	return staticTableColumns;
}

- (void)setStaticTableColumns:(NSArray *)cols {
	if (cols != staticTableColumns) {
		[staticTableColumns release];
		staticTableColumns = [cols copy];
	}
}

- (NSArray *)availableTableColumns {
	return availableTableColumns;
}

- (void)setAvailableTableColumns:(NSArray *)cols {
	if (cols != availableTableColumns) {
		[availableTableColumns release];
		availableTableColumns = [cols copy];
	}
}

- (void)updateTableColumns {

	if ([NSApp isOnLeopardOrBetter]) {
		if ([self playlist]) {
			[trackList setAutosaveName:TRACK_LIST_RESTORE_AUTOSAVE_NAME];
			[trackList setSortDescriptors:nil]; // clear out the sort descriptors (cocoa keeps track of the ones assigned manually)
												// and things start to act funky when they're not cleared
			[trackList setAutosaveName:TRACK_LIST_AUTOSAVE_NAME];
		}
	} else {
				
		// declare some things
		NSTableColumn *column;
		NSEnumerator *tableColumnEnumerator;
		
		// save previos config and wait until
		// everything is added in this config to set the
		// autosave name again
		[self willChangeValueForKey:@"visibleTableColumns"];
		[trackList setAutosaveName:nil];
		[trackList setSortDescriptors:nil]; // clear out the sort descriptors (cocoa keeps track of the ones assigned manually)
											// and things start to act funky when they're not cleared
		
		// remove all table columns
		tableColumnEnumerator = [[[trackList tableColumns] copy] objectEnumerator];
		while (column = [tableColumnEnumerator nextObject]) { [trackList removeTableColumn:column]; }

		if ([self playlist]) {
			// add the table columns
			BOOL appliedDefaults = ([[NSUserDefaults standardUserDefaults] valueForKey:APPLIED_DEFAULTS_KEY] != nil);
			tableColumnEnumerator = [[self staticTableColumns] objectEnumerator];
			while (column = [tableColumnEnumerator nextObject]) {
				// add only the defaults if they've never been applied before
				if (appliedDefaults ||
					[[column identifier] isEqualToString:@"libraries"] ||
					[[column identifier] isEqualToString:@"title"] ||
					[[column identifier] isEqualToString:@"artist"] ||
					[[column identifier] isEqualToString:@"album"] ||
					[[column identifier] isEqualToString:@"genre"] ||
					[[column identifier] isEqualToString:@"length"] ||
					[[column identifier] isEqualToString:@"rating"] ||
					[[column identifier] isEqualToString:@"playCount"]) {
					[trackList addTableColumn:column];
				}
			}
			
			// the width will now change after showing the table column  which will force an autosave
			[[[trackList tableColumns] lastObject] setWidth:0];

			[trackList setAutosaveName:TRACK_LIST_AUTOSAVE_NAME];
			[trackList sizeLastColumnToFit];
		}

		[self didChangeValueForKey:@"visibleTableColumns"];
	}
	
	// apply default sort descriptors
	if ([[trackList sortDescriptors] count] == 0) {
		if ([[self playlist] type] == SETVShowPlaylistType ||
			[[self playlist] type] == SEMoviePlaylistType ||
			[[self playlist] type] == SEMusicPlaylistType ||
			[[self playlist] type] == SEMasterPlaylistType) {
			
			[trackList setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor descriptorWithKey:@"artist" ascending:YES]]];
			[trackList setHighlightedTableColumn:[trackList tableColumnWithIdentifier:@"artist"]];
			[tracks rearrangeObjects];			
		} else {
			NSTableColumn *tableColumn = [trackList tableColumnWithIdentifier:@"libraries"];
			[trackList setIndicatorImage:[NSImage imageNamed:@"^"] inTableColumn:tableColumn];
			[trackList setHighlightedTableColumn:tableColumn];
			[tracks rearrangeObjects];
		}
	} else {
		if (([[self playlist] type] == SETVShowPlaylistType ||
			[[self playlist] type] == SEMoviePlaylistType ||
			[[self playlist] type] == SEMusicPlaylistType ||
			[[self playlist] type] == SEMasterPlaylistType) && [[[[trackList sortDescriptors] objectAtIndex:0] key] isEqualToString:@"libraries"]) {
			[trackList setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor descriptorWithKey:@"artist" ascending:YES]]];
			[trackList setHighlightedTableColumn:[trackList tableColumnWithIdentifier:@"artist"]];
			[tracks rearrangeObjects];			
		} else {
			[trackList setHighlightedTableColumn:[trackList tableColumnWithIdentifier:[[[trackList sortDescriptors] objectAtIndex:0] key]]];
		}
	}
}


#pragma mark cross reference observations
// ----------------------------------------------------------------------------------------------------
// cross reference observations
// ----------------------------------------------------------------------------------------------------

- (void)didCross:(id <SELibrary>)firstLibrary with:(id <SELibrary>)secondLibrary {
	id displayedLibrary = [[self playlist] library];
	if (displayedLibrary == firstLibrary || displayedLibrary == secondLibrary) {
		[trackList reloadData];		
	}
}

@end
