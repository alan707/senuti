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

#import "SEThreadedTrackAdder.h"
#import "SECopyController.h"
#import "SEApplescriptController.h"
#import "SEITunesAdvancedPreferencesViewController.h"

#import "SEObject.h"
#import "SECopyTrack.h"
#import "SEPlaylist.h"
#import "SELibrary.h"

@interface SEThreadedTrackAdder (PRIVATE)
- (BOOL)shouldMakeReference:(SECopyTrack *)track;
- (NSDictionary *)_processObject:(SECopyTrack *)track;
@end

@implementation SEThreadedTrackAdder

- (id)initWithDelegate:(id)del previousPhase:(SEPhasedConsumer *)phase {
	if ((self = [super initWithDelegate:del previousPhase:phase])) {
		script = [[[NSBundle mainBundle] pathForResource:@"itunes" ofType:@"scpt"] retain];
		duplicatedTracks = [[NSMutableSet alloc] init];
		allowStartupDelay = TRUE;
	}
	return self;
}

- (void)dealloc {
	[duplicatedTracks release];
	[script release];
	
	[super dealloc];
}

- (BOOL)shouldMakeReference:(SECopyTrack *)track {
	return ([track reference] &&
			[track destinationPlaylist] &&
			[[track reference] library] == [[track destinationPlaylist] library]);
}

- (void)setupObject:(SECopyTrack *)track {
	if ([track destinationPlaylist]) {
		// set up duplicated tracks
		if (![self shouldMakeReference:track]) {		
			id <SETrack> newTrack = [[track originTrack] duplicateIntoLibrary:[[track destinationPlaylist] library]];
			[[track originTrack] addDuplicateTrack:newTrack];
			[track setDuplicateTrack:newTrack];
			[duplicatedTracks addObject:track];
		}
	}		
}

- (BOOL)shouldProcessObject:(SECopyTrack *)track {
	return ([track destinationPlaylist] != nil);
}

- (void)willCancel {

	// remove any unprocessed duplicated tracks
	// from their origin since they won't ever
	// become real tracks
	
	NSSet *removing;
	@synchronized(duplicatedTracks) {
		removing = [duplicatedTracks copy];
		[duplicatedTracks removeAllObjects];
	}
	
	NSEnumerator *trackEnumerator = [removing objectEnumerator];
	SECopyTrack *track;
	while (track = [trackEnumerator nextObject]) {
		id <SETrack> newTrack = [track duplicateTrack];
		[[track originTrack] removeDuplicateTrack:newTrack];
	}
}

- (void)consumerWillSleep {

#ifdef DEBUG
	NSSet *checking;
	@synchronized(duplicatedTracks) {
		checking = [duplicatedTracks copy];
	}
	
	int count = 0;
	NSEnumerator *trackEnumerator = [checking objectEnumerator];
	SECopyTrack *track;
	while (track = [trackEnumerator nextObject]) {
		if ([[[track originTrack] duplicateTracks] containsObject:[track duplicateTrack]] && ![[track duplicateTrack] persistentID]) {
			count++;
		}
	}
	
	if (count) {
		FSLog(@"There were %i tracks that weren't cleaned up properly", count);
	}
#endif
	
	// clear list of duplicated tracks
	// whenever the consumer is finished
	@synchronized(duplicatedTracks) {
		[duplicatedTracks removeAllObjects];
	}
	[super consumerWillSleep];
}

- (BOOL)processObject:(SECopyTrack *)track {
	int tries = 3;
	BOOL complete = YES;
	
	// applescript sometimes fails randomly
	// so try multiple times
	NSDictionary *error;
	while (((error = [self _processObject:track]) != nil) && (tries-- > 0)) {
		if ([[error objectForKey:NSAppleScriptErrorNumber] intValue] == -1712) {
			// notify copy controller to display an alert (on the main thread)
			[[[SEObject sharedSenutiInstance] copyController] performSelectorOnMainThread:@selector(cancelCopying:) withObject:self waitUntilDone:YES];
			error = nil;
			complete = NO;
			break;
		} else {
			FSLog(@"AppleScriptError: making more tries after: %@", error);
		}
	}
	
	if (error) {
		[NSException raise:@"AppleScriptError" format:@"applescript failed with error %@", error];
	}
	return complete;
}

