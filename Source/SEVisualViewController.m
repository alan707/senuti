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

#import "SEVisualViewController.h"
#import "SEAudioController.h"

#import "SEMainWindow.h"
#import "SETrack.h"
#import "SEPlaylist.h"
#import "SELibrary.h"
#import "SEIPodPlaylist.h"
#import "SETrackProgressView.h"

typedef enum _SEPlayButtonState {
	SEPlayButton,
	SEPauseButton,
	SEStopButton
} SEPlayButtonState;

static void *SEPlayingStateChangeContext = @"SEPlayingStateChangeContext";
static void *SEVolumeChangeContext = @"SEVolumeChangeContext";

@interface SEVisualViewController (PRIVATE)
- (void)updateButtonStates;
- (void)updateVolumeButton;
- (void)startCheckEvent:(NSTimer *)timer;
- (void)checkEvent:(NSEvent *)event;

- (void)scan:(id)sender;

- (void)startProgressPoll;
- (void)stopProgressPoll;
- (void)progressPoll:(NSTimer *)timer;	
@end

@implementation SEVisualViewController

+ (NSString *)nibName {
	return @"VisualView";
}

- (void)awakeFromNib {
	volumeWindow = [[FSHUDWindow alloc] initWithContentRect:NSMakeRect(0, 0, [volumeView frame].size.width, [volumeView frame].size.height) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
	[volumeWindow setHasShadow:TRUE];
	[[volumeWindow contentView] addSubview:volumeView];
	
	[progress setTarget:self];
	[progress setAction:@selector(scan:)];
		
	[[senuti audioController] addObserver:self forKeyPath:@"playing" options:0 context:SEPlayingStateChangeContext];
	[[senuti audioController] addObserver:self forKeyPath:@"paused" options:0 context:SEPlayingStateChangeContext];
	[[senuti audioController] addObserver:self forKeyPath:@"playingPlaylist" options:0 context:SEPlayingStateChangeContext];
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:SESavedVolumeKey options:0 context:SEVolumeChangeContext];
	
	[self updateButtonStates];
	[self updateVolumeButton];
}

- (void)viewDidActivate {
	if ([[[self view] window] isKindOfClass:[SEMainWindow class]]) {
		SEMainWindow *window = (SEMainWindow *)[[self view] window];
		[window setSpacebarTarget:self];
		[window setSpacebarAction:@selector(toggleTrackPlaying:)];
	}
}

- (void)dealloc {
	[self removeControllerObservers];
	
	[playlist release];
	[selectedTrack release];
	[visibleTracks release];
	[super dealloc];
}

- (void)removeControllerObservers {
	if ([self isViewLoaded]) {
		[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:SESavedVolumeKey];
		[[senuti audioController] removeObserver:self forKeyPath:@"playing"];
		[[senuti audioController] removeObserver:self forKeyPath:@"paused"];
		[[senuti audioController] removeObserver:self forKeyPath:@"playingPlaylist"];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SEPlayingStateChangeContext) {
		[self updateButtonStates];
		if ([[senuti audioController] playing]) { [self startProgressPoll]; }
		else { [self stopProgressPoll]; }
	} else if (context == SEVolumeChangeContext) {
		[self updateVolumeButton];
	}
}

- (void)startProgressPoll {
	if (!progressPoll) {
		progressPoll = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(progressPoll:) userInfo:nil repeats:YES];
	}
}

- (void)stopProgressPoll {
	[progressPoll invalidate];
	progressPoll = nil;
	if (![[senuti audioController] paused]) {
		[progress setDoubleValue:0];
	}
}

- (void)progressPoll:(NSTimer *)timer {
	[progress setDoubleValue:[[senuti audioController] progress]];
}

- (void)updateButtonStates {
	
	if (![[playlist library] canPlayAudio]) {
		[audioControls setHidden:YES];
	} else {
		[audioControls setHidden:NO];

		SEPlayButtonState state;
		if ([[senuti audioController] paused]) {
			if ([[senuti audioController] playingPlaylist] != playlist) { state = SEStopButton; }
			else { state = SEPlayButton; }
		} else if ([[senuti audioController] playing]) {
			if ([[senuti audioController] playingPlaylist] != playlist) { state = SEStopButton; }
			else { state = SEPauseButton; }
		} else {
			state = SEPlayButton;
		}
		
		[play setEnabled:TRUE];
		if (state == SEPlayButton) {
			[play setImage:[NSImage imageNamed:@"play"]];
			[play setAlternateImage:[NSImage imageNamed:@"play_pressed"]];
			if ([[senuti audioController] paused]) {
				[forward setEnabled:TRUE];
				[back setEnabled:TRUE];
				[progress setEnabled:TRUE];
			} else {
				[forward setEnabled:FALSE];
				[back setEnabled:FALSE];
				[progress setEnabled:FALSE];
			}
			if (![playlist isKindOfClass:[SEIPodPlaylist class]]) {
				[play setEnabled:FALSE];
				[forward setEnabled:FALSE];
				[back setEnabled:FALSE];
			}
		} else if (state == SEPauseButton) {
			[play setImage:[NSImage imageNamed:@"pause"]];
			[play setAlternateImage:[NSImage imageNamed:@"pause_pressed"]];
			[forward setEnabled:TRUE];
			[back setEnabled:TRUE];
			[progress setEnabled:TRUE];
		} else if (state == SEStopButton) {
			[play setImage:[NSImage imageNamed:@"stop"]];
			[play setAlternateImage:[NSImage imageNamed:@"stop_pressed"]];
			[forward setEnabled:TRUE];
			[back setEnabled:TRUE];
			[progress setEnabled:TRUE];
		} else {
			[NSException raise:@"SETypeException" format:@"Unhandled state"];
		}
	}
}

