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

#import "SEITunesLibrary.h"

#import "SEITunesTrack.h"
#import "SEITunesPlaylist.h"
#import "SETrack.h"
#import "SEPlaylist.h"

#define DEFAULT_MUSIC_FOLDER_URL ([NSURL fileURLWithPath:[FSLocalizedString(@"~/Music/iTunes/iTunes Music", @"The path to the default iTunes music folder") stringByExpandingTildeInPath]])

@interface SEITunesLibrary (PRIVATE)

- (void)setMusicFolderLocation:(NSURL *)location;
- (void)setMasterPlaylist:(SEITunesPlaylist *)playlist;
- (BOOL)getContentFromITunes;
- (NSURL *)libraryLocation;
- (void)addPlaylist:(SEITunesPlaylist *)playlist;

@end

@implementation SEITunesLibrary

+ (Class)trackClass {
	return [SEITunesTrack class];
}

- (id)init {
	if ((self = [super init])) {
		playlists = [[NSMutableArray alloc] init];
		
		if (![self getContentFromITunes]) {
			// set sane default
			// which is used by other parts of the app
			[self setMusicFolderLocation:DEFAULT_MUSIC_FOLDER_URL];
		}
	}
	return self;
}

- (void)dealloc {
	[playlists release];
	[masterPlaylist release];

	[super dealloc];
}

- (void)setMasterPlaylist:(SEITunesPlaylist *)playlist {
	if (masterPlaylist != playlist) {
		[masterPlaylist release];
		masterPlaylist = [playlist retain];
	}
}

- (NSString *)name {
	return @"iTunes";
}

- (id <SEPlaylist>)masterPlaylist {
	return masterPlaylist;
}

- (NSArray *)playlists {
	return playlists;
}

- (void)addPlaylist:(SEITunesPlaylist *)playlist {
	int index = [playlists count];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"playlists"];
	[playlists addObject:playlist];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"playlists"];
}

- (NSArray *)tracks {
	return [super tracks];
}

- (void)addTrack:(id <SETrack>)track {
	[super addTrack:track];
}

- (void)setMusicFolderLocation:(NSURL *)url {
	if (url != musicFolderLocation) {
		[musicFolderLocation release];
		musicFolderLocation = [url retain];
	}
}

- (NSURL *)musicFolderLocation {
	return musicFolderLocation;
}

- (NSURL *)libraryLocation {
	NSURL *databaseURL = nil;
	NSString *databasePath = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.iApps"]
		objectForKey:@"iTunesRecentDatabases"] lastObject];
	
	if (databasePath) {
		databaseURL = [NSURL URLWithString:databasePath];
		if (![databaseURL isFileURL]) { databaseURL = nil; }
	}
	if (!databaseURL) { FSLog(@"WARNING: Couldn't find iTunes library XML file (databasePath='%@')", databasePath); }
	
	return databaseURL;
}    

