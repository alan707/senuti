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

#import "SEBaseLibrary.h"
#import "SELibrary.h"
#import "SETrack.h"

@implementation SEBaseLibrary

- (id)init {
	if ((self = [super init])) {
		tracks = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	// remove all similar tracks
	NSEnumerator *tracksEnumerator, *similarTracksEnumerator;
	id <SETrack> track, similarTrack;
	tracksEnumerator = [[(id <SELibrary>)self tracks] objectEnumerator];
	while (track = [tracksEnumerator nextObject]) {
		similarTracksEnumerator = [[track similarTracks] objectEnumerator];
		while (similarTrack = [similarTracksEnumerator nextObject]) {
			[similarTrack removeSimilarTrack:track];
		}
	}
		
	[tracks release];
	[super dealloc];
}

- (BOOL)canPlayAudio {
	return NO;
}

- (void)addTrack:(id <SETrack>)track {
	[tracks addObject:track];
}

- (NSArray *)tracks {
	return tracks;
}

@end
