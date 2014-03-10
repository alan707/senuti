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

#import "SELibraryController.h"
#import <CoreServices/CoreServices.h>
#import <Libxpod/LXMobile.h>

#import "SEIPodLibrary.h"
#import "SEITunesLibrary.h"
#import "SELibrary.h"
#import "SEPlaylist.h"
#import "SETrack.h"
#import "SEComparingPreferencesViewController.h"

#pragma mark fetcher interface
// ----------------------------------------------------------------------------------------------------
// fetcher interface
// ----------------------------------------------------------------------------------------------------

typedef enum _SELibraryFetcherType {
	SEITunesLibraryFetcherType,
	SEIPodLibraryFetcherType
} SELibraryFetcherType;


@class SELibraryFetcher;
@protocol SELibraryFetcherDelegate
- (void)fetcher:(SELibraryFetcher *)fetcher didFetchLibrary:(id <SELibrary>)library;
- (void)fetcherDidFinish:(SELibraryFetcher *)fetcher; // when called, the fetcher is no longer useable
													  // you can't add more tracks to it... they won't get
													  // processed.
@end

@interface SELibraryFetcher : SEObject {
	id delegate;
	SELibraryFetcherType type;	
	NSMutableArray *libraries;
	NSMutableArray *objects;
	MPSemaphoreID semaphore;
	BOOL canAddObjects;
}

- (id)initWithDelegate:(id)del
		   libraryType:(SELibraryFetcherType)type
			   objects:(NSArray *)objects;

- (BOOL)addObjects:(NSArray *)objects; // strings are paths to load,
									   // also can add LXMobile objects
- (NSArray *)libraries; // this method is provided so that the calling
						// thread will block until the fetcher is finished
						// retreiving the library
@end

#pragma mark cross referencer interface
// ----------------------------------------------------------------------------------------------------
// cross referencer interface
// ----------------------------------------------------------------------------------------------------

@class SELibraryCrossReferencer;
@protocol SELibraryCrossReferencerDelegate
- (void)crossReferencer:(SELibraryCrossReferencer *)crossReferencer didCross:(id <SELibrary>)firstLibrary with:(id <SELibrary>)secondLibrary;
@end

@interface SELibraryCrossReferencer : NSObject {
	id delegate;
	id <SELibrary> library;
	NSSet *crossLibraries;
}
+ (id)startWithDelegate:(id)delegate cross:(id <SELibrary>)library withLibraries:(NSSet *)libraries;
- (id)initWithDelegate:(id)delegate cross:(id <SELibrary>)library withLibraries:(NSSet *)libraries;
@end

#pragma mark controller private interface / implementaiton
// ----------------------------------------------------------------------------------------------------
// controller private interface / implementaiton
// ----------------------------------------------------------------------------------------------------

@interface SELibraryController (PRIVATE)
- (NSSet *)librariesIncludingITunes:(BOOL)flag;
- (void)setITunesLibrary:(SEITunesLibrary *)lib;
- (void)setHasIPods:(BOOL)flag;
- (void)addIPod:(id <SELibrary>)ipods;
- (void)removeIPod:(id <SELibrary>)iPod;
- (void)iPodMounted:(NSNotification *)notification;
- (void)iPodRemoved:(NSNotification *)notification;
- (void)mobileConnected:(NSNotification *)notification;
- (void)mobileDisconnected:(NSNotification *)notification;
@end

@implementation SELibraryController

- (void)controllerDidLoad {
	iPodLibraries = [[NSMutableSet alloc] init];
	crossReferenceObservers = [[NSMutableSet alloc] init];
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(iPodMounted:) name:NSWorkspaceDidMountNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(iPodRemoved:) name:NSWorkspaceDidUnmountNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mobileConnected:) name:LXMobileDeviceConnectedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mobileDisconnected:) name:LXMobileDeviceDisconnectedNotification object:nil];

	[LXMobile beginWatch];

#ifdef RELEASE
	NSArray *possible = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
#else
	NSArray *possible = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
