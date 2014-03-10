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

#import "SEPhasedConsumer.h"

@interface SEPhasedConsumer (PRIVATE)
- (SEPhasedConsumer *)previousPhase;
- (void)setPreviousPhase:(SEPhasedConsumer *)phase;
- (void)setNextPhase:(SEPhasedConsumer *)phase;
@end

@implementation SEPhasedConsumer

- (id)init {
	return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id)del {
	return [self initWithDelegate:del previousPhase:nil];
}

- (id)initWithDelegate:(id)del previousPhase:(SEPhasedConsumer *)phase {
	if ((self = [super initWithDelegate:del])) {
		MPCreateSemaphore(UINT_MAX, 0, &semaphore);
		[phase setNextPhase:self];
		[self setPreviousPhase:phase];
	}
	return self;
}

- (void)dealloc {
	MPSignalSemaphore(semaphore); // allow worker thread to exit
	MPDeleteSemaphore(semaphore);
	
	[previousPhase release];	
	[super dealloc];
}

- (SEPhasedConsumer *)previousPhase {
	return previousPhase;
}

- (void)setPreviousPhase:(SEPhasedConsumer *)phase {
	if (previousPhase != phase) {
		[previousPhase release];
		previousPhase = [phase retain];
	}
}

- (void)setNextPhase:(SEPhasedConsumer *)phase {
	nextPhase = phase;
}

- (void)cancel {
	[super cancel];
	MPDeleteSemaphore(semaphore);
	MPCreateSemaphore(UINT_MAX, 0, &semaphore);
	[nextPhase cancel];
}

- (void)addObjects:(NSArray *)newObjects {		
	[super addObjects:newObjects];		
	[nextPhase addObjects:newObjects];
}

- (BOOL)iterateOverObject:(id)object {
	// wait on the previous phase
	if (previousPhase) { MPWaitOnSemaphore(semaphore, kDurationForever); }
	BOOL complete = [super iterateOverObject:object];	
	if (complete && nextPhase && [nextPhase shouldProcessObject:object]) {
		MPSignalSemaphore(nextPhase->semaphore);
	} else if (!complete && previousPhase) {
		// give another chance to process this object
		MPSignalSemaphore(semaphore);
	}
	return complete;
	
}

@end
