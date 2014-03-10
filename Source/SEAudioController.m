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

#import <QuickTime/QuickTime.h>
#import "SEAudioController.h"

#import "SEInterfaceController.h"
#import "SEMainWindowController.h"
#import "SEApplescriptController.h"
#import "SETrackListViewController.h"
#import "SEGeneralPreferenceViewController.h"

#import "SEContentController.h"
#import "SEPlaylist.h"
#import "SETrack.h"

static void *SEAvailableObjectsChangeContext = @"SEAvailableObjectsChangeContext";
static void *SESavedVolumeChangeContext = @"SESavedVolumeChangeContext";
NSString *SESavedVolumeKey = @"SESavedVolume"; /* In VisualView.nib */

@interface SEAudioController (PRIVATE)
- (void)setPlaying:(BOOL)flag;
- (void)setPlayingTrack:(id <SETrack>)track;
- (void)setMovie:(NSMovie *)mov;
- (void)setPlayingPlaylist:(id <SEPlaylist>)playlist;
- (void)setTrackList:(NSArray *)list;

- (void)updateTrackList;
- (id <SETrack>)previousTrack;
- (id <SETrack>)nextTrack;
- (void)watchForEnd:(id)sender;
- (void)playTrack:(id <SETrack>)track
	   inPlaylist:(id <SEPlaylist>)playlist
  updateTrackList:(BOOL)flag;
@end

@implementation SEAudioController

+ (void)initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:0.5], SESavedVolumeKey, nil]];
}

- (id)init {
	if ((self = [super init])) {
		volume = 0;
		script = [[[NSBundle mainBundle] pathForResource:@"itunes" ofType:@"scpt"] retain];
	}
	return self;
}

- (void)dealloc {
	[script release];
	[movie release];
	[playingTrack release];
	[playingPlaylist release];
	[trackList release];
	[endTimer autorelease];
	
	[super dealloc];
}

- (void)controllerDidLoad {
	[self setVolume:[[NSUserDefaults standardUserDefaults] floatForKey:SESavedVolumeKey]];

	[[senuti interfaceController] addObserver:self forKeyPath:@"mainWindowController.contentController.availableObjects" options:0 context:SEAvailableObjectsChangeContext];
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:SESavedVolumeKey options:0 context:SESavedVolumeChangeContext];
}

- (void)controllerWillClose {
	[[senuti interfaceController] removeObserver:self forKeyPath:@"mainWindowController.contentController.availableObjects"];
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:SESavedVolumeKey];
}

#pragma mark observing changes
// ----------------------------------------------------------------------------------------------------
// observing changes
// ----------------------------------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SEAvailableObjectsChangeContext) {
		[self updateTrackList];
	} else if (context == SESavedVolumeChangeContext) {
		[self setVolume:[[NSUserDefaults standardUserDefaults] floatForKey:SESavedVolumeKey]];
	}
}

- (void)updateTrackList {
	id <SEContentController> contentController = [[[senuti interfaceController] mainWindowController] contentController];
	if ([contentController conformsToProtocol:@protocol(SEContentController)] &&
		[contentController objectsOwner] == playingPlaylist) {
		
		[self setTrackList:[contentController availableObjects]];
	}	
}

- (id <SETrack>)previousTrack {
	int index = [trackList indexOfObjectIdenticalTo:playingTrack];
	if (index >= 0) { index--; }
	else { return nil; }
	
	if (index >= 0 && index < [trackList count]) {
		return [trackList objectAtIndex:index];
	}
	return nil;
}

- (id <SETrack>)nextTrack {
	int index = [trackList indexOfObjectIdenticalTo:playingTrack];
	if (index >= 0) { index++; }
	else { return nil; }
	
	if (index >= 0 && index < [trackList count]) {
		return [trackList objectAtIndex:index];
	}
	return nil;
}

#pragma mark properties
// ----------------------------------------------------------------------------------------------------
// properties
// ----------------------------------------------------------------------------------------------------

- (id <SEPlaylist>)playingPlaylist {
	return playingPlaylist;
}

- (void)setPlayingPlaylist:(id <SEPlaylist>)playlist {
	if (playlist != playingPlaylist) {
		[playingPlaylist release];
		playingPlaylist = [playlist retain];
	}
}

- (id <SETrack>)playingTrack {
	return playingTrack;
}

