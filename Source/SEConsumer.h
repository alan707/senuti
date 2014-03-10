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

/* An abstract threading class that consumes
 * arrays of objects and allows subclasses
 * to process each object individually without
 * worrying about threading issues */

#import "SELooper.h"

@interface SEConsumer : SELooper {
	MPSemaphoreID processSemaphore;
	
	BOOL isWorking;
	NSTimeInterval delayInterval;
	NSDate *lastNotify;
	int completedCount;
	int observingCompletedCount;
	int inProgressCount;
	id currentObject;
	id mostRecentObject;
	
	id delegate;
	NSMutableArray *objects;
	NSArray *activeObjects;
	int currentIndex;
}

- (id)initWithDelegate:(id)delegate;
- (void)addObjects:(NSArray *)objects;
- (void)cancel; // just removes all objects in progress
- (void)abort; // after called, this consumer is no longer usable
			   // in addition, no more delegate notification will be sent

// The update delay time affects how often
// the completed count will get updated
// so that observers won't be constantly
// notified of the changing count when
// the consumer processes objects quickly
- (void)setUpdateDelayMinTime:(NSTimeInterval)time;
- (int)completedCount; // Thread Safe
- (int)inProgressCount; // Thread Safe

- (BOOL)isWorking; // Thread Safe
- (id)currentObject; // Thread Safe
- (id)mostRecentObject;

// For subclassers to implement
- (void)setupObject:(id)object;	// Performed on all objects (regarless of what shouldProcessObject
								// returns) before anything happens.  This method may be destructive.

- (BOOL)processObject:(id)object;
- (BOOL)shouldProcessObject:(id)object; // Before processing, check to see if the object should be processed...
										// this method is called multiple times and should not be destructive.
- (void)consumerWillSleep;
- (void)consumerDidWake;
- (void)willCancel;

// For subclassers to override
- (BOOL)iterateOverObject:(id)transaprent; // Returns whether the object completed or not

@end

@interface NSObject (SEConsumerDelegate)
- (void)consumerDidStart:(SEConsumer *)consumer;
- (void)consumerDidFinish:(SEConsumer *)consumer;
@end
