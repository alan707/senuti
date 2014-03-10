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

#import "SECopyTrack.h"
#import "SELibrary.h"
#import "SEPlaylist.h"

@implementation SECopyTrack

+ (NSArray *)copyTracksFromArray:(NSArray *)standardTracks {
	NSMutableArray *tracks = [NSMutableArray array];
	id <SETrack> track;
	NSEnumerator *trackEnumerator = [standardTracks objectEnumerator];
	while (track = [trackEnumerator nextObject]) {
		[tracks addObject:[SECopyTrack trackWithOrigin:track]];
	}
	return [tracks copy];
}

+ (id)trackWithOrigin:(id <SETrack>)track {
	return [[[self alloc] initWithOrigin:track] autorelease];
}

- (id)init {
	FSLog(@"Must initiate SECopyTrack with initWithOriginalTrack:");
	return nil;
}

- (id)initWithOrigin:(id <SETrack>)track {
	if (self = [super init]) {
		origTrack = [track retain];
		copyMetadata = TRUE;
	}
	return self;
}

- (void)dealloc {
	[destinationPath release];
	[destinationRoot release];
	[destinationPlaylist release];
	[reference release];
	[origTrack release];
	[dupTrack release];
	[super dealloc];
}

- (id <SETrack>)originTrack {
	return origTrack;
}

- (id <SETrack>)reference {
	return reference;
	
}
- (void)setReference:(id <SETrack>)track {
	if (track != reference) {
		[reference release];
		reference = [track retain];
	}
}

- (id <SETrack>)duplicateTrack {
	return dupTrack;
}
- (void)setDuplicateTrack:(id <SETrack>)track {
	if (track != dupTrack) {
		[dupTrack release];
		dupTrack = [track retain];
	}	
}

- (BOOL)organize {
	return organize;
}
- (void)setOrganize:(BOOL)flag {
	organize = flag;
}

- (BOOL)copyMetadata {
	return copyMetadata;
}
- (void)setCopyMetadata:(BOOL)flag {
	copyMetadata = flag;
}

- (SEDuplicateHandlingType)duplicateHandling {
	return duplicateHandling;
}
- (void)setDuplicateHandling:(SEDuplicateHandlingType)type {
	duplicateHandling = type;
}

- (NSString *)destinationRoot {
	return destinationRoot;
}

- (void)setDestinationRoot:(NSString *)path {
	if (path != destinationRoot) {
		[destinationRoot release];
		destinationRoot = [path retain];
	}
}

- (NSString *)destinationPath {
	return destinationPath;
}

- (void)setDestinationPath:(NSString *)path {
	if (path != destinationPath) {
		[destinationPath release];
		destinationPath = [path retain];
	}
}

- (id <SEPlaylist>)destinationPlaylist {
	return destinationPlaylist;
}

- (void)setDestinationPlaylist:(id <SEPlaylist>)playlist {
	if (playlist != destinationPlaylist) {
		[destinationPlaylist release];
		destinationPlaylist = [playlist retain];
	}
}

@end
