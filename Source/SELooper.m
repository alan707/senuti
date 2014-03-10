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

#import "SELooper.h"

@interface SELooper (PRIVATE)
- (void)setState:(SELooperState)state;
@end

@implementation SELooper

- (id)init {
	if ((self = [super init])) {
		state = SELooperFinishedState;
		MPCreateCriticalRegion(&stateChange);
		MPCreateSemaphore(1, 0, &continueSemaphore);
	}
	return self;	
}

- (void)dealloc {
	FSDLog(@"clean exit");
	state = SELooperFinishedState; // allow worker thread to exit 
	MPDeleteCriticalRegion(stateChange);
	MPDeleteSemaphore(continueSemaphore);
	
	[super dealloc];
}

- (void)execute {
	state = SELooperRunningState;
	[NSThread detachNewThreadSelector:@selector(runWorker) toTarget:self withObject:nil];
}

- (void)pause {
	MPEnterCriticalRegion(stateChange, kDurationForever);
	{
		state = SELooperPauseState;
	}
	MPExitCriticalRegion(stateChange);
}

- (void)continue {
	BOOL wasPaused;
	MPEnterCriticalRegion(stateChange, kDurationForever);
	{
		wasPaused = (state == SELooperPauseState);
		state = SELooperRunningState;
	}
	MPExitCriticalRegion(stateChange);
	if (wasPaused) { MPSignalSemaphore(continueSemaphore); }	
}

- (void)abort {
	BOOL wasPaused;
	MPEnterCriticalRegion(stateChange, kDurationForever);
	{
		wasPaused = (state == SELooperPauseState);		
		state = SELooperAbortState;
	}
	MPExitCriticalRegion(stateChange);
	if (wasPaused) { MPSignalSemaphore(continueSemaphore); }		
}

- (void)setState:(SELooperState)newState {
	MPEnterCriticalRegion(stateChange, kDurationForever);
	{
		state = newState;
	}
	MPExitCriticalRegion(stateChange);
}

- (void)runWorker {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL complete = FALSE;	
	[self start];
	
	while (state != SELooperFinishedState) {
		NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
		
		[self iteration];
		
		// pause until told to continue
		if (state == SELooperPauseState) {
			[self willPause];
			MPWaitOnSemaphore(continueSemaphore, kDurationForever);
		}
		// abort
		if (state == SELooperAbortState) {
			[self willAbort];
			complete = TRUE;
		}
		
		[innerPool release];
		if (complete) { break; }
	}
	
	[self end];
	[pool release];
}

- (void)start {}
- (void)iteration {}
- (void)end {}

- (void)willAbort {}
- (void)willPause {}

@end
