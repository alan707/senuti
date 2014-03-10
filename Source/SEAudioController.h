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

#import "SEObject.h"
#import "SEController.h"

@protocol SETrack, SEPlaylist;
@interface SEAudioController : SEObject <SEController> {
	NSString *script;
	NSMovie *movie;
	BOOL playing;
	float volume;
	id <SETrack> playingTrack;
	id <SEPlaylist> playingPlaylist;
	NSArray *trackList;
	NSTimer *endTimer;
}

- (float)volume;
- (void)setVolume:(float)vol;

- (BOOL)playing;
- (BOOL)paused;
- (float)progress;
- (void)setProgress:(float)progress;
- (float)time;

- (void)playTrack:(id <SETrack>)track inPlaylist:(id <SEPlaylist>)playlist;
- (void)pause;
- (void)continue;
- (void)stop;

- (IBAction)forward:(id)sender;
- (IBAction)back:(id)sender;

- (id <SETrack>)playingTrack;
- (id <SEPlaylist>)playingPlaylist;

@end

extern NSString *SESavedVolumeKey;