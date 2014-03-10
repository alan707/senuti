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

#import "SEViewController.h"
#import "SEControllerObserver.h"

@protocol SETrack, SEPlaylist;
@class SEAudioView, SETrackProgressView;
@interface SEVisualViewController : SEViewController <SEControllerObserver> {
	IBOutlet NSTextField *data;
	IBOutlet NSButton *play;
	IBOutlet NSButton *forward;
	IBOutlet NSButton *back;
	IBOutlet NSButton *volume;
	IBOutlet NSView *audioControls;
	IBOutlet NSView *volumeView;
	IBOutlet SETrackProgressView *progress;
	
	NSWindow *volumeWindow;
	NSTimer *progressPoll;
	
	id <SETrack> selectedTrack;
	id <SEPlaylist> playlist;
	NSArray *visibleTracks;
}

- (void)setPlaylist:(id <SEPlaylist>)playlist;
- (void)setSelectedTrack:(id <SETrack>)track;
- (void)setVisibleTracks:(NSArray *)tracks;

- (IBAction)toggleTrackPlaying:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)showVolume:(id)sender;

@end