#endif
	
	// check to see if it looks like they have an iPod plugged in
	// at the launch of the application
	NSEnumerator *possibleEnumerator = [possible objectEnumerator];
	NSString *path;
	while (path = [possibleEnumerator nextObject]) {
		if ([SEIPodLibrary looksLikeIPod:path]) {
			[self setHasIPods:YES];
			break;
		}
	}
	
	iPodLibraryFetcher = [[SELibraryFetcher alloc] initWithDelegate:self libraryType:SEIPodLibraryFetcherType objects:possible];
	iTunesLibraryFetcher = [[SELibraryFetcher alloc] initWithDelegate:self libraryType:SEITunesLibraryFetcherType objects:nil];	
}

- (void)controllerWillClose {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

	[iPodLibraries release];
	iPodLibraries = nil;
	
	[crossReferenceObservers release];
	crossReferenceObservers = nil;
	
	[iTunesLibrary release];
	iTunesLibrary = nil;
}



- (void)eject:(SEIPodLibrary *)library {
	if ([library isKindOfClass:[SEIPodLibrary class]] &&
		[(SEIPodLibrary *)library mobile]) { [self removeIPod:library]; }
	else { [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:[library iPodPath]]; }
}

- (NSSet *)librariesIncludingITunes:(BOOL)flag {
	NSMutableSet *libraries = [NSMutableSet set];
	@synchronized(self) {
		[libraries unionSet:iPodLibraries];
		if (flag && [self iTunesLibrary] && [[self iTunesLibrary] masterPlaylist]) {
			[libraries addObject:[self iTunesLibrary]];
		}
	}
	return libraries;
}

- (SEITunesLibrary *)iTunesLibrary {
	return iTunesLibrary;
}

- (void)setITunesLibrary:(SEITunesLibrary *)lib {
	if (lib != iTunesLibrary) {
		NSSet *libraries = [self librariesIncludingITunes:NO];
		if ([libraries count]) {
			[SELibraryCrossReferencer startWithDelegate:self cross:lib withLibraries:libraries];
		}		
		
		[iTunesLibrary autorelease];
		iTunesLibrary = [lib retain];
	}
}

- (NSSet *)iPodLibraries {
	return iPodLibraries;
}

- (void)addIPod:(id <SELibrary>)iPod {
	NSSet *libraries = [self librariesIncludingITunes:YES];
	if ([libraries count]) {
		[SELibraryCrossReferencer startWithDelegate:self cross:iPod withLibraries:libraries];
	}

	[self willChangeValueForKey:@"iPodLibraries" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:iPod]];
	[iPodLibraries addObject:iPod];
	[self didChangeValueForKey:@"iPodLibraries" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:iPod]];

	if ([iPodLibraries count]) { [self setHasIPods:TRUE]; }
}

- (void)removeIPod:(id <SELibrary>)iPod {
	[self willChangeValueForKey:@"iPodLibraries" withSetMutation:NSKeyValueMinusSetMutation usingObjects:[NSSet setWithObject:iPod]];
	[iPodLibraries removeObject:iPod];
	[self didChangeValueForKey:@"iPodLibraries" withSetMutation:NSKeyValueMinusSetMutation usingObjects:[NSSet setWithObject:iPod]];
	
	if (![iPodLibraries count]) { [self setHasIPods:FALSE];	}
}

- (void)iPodMounted:(NSNotification *)notification {
	NSString *path = [[notification userInfo] objectForKey:@"NSDevicePath"];
	if (![(SELibraryFetcher *)iPodLibraryFetcher addObjects:[NSArray arrayWithObject:path]]) {
		iPodLibraryFetcher = [[SELibraryFetcher alloc] initWithDelegate:self
															libraryType:SEIPodLibraryFetcherType
																objects:[NSArray arrayWithObject:path]];
	}	
}

