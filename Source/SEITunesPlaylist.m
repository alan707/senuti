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

#import "SEITunesPlaylist.h"
#import "SEITunesLibrary.h"

@interface SEITunesLibrary (PRIVATE)
- (void)addPlaylist:(SEITunesPlaylist *)playlist;
@end


@implementation SEITunesPlaylist

- (id)init {
	FSLog(@"Must initiate SEITunesPlaylist with initInLibrary:name:smart:");
	return nil;
}

- (id)initInLibrary:(SEITunesLibrary *)lib name:(NSString *)initialName type:(SEPlaylistType)t {
	if ((self = [super init])) {
		library = lib;
		[library addPlaylist:self];
		name = [initialName retain];
		type = t;
		tracks = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[name release];
	[tracks release];
	
	[super dealloc];
}

- (NSString *)name {
	return name;
}

- (SEPlaylistType)type {
	return type ;
}

- (id <SELibrary>)library {
	return library;
}

- (void)addTrack:(id <SETrack>)track {
	[tracks addObject:track];
}
- (void)removeTrack:(id <SETrack>)track {
	[tracks removeObjectIdenticalTo:track];
}

- (NSArray *)tracks {
	return tracks;
}



@end