- (void)setPlayingTrack:(id <SETrack>)track {
	if (track != playingTrack) {
		[self willChangeValueForKey:@"paused"];
		[playingTrack release];
		playingTrack = [track retain];
		[self didChangeValueForKey:@"paused"];
		
		if (playingTrack) { [self setMovie:[[[NSMovie alloc] initWithURL:[NSURL fileURLWithPath:[track path]] byReference:YES] autorelease]]; }
		else { [self setMovie:nil]; }
	}
}

- (void)setTrackList:(NSArray *)list {
	if (list != trackList) {
		[trackList release];
		trackList = [list copy];
	}
}

- (void)setMovie:(NSMovie *)mov {
	if (movie != mov) {
		[movie release];
		movie = [mov retain];
	}
}

- (BOOL)playing {
	return playing;
}

- (BOOL)paused {
	return (playingTrack && !playing);
}

- (void)setPlaying:(BOOL)flag {
	[self willChangeValueForKey:@"paused"];
	playing = flag;
	[self didChangeValueForKey:@"paused"];
}

- (float)volume {
	return volume;
}

- (void)setVolume:(float)vol {
	volume = vol;
	if (movie) {
		// qt volume range is 0 to 256 (-1 to 1 as short)
		SetMovieVolume([movie QTMovie], volume * 256);
	}
}

- (float)progress {
	return (float)GetMovieTime([movie QTMovie], NULL) / (float)GetMovieDuration([movie QTMovie]);
}

- (void)setProgress:(float)progress {
	SetMovieTimeValue([movie QTMovie], (float)GetMovieDuration([movie QTMovie]) * progress);
	[self watchForEnd:nil];
}

- (float)time {
	return (float)GetMovieTime([movie QTMovie], NULL) / (float)GetMovieTimeScale([movie QTMovie]);
}

- (void)playTrack:(id <SETrack>)track inPlaylist:(id <SEPlaylist>)playlist {
	[self playTrack:track inPlaylist:playlist updateTrackList:YES];
}

- (void)playTrack:(id <SETrack>)track inPlaylist:(id <SEPlaylist>)playlist updateTrackList:(BOOL)flag {
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:SEPauseITunesOnPlayKey]) {
		FSAppleScriptClient *client = [[senuti applescriptController] runner];
		[client run:script
		   function:@"pause"
		  arguments:nil
			  error:NULL];
	}
	
	[self setPlayingTrack:track];
	[self setPlayingPlaylist:playlist];
	[self setVolume:volume];
	
	GoToBeginningOfMovie([movie QTMovie]);
	StartMovie([movie QTMovie]);
	[self setPlaying:TRUE];
	[self watchForEnd:nil];
	if (flag) { [self updateTrackList]; }
}

- (IBAction)forward:(id)sender {
	id <SETrack> nextTrack = [self nextTrack];
	if (nextTrack) { [self playTrack:nextTrack inPlaylist:playingPlaylist updateTrackList:NO]; }
	else { [self stop]; }
}

- (IBAction)back:(id)sender {
	if ([self time] < 5) {
		id <SETrack> previousTrack = [self previousTrack];
		if (previousTrack) { [self playTrack:previousTrack inPlaylist:playingPlaylist updateTrackList:NO]; }
		else { [self stop]; }
	} else {
		[self playTrack:playingTrack inPlaylist:playingPlaylist updateTrackList:NO];
	}
}


- (void)pause {
	StopMovie([movie QTMovie]);
	[self setPlaying:FALSE];
}

- (void)continue {
	StartMovie([movie QTMovie]);
	[self setPlaying:TRUE];
	[self watchForEnd:nil];
}

- (void)stop {
	StopMovie([movie QTMovie]);
	[self setPlaying:FALSE];
	[self setPlayingTrack:nil];
	[self setPlayingPlaylist:nil];
}

- (void)watchForEnd:(id)sender {
	if ([self progress] > 0.999) {
		id <SETrack> nextTrack = [self nextTrack];
		if (nextTrack) {
			[self playTrack:nextTrack inPlaylist:playingPlaylist updateTrackList:NO];
		}
	} else if ([self playing]) {
		float percentLeft = ((float)GetMovieDuration([movie QTMovie]) - (float)GetMovieTime([movie QTMovie], NULL)) / (float)GetMovieDuration([movie QTMovie]);
		float timeLeft = [playingTrack length] * percentLeft;
		[endTimer invalidate];
		[endTimer autorelease];
		endTimer = [[NSTimer scheduledTimerWithTimeInterval:(0.99 * timeLeft) target:self selector:@selector(watchForEnd:) userInfo:nil repeats:NO] retain];
	}
}

@end