- (void)iPodRemoved:(NSNotification *)notification {
	NSString *path = [[notification userInfo] objectForKey:@"NSDevicePath"];
	SEIPodLibrary *iPodLibrary;
	NSEnumerator *libraryEnumerator = [iPodLibraries objectEnumerator];
	while (iPodLibrary = [libraryEnumerator nextObject]) {
		if ([[iPodLibrary iPodPath] isEqualToString:path]) {
			[self removeIPod:iPodLibrary];
			break;
		}
	}
}

- (void)mobileConnected:(NSNotification *)notification {
	FSDLog(@"connected");
	LXMobile *mobile = [notification object];
	if (![(SELibraryFetcher *)iPodLibraryFetcher addObjects:[NSArray arrayWithObject:mobile]]) {
		FSDLog(@"adding iPod new fetcher");
		iPodLibraryFetcher = [[SELibraryFetcher alloc] initWithDelegate:self
															libraryType:SEIPodLibraryFetcherType
																objects:[NSArray arrayWithObject:mobile]];
	}	
}

- (void)mobileDisconnected:(NSNotification *)notification {
	LXMobile *mobile = [notification object];
	SEIPodLibrary *iPodLibrary;
	NSEnumerator *libraryEnumerator = [iPodLibraries objectEnumerator];
	while (iPodLibrary = [libraryEnumerator nextObject]) {
		if ([iPodLibrary mobile] == mobile) {
			[self removeIPod:iPodLibrary];
			break;
		}
	}	
}

- (void)setHasIPods:(BOOL)flag {
	hasIPods = flag;
}

- (BOOL)hasIPods {
	return hasIPods;
}

#pragma mark fetcher delegate
// ----------------------------------------------------------------------------------------------------
// fetcher delegate
// ----------------------------------------------------------------------------------------------------

- (void)fetcher:(SELibraryFetcher *)fetcher didFetchLibrary:(id <SELibrary>)library {
	if (fetcher == iTunesLibraryFetcher) { [self setITunesLibrary:(SEITunesLibrary *)library]; }
	else if (fetcher == iPodLibraryFetcher) { [self addIPod:library]; }
}

- (void)fetcherDidFinish:(SELibraryFetcher *)fetcher {
	FSDLog(@"fetcher finished");
	if (fetcher == iTunesLibraryFetcher) {
		// no longer using this fetcher
		[iTunesLibraryFetcher release];
		iTunesLibraryFetcher = nil;
	} else if (fetcher == iPodLibraryFetcher) {
		// no longer using this fetcher
		[iPodLibraryFetcher release];
		iPodLibraryFetcher = nil;		
	}
}

#pragma mark cross referencer delegate and observer
// ----------------------------------------------------------------------------------------------------
// cross referencer delegate and observer
// ----------------------------------------------------------------------------------------------------

- (void)crossReferencer:(SELibraryCrossReferencer *)crossReferencer didCross:(id <SELibrary>)firstLibrary with:(id <SELibrary>)secondLibrary {
	NSEnumerator *crossReferenceObserverEnumerator = [crossReferenceObservers objectEnumerator];
	id <SECrossReferenceObserver> observer;
	while (observer = [crossReferenceObserverEnumerator nextObject]) {
		[observer didCross:firstLibrary with:secondLibrary];
	}
}

- (void)addCrossReferenceObserver:(id <SECrossReferenceObserver>)observer {
	[crossReferenceObservers addObject:observer];
}
- (void)removeCrossReferenceObserver:(id <SECrossReferenceObserver>)observer {
	[crossReferenceObservers removeObject:observer];
}

@end

#pragma mark cross referencer
// ----------------------------------------------------------------------------------------------------
// cross referencer
// ----------------------------------------------------------------------------------------------------

@interface SELibraryCrossReferencer (PRIVATE)
- (void)crossLibraries;
- (void)informDelegateOfCrossReference:(NSArray *)libraries;
@end


@implementation SELibraryCrossReferencer

+ (id)startWithDelegate:(id)del cross:(id <SELibrary>)lib withLibraries:(NSSet *)libraries {
	return [[[self alloc] initWithDelegate:del cross:lib withLibraries:libraries] autorelease];
}

