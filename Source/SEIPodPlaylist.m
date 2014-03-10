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

#import "SEIPodPlaylist.h"

@interface SEIPodPlaylist (PRIVATE)
- (void)setNameWithUTF8String:(char *)name;

void add_song(Itdb_Track *track, SEIPodPlaylist *playlist);
@end

@implementation SEIPodPlaylist

- (id)init {
	FSLog(@"Must initiate SEIPodPlaylist with initWithData:");
	return nil;
}

- (void)dealloc {
	[name release];
	[tracks release];
	[super dealloc];
}

- (id)initWithData:(Itdb_Playlist *)playlist {
	if (playlist && (self = [super init])) {
		_playlist = playlist;
		tracks = [[NSMutableArray alloc] init];
		
		[self setNameWithUTF8String:_playlist->name];
		g_list_foreach(_playlist->members, (GFunc)add_song, self);

		return self;
	}
	return nil;
}

- (void)setNameWithUTF8String:(char *)utf8String {
	[name autorelease];
	name = [[NSString alloc] initWithUTF8String:utf8String];
}

- (NSString *)name {
	return name;
}

- (void)addTrack:(id <SETrack>)track {
	FSLog(@"SEIPodPlaylist cannot add tracks.  Not supported (yet).");
}

- (void)removeTrack:(id <SETrack>)track {
	FSLog(@"SEIPodPlaylist cannot remove tracks.  Not supported (yet).");
}

- (NSArray *)tracks {
	return tracks;
}

- (id <SELibrary>)library {
	return (_playlist && _playlist->itdb) ? _playlist->itdb->userdata : nil;
}

- (SEPlaylistType)type {
	if (_playlist == NULL) { return SEStandardPlaylistType; }
	else if (_playlist == itdb_playlist_mpl(_playlist->itdb)) { return SEMasterPlaylistType; }
	else if (_playlist->is_spl) { return SESmartPlaylistType; }
	else if (_playlist->podcastflag) { return SEPodcastPlaylistType; }
	return SEStandardPlaylistType;
}

void add_song(Itdb_Track *track, SEIPodPlaylist *playlist) {
	if (track->userdata) {
		[playlist->tracks addObject:track->userdata];
	}
}

@end