- (BOOL)getContentFromITunes {
	
	NSURL *libraryLocation = [self libraryLocation];
	if (!libraryLocation) { return FALSE; }

	NSDictionary *data = [NSDictionary dictionaryWithContentsOfURL:libraryLocation];
	if (!data) { return FALSE; }
	
	NSMutableDictionary *library = [[NSMutableDictionary alloc] init];
	NSString *musicFolder = [data objectForKey:@"Music Folder"];
	
	if (musicFolder) { [self setMusicFolderLocation:[NSURL URLWithString:musicFolder]]; }
	else { [self setMusicFolderLocation:DEFAULT_MUSIC_FOLDER_URL]; }
	
	NSEnumerator *trackDataEnumerator = [[(NSDictionary *)[data objectForKey:@"Tracks"] allValues] objectEnumerator];
	NSDictionary *track_data;
	while (track_data = [trackDataEnumerator nextObject])
	{
		SEITunesTrack *track = [[SEITunesTrack alloc] initInLibrary:self];
		
		[track setIdentifier:[[track_data objectForKey:@"Track ID"] intValue]];
		[track setPersistentID:[[track_data objectForKey:@"Persistent ID"] lowercaseString]];
		[track setRating:[[track_data objectForKey:@"Rating"] intValue] / 20];
		[track setDateAdded:[[[NSCalendarDate alloc] initWithString:[[track_data objectForKey:@"Date Added"] description]] autorelease]];
		[track setSize:[[track_data objectForKey:@"Size"] intValue]];
		[track setLength:(float)[[track_data objectForKey:@"Total Time"] intValue] / 1000];
		[track setTrackNumber:[[track_data objectForKey:@"Track Number"] intValue]];
		[track setTotalTrackNumbers:[[track_data objectForKey:@"Track Count"] intValue]];
		[track setYear:[[track_data objectForKey:@"Track Number"] intValue]];
		[track setBitRate:[[track_data objectForKey:@"Bit Rate"] intValue]];
		[track setLastModified:[[[NSCalendarDate alloc] initWithString:[[track_data objectForKey:@"Date Modified"] description]] autorelease]];
//		[track setVolumeAdjustment:([[track_data objectForKey:@"Track Number"] floatValue]] / 255)];
		[track setStartTime:(float)[[track_data objectForKey:@"Start Time"] intValue] / 1000];
		[track setStopTime:(float)[[track_data objectForKey:@"Stop Time"] intValue] / 1000];
//		[track setSoundCheck:(float)(4.333 * (6.9 - log(longFrom4Bytes(pos+76, contents))))];
		[track setPlayCount:[[track_data objectForKey:@"Play Count"] intValue]];
		[track setDiscNumber:[[track_data objectForKey:@"Disc Number"] intValue]];
		[track setTotalDiscs:[[track_data objectForKey:@"Disc Count"] intValue]];
		[track setTitle:[NSString stringWithStringOrNil:[track_data objectForKey:@"Name"]]];
		[track setArtist:[NSString stringWithStringOrNil:[track_data objectForKey:@"Artist"]]];
		[track setAlbum:[NSString stringWithStringOrNil:[track_data objectForKey:@"Album"]]];
		[track setGenre:[NSString stringWithStringOrNil:[track_data objectForKey:@"Genre"]]];
		[track setComment:[NSString stringWithStringOrNil:[track_data objectForKey:@"Comment"]]];
		[track setComposer:[NSString stringWithStringOrNil:[track_data objectForKey:@"Composer"]]];
		[track setType:[NSString stringWithStringOrNil:[track_data objectForKey:@"Kind"]]];
		
		NSString *location = [track_data objectForKey:@"Location"];
		if (location) { location = [[NSURL URLWithString:location] path]; }
		[track setPath:[NSString stringWithStringOrNil:location]];
		
		[tracks addObject:track];
		[library setObject:track forKey:[NSString stringWithFormat:@"%i", [track identifier]]];
		[track release];
	}
	
	NSEnumerator *listsEnumerator = [[data objectForKey:@"Playlists"] objectEnumerator];
	NSDictionary *list;
	while (list = [listsEnumerator nextObject])
	{		
		SEPlaylistType type = SEStandardPlaylistType;
		if ([list objectForKey:@"Smart Info"]) { type = SESmartPlaylistType; }
		else if ([[list objectForKey:@"Music"] boolValue]) { type = SEMusicPlaylistType; }
		else if ([[list objectForKey:@"Movies"] boolValue]) { type = SEMoviePlaylistType; }
		else if ([[list objectForKey:@"TV Shows"] boolValue]) { type = SETVShowPlaylistType; }
		else if ([list objectForKey:@"Purchased Music"]) { type = SEPurchasedMusicPlaylistType; }
		else if ([[list objectForKey:@"Audiobooks"] boolValue]) { type = SEAudiobookPlaylistType; }
		else if ([[list objectForKey:@"Podcasts"] boolValue]) { type = SEPodcastPlaylistType; }
		else if ([[list objectForKey:@"Party Shuffle"] boolValue]) { type = SEPartyShufflePlaylistType; }
		else if ([[list objectForKey:@"Master"] boolValue]) { type = SEMasterPlaylistType; }
		
		// don't add hidden playlists
		if ([list objectForKey:@"Visible"] && [[list objectForKey:@"Visible"] boolValue] == FALSE) {
			// master playlist still needs to be processed
			// even if it's hidden... all other playlists need not be
			if (type != SEMasterPlaylistType) { continue; }
		}
		
		SEITunesPlaylist *playlist = [[[SEITunesPlaylist alloc] initInLibrary:self
																		 name:[list objectForKey:@"Name"]
																		 type:type] autorelease];
				
		// add the playlist after getting name and info so it gets sorted correctly
		if (type == SEMasterPlaylistType) {
			[self setMasterPlaylist:playlist];
			[playlists removeObject:playlist]; /* don't display master playlist...
												* music playlist does this now */
		}		
		
		NSArray *playlistItems = [list objectForKey:@"Playlist Items"];
		NSEnumerator *playlistItemsEnumerator = [playlistItems objectEnumerator];
		NSDictionary *playlistItem;
		while (playlistItem = [playlistItemsEnumerator nextObject]) {
			NSNumber *ref = [playlistItem objectForKey:@"Track ID"];
			NSString *key = [NSString stringWithFormat:@"%i", [ref intValue]];
			SEITunesTrack *add = [library objectForKey:key];
			if (add) { [playlist addTrack:add]; }
		}		
	}
		
	[library release];
	[playlists sortUsingDescriptors:[NSArray arrayWithObjects:
		[NSSortDescriptor descriptorWithKey:@"type" ascending:FALSE],
		[NSSortDescriptor descriptorWithKey:@"name" ascending:TRUE], nil]];
	
	return TRUE;
}


@end