- (id)init {
	FSLog(@"Must initiate SELibraryCrossReferencer with initWithDelegate:cross:withLibraries:");
	return nil;
}

- (id)initWithDelegate:(id)del cross:(id <SELibrary>)lib withLibraries:(NSSet *)libraries {
	if (self = [super init]) {
		delegate = del;		
		library = [lib retain];
		crossLibraries = [libraries retain];
		
		[NSThread detachNewThreadSelector:@selector(crossLibraries) toTarget:self withObject:nil];
	}
	return self;
}

- (void)dealloc {
	delegate = nil;
	[library release];
	[crossLibraries release];
	[super dealloc];
}

- (NSString *)keyForTrack:(id <SETrack>)track builtFrom:(NSArray *)keys {
	NSMutableString *result = [NSMutableString string];
	NSEnumerator *keyEnumerator = [keys objectEnumerator];
	NSString *key;
	while (key = [keyEnumerator nextObject]) {
		[result appendFormat:@"-%@", [(NSObject *)track valueForKey:key]];
	}
	return result;
}

- (void)crossReferenceLibrary:(id <SELibrary>)lib1 with:(id <SELibrary>)lib2 {
	
	BOOL exact = [[NSUserDefaults standardUserDefaults] boolForKey:SEExactComparisonPreferenceKey];
	NSArray *compareKeys = [[NSUserDefaults standardUserDefaults] objectForKey:SEComparisonFieldsPreferenceKey];
	
#ifdef DEBUG
	NSDate *start = [NSDate date];
#endif
	NSMutableArray *tracks1 = [[[[lib1 masterPlaylist] tracks] mutableCopy] autorelease];
	NSMutableArray *tracks2 = [[[[lib2 masterPlaylist] tracks] mutableCopy] autorelease];
	
	id <SETrack> iterateTrack, matchTrack;
	NSEnumerator *tracksEnumerator, *matchedTrackEnumerator;
	NSArray *matchedTracks;
	
	NSMutableDictionary *cross = [NSMutableDictionary dictionary];
	
	tracksEnumerator = [tracks1 objectEnumerator];
	while (iterateTrack = [tracksEnumerator nextObject]) {
		NSString *key = (exact ? [iterateTrack persistentID] : [self keyForTrack:iterateTrack builtFrom:compareKeys]);
		NSMutableArray *all = [cross objectForKey:key];
		if (!all) {
			all = [NSMutableArray array];
			[cross setObject:all forKey:key];
		}
		[all addObject:iterateTrack];
	}
	
	tracksEnumerator = [tracks2 objectEnumerator];
	while (iterateTrack = [tracksEnumerator nextObject]) {
		NSString *key = (exact ? [iterateTrack persistentID] : [self keyForTrack:iterateTrack builtFrom:compareKeys]);
		matchedTracks = [cross objectForKey:key];
		if (matchedTracks) {
			matchedTrackEnumerator = [matchedTracks objectEnumerator];
			while (matchTrack = [matchedTrackEnumerator nextObject]) {
				[matchTrack addSimilarTrack:iterateTrack];
				[iterateTrack addSimilarTrack:matchTrack];
			}
		}
	}
	
	[self performSelectorOnMainThread:@selector(informDelegateOfCrossReference:) withObject:[NSArray arrayWithObjects:lib1, lib2, nil] waitUntilDone:NO];
	FSDLog(@"Crossreference of %@ with %@ took %f seconds.", [lib1 name], [lib2 name], [[NSDate date] timeIntervalSinceDate:start]);
}

- (void)crossLibraries {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	id <SELibrary> libraryInSet;
	NSEnumerator *enumerator = [crossLibraries objectEnumerator];
	while (libraryInSet = [enumerator nextObject]) {
		[self crossReferenceLibrary:library with:libraryInSet];
	}
	
	[pool release];	
}

- (void)informDelegateOfCrossReference:(NSArray *)libraries {
	// on main thread
	id firstLibrary = [libraries objectAtIndex:0];
	id secondLibrary = [libraries objectAtIndex:1];
	[delegate crossReferencer:self
					 didCross:firstLibrary
						 with:secondLibrary];
}

