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

/* An abstract threading class that loops
 * indefinitely and allows pause, continue, 
 * and abort */

typedef enum _SELooperState {
	SELooperRunningState,
	SELooperPauseState,
	SELooperAbortState,
	SELooperFinishedState
} SELooperState;

@interface SELooper : NSObject {
	MPSemaphoreID continueSemaphore;
	MPCriticalRegionID stateChange;
	SELooperState state;
}

- (void)execute;

- (void)pause;
- (void)continue;
- (void)abort;

// For subclassers to implement
- (void)start; // Called before beginning to loop (once execute is called)
- (void)iteration; // Called each iteration of the loop
- (void)end; // Called after exiting the looping phase (once abort was called)

// For subclassers to override
- (void)willAbort; // Called when an abort is about occur.
- (void)willPause; // Called when a pause is about occur.

@end
