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

#import "SEThreadedTrackPreprocessor.h"

#import "SEInterfaceController.h"
#import "SECopyingPreferenceViewController.h"
#import "SECopyLocationWindowController.h"
#import "SELibraryController.h"

#import "SEObject.h"
#import "SETrack.h"
#import "SELibrary.h"
#import "SEPlaylist.h"
#import "SECopyTrack.h"
#import "SEITunesLibrary.h"
#import "SEITunesPlaylist.h"
#import "SEIPodLibrary.h"

@interface SEPreprocessorContainer (PRIVATE)
- (id <SEPlaylist>)playlist;
- (NSArray *)tracks;
@end

@implementation SEThreadedTrackPreprocessor

- (id)initWithCopier:(SEConsumer *)copy {
	if ((self = [super init])) {
		copier = copy;
	}
	return self;
}

- (void)dealloc {
	copier = nil;
	[super dealloc];
}

- (BOOL)processObject:(SEPreprocessorContainer *)container {

	NSArray *tracks = [container tracks];
	id <SEPlaylist> playlist = [container playlist];
	
	SECopyTrack *track;
	NSEnumerator *tracksEnumerator;
	NSArray *copyTracks = [SECopyTrack copyTracksFromArray:tracks];
	double requiredSpace = 0;
	BOOL needsToEnsureDestination = FALSE;
	
	// other preferences
	SEDuplicateHandlingType duplicateType = [[NSUserDefaults standardUserDefaults] integerForKey:SEDuplicateFileHandlingPreferenceKey];
	BOOL organize = [[NSUserDefaults standardUserDefaults] boolForKey:SEOrganizeCopiedTracksPreferenceKey];
	SEReferenceHandlingType referenceHandling = [[NSUserDefaults standardUserDefaults] integerForKey:SEReferenceHandingPreferenceKey];
	BOOL copyMetadata = [[NSUserDefaults standardUserDefaults] boolForKey:SECopyMetadataPreferenceKey];
	
	// defaults for when adding a track from an iPod
	id defaultAddToPlaylist = nil;
	BOOL addToITunes = [[NSUserDefaults standardUserDefaults] boolForKey:SEAddToITunesPreferenceKey];
	if (addToITunes) {
		SEITunesLibrary *iTunesLibrary = [[[SEObject sharedSenutiInstance] libraryController] iTunesLibrary];
		// check that itunes was really loaded
		if ([iTunesLibrary masterPlaylist]) {
			BOOL addToIPlaylist = [[NSUserDefaults standardUserDefaults] boolForKey:SEAddToPlaylistPreferenceKey];
			if (addToIPlaylist) {
				NSString *playlistName = [[NSUserDefaults standardUserDefaults] objectForKey:SEAddToPlaylistNamedPreferenceKey];
				defaultAddToPlaylist = [[[iTunesLibrary playlists] filter:@selector(name) where:playlistName] firstObject];
				if (!defaultAddToPlaylist && playlistName && ![playlistName isEqualToString:@""]) {
					defaultAddToPlaylist = [[[SEITunesPlaylist alloc] initInLibrary:iTunesLibrary
																			   name:playlistName
																			   type:SEStandardPlaylistType] autorelease];
				}
			} else {
				defaultAddToPlaylist = [iTunesLibrary masterPlaylist];
			}
		}
	}
	
	// calculate destination
	NSString *destination;
	BOOL ask = [[NSUserDefaults standardUserDefaults] boolForKey:SEAskCopyLocationPreferenceKey];
	if (ask) {
		destination = [[SECopyLocationWindowController runWithDefaultLocation:[[NSUserDefaults standardUserDefaults] objectForKey:SECopyLocationPreferenceKey]
															   modalForWindow:[[[SEObject sharedSenutiInstance] interfaceController] mainWindow]] stringByExpandingTildeInPath];
		if (!destination) { return YES; }
	} else {
		destination = [[[NSUserDefaults standardUserDefaults] objectForKey:SECopyLocationPreferenceKey] stringByExpandingTildeInPath];
	}
	
	
	// set information on each track
	tracksEnumerator = [copyTracks objectEnumerator];
	while (track = [tracksEnumerator nextObject]) {
		
		[track setDestinationRoot:destination];
		[track setDestinationPlaylist:playlist];
		[track setDuplicateHandling:duplicateType];
		[track setOrganize:organize];
		
		if ([(NSObject *)[[track originTrack] library] isKindOfClass:[SEIPodLibrary class]]) {
			if (!playlist) { [track setDestinationPlaylist:defaultAddToPlaylist]; }
		}
		
		if (referenceHandling != SECopyFileReferenceType) {
			// check for similar tracks
			id <SETrack> similarTrack;
			NSMutableSet *search = [NSMutableSet set];
			[search unionSet:[[track originTrack] similarTracks]];
			[search unionSet:[[track originTrack] duplicateTracks]];
			NSEnumerator *similarTracksEnumerator = [search objectEnumerator];
			while (similarTrack = [similarTracksEnumerator nextObject]) {
				if ([[track destinationPlaylist] library] == [similarTrack library] &&
					[similarTrack fileExists]) {
					if (referenceHandling == SEReferenceOnlyReferenceType) {
						[track setReference:similarTrack];
						[track setCopyMetadata:copyMetadata];
					}
					
					// don't copy the track
					[track setDestinationRoot:nil];					
					break;
				}
			}
		}		
		
		needsToEnsureDestination = needsToEnsureDestination || [track destinationRoot];
		if ([track destinationRoot] && ![track reference]) {
			requiredSpace += [[track originTrack] size] / 1024.0 / 1024.0;
		}
	}
	
	// check to see if there's enough space for all files to be copied
	if (requiredSpace > [[NSFileManager defaultManager] freeSpaceOnDeviceContainingPath:destination]) {
		while (requiredSpace > [[NSFileManager defaultManager] freeSpaceOnDeviceContainingPath:destination]) {
			FSDLog(@"Not enough space at \"%@\"", destination);
			int alertResult;
			alertResult = NSRunAlertPanel(FSLocalizedString(@"Not enough free disk space", @"Disk full - title"),
										  [NSString stringWithFormat:FSLocalizedString(@"To copy the tracks you requested, %0.2f MB of free disk space is required.  Please free more space or try copying to a different disk.", @"Disk full - message"), requiredSpace],
										  FSLocalizedString(@"Try Again", nil),
										  FSLocalizedString(@"Cancel", nil),
										  nil);
			// stop trying to copy
			if (alertResult == NSAlertAlternateReturn) { return YES; }		
		}		
	}
	
	// safely ensure destination exists
	while (needsToEnsureDestination && ![[NSFileManager defaultManager] safelyEnsurePath:destination]) {
		FSDLog(@"Failed to create copy path \"%@\"", destination);
		int alertResult;
		alertResult = NSRunAlertPanel(FSLocalizedString(@"Unable to create folder", @"iTunes add timeout - title"),
									  [NSString stringWithFormat:FSLocalizedString(@"Senuti was unable to create the folder \"%@\".  This could be because the directory is readonly or because you are trying to copy to an external hard drive which is not present.  You can attempt to create the directory yourself and try again.", @"Cannot create copy directory - message"), destination],
									  FSLocalizedString(@"Try Again", nil),
									  FSLocalizedString(@"Cancel", nil),
									  nil);
		// stop trying to copy
		if (alertResult == NSAlertAlternateReturn) { return YES; }
	}
	
	// actually copy
	[copier addObjects:copyTracks];
	
	return YES;
}

@end


@implementation SEPreprocessorContainer

+ (id)containerForTracks:(NSArray *)theTracks toPlaylist:(id <SEPlaylist>)thePlaylist {
	return [[[self alloc] initForTracks:theTracks toPlaylist:thePlaylist] autorelease];
}

- (id)initForTracks:(NSArray *)theTracks toPlaylist:(id <SEPlaylist>)thePlaylist {
	if ((self = [super init])) {
		tracks = [theTracks retain];
		playlist = [thePlaylist retain];
	}
	return self;
}

- (id <SEPlaylist>)playlist {
	return playlist;
}

- (NSArray *)tracks {
	return tracks;
}

- (void)dealloc {
	[tracks release];
	[playlist release];
	[super dealloc];
}

@end
