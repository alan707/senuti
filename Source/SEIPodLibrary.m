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

#import "SEIPodLibrary.h"
#import "SEIPodPlaylist.h"
#import "SEIPodTrack.h"

#import "SELibrary.h"
#import "SEPlaylist.h"
#import "SETrack.h"

@interface SEIPodLibrary (PRIVATE)
- (void)createDatabase;
- (void)attachDatabase;
- (void)destroyDatabase;

- (Itdb_iTunesDB *)database;

void attach_cocoa_track(Itdb_Track *track, gpointer data);
void attach_cocoa_playlist(Itdb_Playlist *playlist, gpointer data);
void detach_cocoa_track(Itdb_Track *track, gpointer data);
void detach_cocoa_playlist(Itdb_Playlist *playlist, gpointer data);
@end

@implementation SEIPodLibrary

+ (Class)trackClass {
	return [SEIPodTrack class];
}

+ (BOOL)looksLikeIPod:(NSString *)path {
	BOOL isDir = FALSE;
	return [[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"iPod_Control"]
												isDirectory:&isDir] && isDir;
}

- (id)init {
	FSLog(@"Must initiate SEIPodLibrary with initWithIPodAtPath:");
	return nil;
}

- (id)initWithIPodAtPath:(NSString *)path {
	if ((self = [super init])) {
		playlists = [[NSMutableArray alloc] init];
		iPodPath = [path retain];
		
		[self createDatabase];
		if (_database == NULL) {
			[self release];
			return nil;
		} else {
			[self attachDatabase];
		}
	}
	return self;
}

- (id)initWithMobile:(LXMobile *)mob {
	if ((self = [super init])) {
		playlists = [[NSMutableArray alloc] init];
		iPodPath = [@"" retain];
		mobile = [mob retain];
		[self attachDatabase];
	}
	return self;
}

- (void)dealloc {		
	[mobile release];
	mobile = nil;
	[self destroyDatabase];
	[playlists release];
	[iPodPath release];
    [super dealloc];
}

- (Itdb_iTunesDB *)database {
	return mobile ? [mobile contents] : _database;
}

- (void)createDatabase {

	GError *error = NULL;
	_database = itdb_parse([[self iPodPath] UTF8String], &error);
	if (error != NULL) {
		if (error->code != ITDB_FILE_ERROR_NOTFOUND) {
			FSLog(@"failed to initialize iPod database file: %s", error->message);
		}
		g_error_free(error);
		return;
	}
	if (_database == NULL) {
		FSLog(@"unexpected return value from itdb_parse_file");
		return;
	}
}

- (void)attachDatabase {
		
	[self database]->userdata = self;
	
	// track cocoa objects need to be attached first
	// when cocoa playlists are created, they use the cocoa track objects
	g_list_foreach([self database]->tracks, (GFunc)attach_cocoa_track, NULL);
	g_list_foreach([self database]->playlists, (GFunc)attach_cocoa_playlist, NULL);
	
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([playlists count], itdb_playlists_number([self database]))];
	[self willChange:NSKeyValueChangeInsertion
	 valuesAtIndexes:indexes
			  forKey:@"playlists"];
	int counter;
	for (counter = 0; counter < itdb_playlists_number([self database]); counter++) {
		[playlists addObject:(id)itdb_playlist_by_nr([self database], counter)->userdata];
	}
	
	[playlists sortUsingDescriptors:[NSArray arrayWithObjects:
		[NSSortDescriptor descriptorWithKey:@"type" ascending:FALSE],
		[NSSortDescriptor descriptorWithKey:@"name" ascending:TRUE], nil]];

	[self didChange:NSKeyValueChangeInsertion
	 valuesAtIndexes:indexes
			  forKey:@"playlists"];
	
	// add the tracks to the base class array
	[tracks addObjectsFromArray:[[self masterPlaylist] tracks]];

}

- (void)destroyDatabase {
	if ([self database] != _database) { return; }
	if (_database == NULL) { return; }
	
	g_list_foreach(_database->playlists, (GFunc)detach_cocoa_playlist, NULL);
	g_list_foreach(_database->tracks, (GFunc)detach_cocoa_track, NULL);

	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [playlists count])];
	[self willChange:NSKeyValueChangeRemoval
	 valuesAtIndexes:indexes
			  forKey:@"playlists"];
	[playlists removeAllObjects];
	[self willChange:NSKeyValueChangeRemoval
	 valuesAtIndexes:indexes
			  forKey:@"playlists"];
	
	_database->userdata = NULL;
	itdb_free(_database);
	_database = NULL;
}

- (NSString *)iPodPath {
	return iPodPath;
}

- (LXMobile *)mobile {
	return mobile;
}

- (BOOL)canPlayAudio {
	return mobile == nil;
}

- (NSString *)name {
	return [[self masterPlaylist] name];
}

- (id <SEPlaylist>)masterPlaylist {
	if ([self database]) { return itdb_playlist_mpl([self database])->userdata; }
	else { return nil; }
}

- (NSArray *)playlists {
	return playlists;
}

- (NSArray *)tracks {
	return [super tracks];
}

- (void)addTrack:(id <SETrack>)track {
	[super addTrack:track];
}

void attach_cocoa_track(Itdb_Track *track, gpointer arbitrary) {
	track->userdata = [(SEIPodTrack *)[SEIPodTrack alloc] initWithData:track];
}

void attach_cocoa_playlist(Itdb_Playlist *playlist, gpointer arbitrary) {
	playlist->userdata = [(SEIPodPlaylist *)[SEIPodPlaylist alloc] initWithData:playlist];
}

void detach_cocoa_track(Itdb_Track *track, gpointer arbitrary) {
	if (track->userdata) { [(id <SETrack>)track->userdata release]; }
	track->userdata = NULL;
}

void detach_cocoa_playlist(Itdb_Playlist *playlist, gpointer arbitrary) {
	[(id <SETrack>)playlist->userdata release];
	playlist->userdata = NULL;
}

@end