- (void)updateVolumeButton {
	float vol = [[senuti audioController] volume];
	if (vol < 0.01) {
		[volume setImage:[NSImage imageNamed:@"volume_off"]];
		[volume setAlternateImage:[NSImage imageNamed:@"volume_off_pressed"]];
	} else if (vol < 0.3) {
		[volume setImage:[NSImage imageNamed:@"volume_low"]];
		[volume setAlternateImage:[NSImage imageNamed:@"volume_low_pressed"]];
	} else if (vol < 0.7) {
		[volume setImage:[NSImage imageNamed:@"volume_medium"]];
		[volume setAlternateImage:[NSImage imageNamed:@"volume_medium_pressed"]];
	} else {
		[volume setImage:[NSImage imageNamed:@"volume_high"]];
		[volume setAlternateImage:[NSImage imageNamed:@"volume_high_pressed"]];
	}
}

- (void)setPlaylist:(id <SEPlaylist>)list {
	if (list != playlist) {
		[playlist release];
		playlist = [list retain];
		[self updateButtonStates];
	}
}

- (void)setSelectedTrack:(id <SETrack>)track {
	if (track != selectedTrack) {
		[selectedTrack release];
		selectedTrack = [track retain];
	}
}

- (void)setVisibleTracks:(NSArray *)tracks {
	
	if (tracks != visibleTracks) {
		[visibleTracks release];
		visibleTracks = [tracks retain];
	}
	
	/* always perform sum.  the tracks within the
	 * same array object could have changed since
	 * the array is just retained */
	NSEnumerator *trackEnumerator = [tracks objectEnumerator];
	id <SETrack> track;
	float totalLength = 0;
	long long totalSize = 0;
	
	while (track = [trackEnumerator nextObject]) {
		totalLength += [track length];
		totalSize += [track size];
	}
	
	[data setStringValue:[NSString stringWithFormat:FSLocalizedString(@"%i songs, %@, %@", @"Number of songs, time and size"),
		[tracks count],
		[[NSValueTransformer valueTransformerForName:@"SEShortTimeTransformer"] transformedValue:[NSNumber numberWithFloat:totalLength]],
		[[NSValueTransformer valueTransformerForName:@"SESizeTransformer"] transformedValue:[NSNumber numberWithLongLong:totalSize]]]];
}

- (void)toggleTrackPlaying:(id)sender {
	
	BOOL startSelectedTrack = FALSE;
	
	if ([[senuti audioController] paused]) {
		if ([[senuti audioController] playingPlaylist] != playlist) {
			if (sender == play) { [[senuti audioController] stop]; } // stop if it's the button
			else { startSelectedTrack = TRUE; } // start a new track otherwise
		} else {
			[[senuti audioController] continue];
		}
	} else if ([[senuti audioController] playing]) {
		if ([[senuti audioController] playingPlaylist] != playlist) {
			[[senuti audioController] stop];
		} else {
			[[senuti audioController] pause];
		}
	} else {
		startSelectedTrack = TRUE;
	}

	if (startSelectedTrack) {
		id <SETrack> track = selectedTrack;
		if (!track) { track = [visibleTracks firstObject]; }
		[[senuti audioController] playTrack:track inPlaylist:playlist];
	}
}


- (IBAction)forward:(id)sender {
	[[senuti audioController] forward:nil];
}

- (IBAction)back:(id)sender {
	[[senuti audioController] back:nil];
}

- (void)scan:(id)sender {
	[[senuti audioController] setProgress:[progress doubleValue]];
}

- (IBAction)showVolume:(id)sender {
	NSPoint origin;
	NSWindow *thisWindow = [[self view] window];
	origin = [volume frame].origin;
	origin = [[thisWindow contentView] convertPoint:origin fromView:[volume superview]];
	origin = [thisWindow convertBaseToScreen:origin];
	origin.y -= [volumeWindow frame].size.height;
	origin.x += 2;
	[volumeWindow setFrameOrigin:origin];	
	[volumeWindow orderFront:nil];
	
	[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(startCheckEvent:) userInfo:nil repeats:NO];
}

- (void)startCheckEvent:(NSTimer *)timer {
	[self checkEvent:[volumeWindow nextEventMatchingMask:NSLeftMouseDownMask | NSRightMouseDownMask]];
}

// close this when clicking outside of volume window
- (void)checkEvent:(NSEvent *)event {
	NSEventType type = [event type];
	if ((type == NSLeftMouseDown || type == NSRightMouseDown) && [event window] != volumeWindow) {
		[volumeWindow close];
		[NSApp sendEvent:event];
	} else {
		[NSApp sendEvent:event];
		[self checkEvent:[volumeWindow nextEventMatchingMask:NSAnyEventMask]];
	}
}

@end