@end

#pragma mark fetcher
// ----------------------------------------------------------------------------------------------------
// fetcher
// ----------------------------------------------------------------------------------------------------

@interface SELibraryFetcher (PRIVATE)
- (void)fetchLibraries;
- (void)informDelegateOfLibrary:(id <SELibrary>)lib;
@end

@implementation SELibraryFetcher

- (id)init {
	FSLog(@"Must initiate SELibraryFetcher with initWithDelegate:libraryType:path:");
	return nil;
}

- (id)initWithDelegate:(id)del
		   libraryType:(SELibraryFetcherType)t
			   objects:(NSArray *)objs {
	if ((self = [super init])) {
		delegate = del;
		type = t;
		objects = [[NSMutableArray alloc] initWithArray:objs];
		libraries = [[NSMutableArray alloc] init];
		canAddObjects = TRUE;
		MPCreateSemaphore(1,0,&semaphore);
		
		[NSThread detachNewThreadSelector:@selector(fetchLibraries) toTarget:self withObject:nil];
	}
	return self;
}

- (void)dealloc {
	delegate = nil;
	[libraries release];
	libraries = nil;
	[objects release];
	objects = nil;
	
	MPSignalSemaphore(semaphore); // don't leave a deadlock
	MPDeleteSemaphore(semaphore);
	
	[super dealloc];
}

- (void)fetchLibraries {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if (type == SEITunesLibraryFetcherType) {
		NSAssert([objects count] == 0, @"paths should not be given when the fetcher type is for iTunes");
		id <SELibrary> library = [[SEITunesLibrary alloc] init];
		if (library) {
			[libraries addObject:library];
			[self performSelectorOnMainThread:@selector(informDelegateOfLibrary:) withObject:library waitUntilDone:NO];
		}		
	} else if (type == SEIPodLibraryFetcherType) {
		while (TRUE) {
			NSObject *object;
			NSEnumerator *objectEnumerator;
			@synchronized(self) {
				if ([objects count] == 0) { canAddObjects = FALSE; break; }
				else {
					objectEnumerator = [[[objects copy] autorelease] objectEnumerator];
					[objects removeAllObjects];
				}
			}
			
			while (object = [objectEnumerator nextObject]) {
				id <SELibrary> library = nil;
				if ([object isKindOfClass:[NSString class]]) {
					library = [[[SEIPodLibrary alloc] initWithIPodAtPath:(NSString *)object] autorelease];
				} else if ([object isKindOfClass:[LXMobile class]]) {
					library = [[[SEIPodLibrary alloc] initWithMobile:(LXMobile *)object] autorelease];
				}
				if (library) {
					[libraries addObject:library];
					[self performSelectorOnMainThread:@selector(informDelegateOfLibrary:) withObject:library waitUntilDone:NO];
				}
			}
		}
	} else {
		[NSException raise:@"InvalidArgument" format:@"Type argument to SELibraryFetcher invalid"];
	}
	
	MPSignalSemaphore(semaphore); // libraries retrieved, okay
								  // to return on main thread now
		
	// inform delegate that everything's finished
	[delegate performSelectorOnMainThread:@selector(fetcherDidFinish:) withObject:self waitUntilDone:NO];
	[pool release];	
}

// returns whether the objects were actually added or not
// if this returns false, these objects will not be processed
// and this fetcher will eventually be deallocated, so you
// should create a new fetcher and add the objects to it
- (BOOL)addObjects:(NSArray *)ps {
	FSDLog(@"adding %i objects", [ps count]);
	BOOL added;
	@synchronized(self) {
		if (added = canAddObjects) { [objects addObjectsFromArray:ps]; }
	}
	return added;
}

- (void)informDelegateOfLibrary:(id <SELibrary>)library {
	[delegate fetcher:self didFetchLibrary:library];
}

- (NSArray *)libraries {
	MPWaitOnSemaphore(semaphore,kDurationForever);
	return libraries;
}

@end