- (NSDictionary *)_processObject:(SECopyTrack *)track {
	
	// don't need to do any adding if the track isn't
	// being added anywhere, but the dupicate does need
	// to be removed
	if (![track destinationPlaylist]) {
		[[track originTrack] removeDuplicateTrack:[track duplicateTrack]];
		return nil;
	}
	
	NSDictionary *errorInfo = nil;
	NSAppleEventDescriptor *scriptResult = nil;

	NSMutableArray *metadataValues = [NSMutableArray array];
	NSMutableArray *metadataKeys = [NSMutableArray array];

	// build metdata info
	if ([track copyMetadata]) {
		NSArray *defaultKeys = [[NSUserDefaults standardUserDefaults] objectForKey:SECopyITunesMetadataPreferenceKey];
		NSEnumerator *defaultKeyEnumerator = [defaultKeys objectEnumerator];
		
		NSString *key;
		while (key = [defaultKeyEnumerator nextObject]) {
			id object = [(NSObject *)[track originTrack] valueForKey:key];
			if (object) {
				[metadataKeys addObject:key];
				[metadataValues addObject:object];
			}
		}		
	}
	
	NSString *destinationPlaylistName = [[track destinationPlaylist] name];
	if ([[[track destinationPlaylist] library] masterPlaylist] == [track destinationPlaylist]) {
		// no name when adding to the master playlist
		destinationPlaylistName = @"";
	}
	
	if ([self shouldMakeReference:track]) {

		// run the script
		// --------------------------------------------------------
		NSArray *arguments = [NSArray arrayWithObjects:
			destinationPlaylistName,
			[[track reference] persistentID],
			metadataKeys,
			metadataValues,
			[NSNumber numberWithBool:allowStartupDelay],
			nil];

		FSAppleScriptClient *client = [[[SEObject sharedSenutiInstance] applescriptController] runner];
		scriptResult = [client run:script
						  function:@"add_reference"
						 arguments:arguments
							 error:&errorInfo];

		// add to the propper location
		if (scriptResult) {
			[[track destinationPlaylist] addTrack:[track reference]];
		}
	} else {

		BOOL isDir;
		if (![track destinationPath] ||
			![[NSFileManager defaultManager] fileExistsAtPath:[track destinationPath] isDirectory:&isDir] ||
			isDir) {
			
			[[track originTrack] removeDuplicateTrack:[track duplicateTrack]];
			return nil;
		}
		
		NSArray *arguments = [NSArray arrayWithObjects:
			destinationPlaylistName,
			[track destinationPath],
			metadataKeys,
			metadataValues,
			[NSNumber numberWithBool:allowStartupDelay],
			nil];
		allowStartupDelay = FALSE; // only allow startup delay once
		
		// run the script
		// --------------------------------------------------------
		FSAppleScriptClient *client = [[[SEObject sharedSenutiInstance] applescriptController] runner];
		scriptResult = [client run:script
						  function:@"add_song"
						 arguments:arguments
							 error:&errorInfo];

		// add to the propper location
		if (scriptResult) {			
			NSString *persistentID = [[scriptResult descriptorAtIndex:1] stringValue]; // 1 based indexing
			NSString *resultPath = [[scriptResult descriptorAtIndex:2] stringValue];
			
			id <SETrack> newTrack = [track duplicateTrack];
			[newTrack setPersistentID:persistentID];
			[[track originTrack] removeDuplicateTrack:newTrack];
			[[track originTrack] addSimilarTrack:newTrack];
			[newTrack addSimilarTrack:[track originTrack]];
			
			// add to the playlist as well
			// as the library (in memory)
			[[track destinationPlaylist] addTrack:newTrack];
			[[[track destinationPlaylist] library] addTrack:newTrack];

			// update things like destination path and whatever
			// else would change when adding to a different device
			[newTrack setPath:resultPath];
						
			// check to see if a duplicate was created, and if so, trash the one
			// that wasn't added to iTunes
			if (![resultPath hasPrefix:[track destinationRoot]] && // track was moved outside of destination root
				![[track destinationPath] isEqualToString:[[track originTrack] path]]) { // track file isn't the same as the original
				FSDLog(@"Removing duplicated file at %@", [track destinationPath]);
				[[NSFileManager defaultManager] removeFileAtPath:[track destinationPath] handler:nil];
			}
		}
	}

	if (scriptResult) { return nil; }
	else { return errorInfo; }
}

@end
