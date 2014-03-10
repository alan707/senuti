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

#import "SEConsumer.h"

@interface SEConsumer (PRIVATE)
- (void)setCurrentObject:(id)object;
- (void)setMostRecentObject:(id)object;
- (void)setIsWorking:(BOOL)flag;
- (void)resetActiveObjects;

- (int)inProgressCount;
- (void)setInProgressCount:(int)count;
- (int)completedCount;
- (void)setCompletedCount:(int)count forceKVONotify:(BOOL)forceKVONotify;
@end

@implementation SEConsumer

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    if ([theKey isEqualToString:@"completedCount"]) { return NO; }
    return [super automaticallyNotifiesObserversForKey:theKey];
}

- (id)init {
	return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id)del {
	if ((self = [super init])) {
		MPCreateSemaphore(1, 0, &processSemaphore);
		objects = [[NSMutableArray alloc] init];
		delegate = del;
	}
	return self;	
}

- (void)dealloc {
	[self setCurrentObject:nil];
	[self setMostRecentObject:nil];
	MPDeleteSemaphore(processSemaphore);
		
	[lastNotify release];
	[objects release];
	[activeObjects release];
	[super dealloc];
}


#pragma mark public information
// ----------------------------------------------------------------------------------------------------
// public information
// ----------------------------------------------------------------------------------------------------

- (void)cancel {
	[self willCancel];
	
	@synchronized(objects) {
		[objects removeAllObjects];
		[activeObjects autorelease];
		activeObjects = nil;	
	}
}

- (void)abort {
	MPSignalSemaphore(processSemaphore); // allow worker thread to exit
	[self cancel];
	[super abort];
}

- (void)setUpdateDelayMinTime:(NSTimeInterval)time {
	delayInterval = time;
}

- (BOOL)isWorking {
	BOOL result;
	@synchronized(self) { result = isWorking; }
	return result;
}

- (void)setIsWorking:(BOOL)flag {
	@synchronized(self) { isWorking = flag; }
	
	if (isWorking) { [delegate performSelectorOnMainThread:@selector(consumerDidStart:)
												withObject:self
											 waitUntilDone:NO]; }
	else { [delegate performSelectorOnMainThread:@selector(consumerDidFinish:)
									  withObject:self
								   waitUntilDone:NO]; }
}

- (int)completedCount {
	int result;
	@synchronized(self) { result = observingCompletedCount; }
	return result;	
}

- (void)setCompletedCount:(int)count forceKVONotify:(BOOL)forceKVONotify {
	completedCount = count;

	NSDate *now = [NSDate date];
	if (forceKVONotify || !lastNotify ||
		([now timeIntervalSinceDate:lastNotify] > delayInterval)) {
		[self willChangeValueForKey:@"completedCount"];
		@synchronized(self) { observingCompletedCount = count; }
		[self didChangeValueForKey:@"completedCount"];

		[lastNotify autorelease];
		lastNotify = [now retain];
	}	
}

- (int)inProgressCount {
	int result;
	@synchronized(self) { result = inProgressCount; }
	return result;
}

- (void)setInProgressCount:(int)count {
	@synchronized(self) { inProgressCount = count; }
}

- (void)addObjects:(NSArray *)addObjects {
	
	int processCount = 0;
	NSObject *obj;
	NSEnumerator *objectEnumerator = [addObjects objectEnumerator];
	while ((obj = [objectEnumerator nextObject])) {
		processCount += [self shouldProcessObject:obj] ? 1 : 0;
		[self setupObject:obj];
	}

	// lock for as little time as possible
	BOOL signal;
	@synchronized(objects) {
		// signal if there aren't any objects only
		signal = [objects count] == 0;
		[objects addObjectsFromArray:addObjects];
	}
	
	// note the count change
	[self setInProgressCount:inProgressCount + processCount];
	
	if (signal) {
		FSDLog(@"%@ starting to process objects", [self class]);
		MPSignalSemaphore(processSemaphore);
	}	
}

- (id)currentObject {
	id value;
	@synchronized(currentObject) { value = [currentObject retain]; }
	return [value autorelease];
}

- (void)setCurrentObject:(id)object {
	@synchronized(currentObject) {
		if (object != currentObject) {
			[currentObject release];
			currentObject = [object retain];
		}
	}
	
	if (object != nil) { [self setMostRecentObject:object]; }
}

- (id)mostRecentObject {
	id value;
	@synchronized(mostRecentObject) { value = [mostRecentObject retain]; }
	return [value autorelease];
}

- (void)setMostRecentObject:(id)object {
	@synchronized(mostRecentObject) {
		if (object != mostRecentObject) {
			[mostRecentObject release];
			mostRecentObject = [object retain];
		}
	}
}


#pragma mark progressing through objects
// ----------------------------------------------------------------------------------------------------
// progressing through objects
// ----------------------------------------------------------------------------------------------------

- (id)activeObject {
	// reset if there aren't any objects in the
	// active list or if we're at the end of the
	// active list	
	int count;
	@synchronized(objects) { count = [activeObjects count]; }
	if (count == 0 || currentIndex >= count) {
		
		[self resetActiveObjects];
		currentIndex = 0;
		
		while (TRUE) {
			@synchronized(objects) { count = [activeObjects count]; }
			if (count) { break; }
			
			[self setInProgressCount:0];
			[self setCompletedCount:0 forceKVONotify:TRUE];
			[self setMostRecentObject:nil];
			FSDLog(@"%@ waiting for objects", [self class]);
			[self consumerWillSleep];
			[self setIsWorking:FALSE];
			MPWaitOnSemaphore(processSemaphore, kDurationForever);
			[self setIsWorking:TRUE];
			[self consumerDidWake];
			[self resetActiveObjects];
		}
		
		// return nil and wait for the next iteration
		// so any abort/pause messages get processed
		return nil;
	} else {
		id result;
		@synchronized(objects) { result = [activeObjects objectAtIndex:currentIndex]; }
		return result;
	}
}

- (void)resetActiveObjects {
	@synchronized(objects) {
		[activeObjects autorelease];
		activeObjects = [objects copy];
		[objects removeAllObjects];
	}
}

- (void)iteration {
	id object = [self activeObject];
	if (object) {
		BOOL objectFinished = [self iterateOverObject:object];	
		if (objectFinished) {
			// only increemnt completed count if this
			// was an object that should have been processed
			if ([self shouldProcessObject:object]) {
				[self setCompletedCount:completedCount + 1 forceKVONotify:FALSE];
			}
			currentIndex++;
		}
	}
}

- (BOOL)iterateOverObject:(id)object {
	if ([self shouldProcessObject:object]) {
		[self setCurrentObject:object];
		BOOL objectFinished = [self processObject:object];
		[self setCurrentObject:nil];
		return objectFinished;
	} else {
		return YES;
	}
}

#pragma mark default implementation for subclasss methods
// ----------------------------------------------------------------------------------------------------
// default implementation for subclasss methods
// ----------------------------------------------------------------------------------------------------

- (void)setupObject:(id)object {}
- (BOOL)processObject:(id)object { return YES; }
- (BOOL)shouldProcessObject:(id)object { return YES; }
- (void)consumerWillSleep {}
- (void)consumerDidWake {}
- (void)willCancel {}

@end

@implementation NSObject (SEConsumerDelegate)
- (void)consumerDidStart:(SEConsumer *)consumer {}
- (void)consumerDidFinish:(SEConsumer *)consumer {}
@end
