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

@class SEConsumer;
@protocol SEPlaylist;
@interface SECopyController : SEObject <SEController> {
	SEConsumer *preprocessor;
	SEConsumer *copier;
	SEConsumer *adder;
	BOOL copying;
	int inProgress;
	int completed;
	int addInProgress;
	int addCompleted;
	int copyInProgress;
	int copyCompleted;
}

- (void)copyTracks:(NSArray *)tracks to:(id <SEPlaylist>)playlist;
- (void)copyTracks:(NSArray *)tracks toPlaylistNamed:(NSString *)name;
- (IBAction)cancelCopying:(id)sender;
- (BOOL)isCopying;

- (NSString *)nameOfATrackInProgress;
- (int)inProgress;
- (int)completed;

- (NSString *)nameOfCopyTrackInProgress;
- (int)copyInProgress;
- (int)copyCompleted;

- (NSString *)nameOfAddTrackInProgress;
- (int)addInProgress;
- (int)addCompleted;

@end
