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

#import "SECopyController.h"

#import "SELibraryController.h"

#import "SETrack.h"
#import "SEPlaylist.h"
#import "SELibrary.h"
#import "SECopyTrack.h"
#import "SEITunesLibrary.h"
#import "SEITunesPlaylist.h"

#import "SEThreadedTrackPreprocessor.h"
#import "SEThreadedTrackCopier.h"
#import "SEThreadedTrackAdder.h"

static void *SECopyingInProgressCountChangedContext = @"SECopyingInProgressCountChangedContext";
static void *SECopyingCompletedCountChangedContext = @"SECopyingCompletedCountChangedContext";

#pragma mark copy controller private interface
// ----------------------------------------------------------------------------------------------------
// copy controller private interface
// ----------------------------------------------------------------------------------------------------

@interface SECopyController (PRIVATE)
- (void)pause;
- (void)continue;
- (void)cancel;

- (void)setInProgress:(int)num;
- (void)setCompleted:(int)num;
- (void)setCopyInProgress:(int)num;
- (void)setCopyCompleted:(int)num;
- (void)setAddInProgress:(int)num;
- (void)setAddCompleted:(int)num;
@end	

#pragma mark copy controller implementation
// ----------------------------------------------------------------------------------------------------
// copy controller implementation
// ----------------------------------------------------------------------------------------------------

@implementation SECopyController

- (id)init {
	if ((self = [super init])) {
		copier = [[SEThreadedTrackCopier alloc] initWithDelegate:self];
		adder = [[SEThreadedTrackAdder alloc] initWithDelegate:self previousPhase:(SEPhasedConsumer *)copier];
		preprocessor = [[SEThreadedTrackPreprocessor alloc] initWithCopier:copier];
		[adder setUpdateDelayMinTime:0.1];
		[copier setUpdateDelayMinTime:0.1];
		[adder addObserver:self forKeyPath:@"inProgressCount" options:0 context:SECopyingInProgressCountChangedContext];
		[adder addObserver:self forKeyPath:@"completedCount" options:0 context:SECopyingCompletedCountChangedContext];
		[copier addObserver:self forKeyPath:@"inProgressCount" options:0 context:SECopyingInProgressCountChangedContext];
		[copier addObserver:self forKeyPath:@"completedCount" options:0 context:SECopyingCompletedCountChangedContext];
	}
	return self;
}

- (void)dealloc {
	[adder removeObserver:self forKeyPath:@"inProgressCount"];
	[adder removeObserver:self forKeyPath:@"completedCount"];
	[copier removeObserver:self forKeyPath:@"inProgressCount"];
	[copier removeObserver:self forKeyPath:@"completedCount"];
	
	[preprocessor release];
	[copier release];
	[adder release];
	[super dealloc];
}

- (void)controllerDidLoad {	
	[preprocessor execute];
	[copier execute];		
	[adder execute];
}

- (void)controllerWillClose {
	[preprocessor abort];
	[adder abort];
	[copier abort];
}

- (void)copyTracks:(NSArray *)tracks toPlaylistNamed:(NSString *)name {

	NSString *newName = name;
	SEITunesLibrary *iTunesLibrary = [[senuti libraryController] iTunesLibrary];

	int suffix = 0;
	while ([[[iTunesLibrary playlists] filter:@selector(name) where:newName] firstObject]) {
		newName = [NSString stringWithFormat:@"%@ %i", name, ++suffix];
	}
	
	id <SEPlaylist> playlist = [[[SEITunesPlaylist alloc] initInLibrary:iTunesLibrary
																		   name:newName
																		   type:SEStandardPlaylistType] autorelease];
	
	[self copyTracks:tracks to:playlist];
}

- (void)copyTracks:(NSArray *)tracks to:(id <SEPlaylist>)playlist {
	[preprocessor addObjects:
		[NSArray arrayWithObject:[SEPreprocessorContainer containerForTracks:tracks toPlaylist:playlist]]];
}

- (IBAction)cancelCopying:(id)sender {
	[self pause];
		
	// ask the user
	int alertResult;
	if (sender == adder) {
		alertResult = NSRunAlertPanel(FSLocalizedString(@"Unable to add song to iTunes", @"iTunes add timeout - title"),
									  FSLocalizedString(@"Senuti was unable to add songs to iTunes.  This is most likely because iTunes has a dialog displayed.  Please dismiss all dialogs in iTunes before continuing.", @"iTunes add timeout - message"),
									  FSLocalizedString(@"Continue", nil),
									  FSLocalizedString(@"Cancel", nil),
									  nil);		
	} else if (sender == copier) {
		alertResult = NSRunAlertPanel(FSLocalizedString(@"Unable to copy song", @"copy fail - title"),
									  [NSString stringWithFormat:
										  FSLocalizedString(@"Senuti was unable to copy the song \"%@\".  An error occurred while trying to %@.  If this continues to be an issue, please report it.", @"copy fail - message"),
										  [[(SECopyTrack *)[sender currentObject] originTrack] title],
										  [sender failAction]],
									  FSLocalizedString(@"Continue", nil),
									  FSLocalizedString(@"Cancel", nil),
									  nil);
	} else {
		alertResult = NSRunAlertPanel(FSLocalizedString(@"Are you sure you want to stop copying?", @"Stop copying - title"),
									  FSLocalizedString(@"Stoping copying will not allow you to resume and is not recommended.", @"Stop copying - message"),
									  FSLocalizedString(@"Continue", nil),
									  FSLocalizedString(@"Stop Copying", nil),
									  nil);		
	}
	
	if (alertResult == NSAlertAlternateReturn) { [self cancel]; }

	// always continue since
	// it got paused to start
	[self continue];
}

/* called by the processor and expects the track to be
 * updated with the proper duplicate stye */
- (void)chooseDuplicateStyle:(SEConsumer *)sender {
	SECopyTrack *track = [sender currentObject];
	int choice;
	choice = NSRunAlertPanel(FSLocalizedString(@"Duplicate File", @"Duplicate file notification title"),
							 [NSString stringWithFormat:
								 FSLocalizedString(@"An item already exists where you are trying to copy \"%@\".  Do you want Senuti to choose a similar file name?", @"Duplicate file notification message"),
								 [[track originTrack] title]],
							 FSLocalizedString(@"Use Similar Name", nil),
							 FSLocalizedString(@"Skip", nil),
							 FSLocalizedString(@"Overwrite", nil));
	if (choice == NSAlertDefaultReturn) { [track setDuplicateHandling:SERenameDuplicatesType]; }
	else if (choice == NSAlertAlternateReturn) { [track setDuplicateHandling:SESkipDuplicatesType]; }
	else if (choice == NSAlertOtherReturn) { [track setDuplicateHandling:SEOverwriteDuplicatesType]; }				
}

- (void)pause {
	[copier pause];
	[adder pause];
}
- (void)continue {
	[copier continue];
	[adder continue];
}
- (void)cancel {
	[copier cancel];
	[adder cancel];
}

- (BOOL)isCopying {
	return copying;
}

- (void)setCopying:(BOOL)flag {
	if (copying != flag) {
		copying = flag;
	}
}

- (NSString *)nameOfATrackInProgress {
	NSString *title;
	title = [[(SECopyTrack *)[copier mostRecentObject] originTrack] title];
	if (title) { return title; }
	title = [[(SECopyTrack *)[adder mostRecentObject] originTrack] title];
	if (title) { return title; }
	
	return nil;
}

- (int)inProgress {
	return inProgress;
}

- (void)setInProgress:(int)num {
	inProgress = num;
}

- (int)completed {
	return completed;
}

- (void)setCompleted:(int)num {
	completed = num;
}

- (NSString *)nameOfCopyTrackInProgress {
	return [[(SECopyTrack *)[copier mostRecentObject] originTrack] title];
}

- (int)copyInProgress {
	return copyInProgress;
}

- (void)setCopyInProgress:(int)num {
	copyInProgress = num;
}

- (int)copyCompleted {
	return copyCompleted;
}

- (void)setCopyCompleted:(int)num {
	copyCompleted = num;
}

- (NSString *)nameOfAddTrackInProgress {
	return [[(SECopyTrack *)[adder mostRecentObject] originTrack] title];
}

- (int)addInProgress {
	return addInProgress;
}

- (void)setAddInProgress:(int)num {
	addInProgress = num;
}

- (int)addCompleted {
	return addCompleted;
}

- (void)setAddCompleted:(int)num {
	addCompleted = num;
}


#pragma mark consumer delegate
// ----------------------------------------------------------------------------------------------------
// consumer delegate
// ----------------------------------------------------------------------------------------------------

- (void)consumerDidStart:(SEConsumer *)consumer {
	[self setCopying:TRUE];
}
- (void)consumerDidFinish:(SEConsumer *)consumer {
	if (![copier isWorking] && ![adder isWorking]) {
		[self setCopying:FALSE];
	}
}


#pragma mark observing changes
// ----------------------------------------------------------------------------------------------------
// observing changes
// ----------------------------------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SECopyingInProgressCountChangedContext) {
		[self setInProgress:[adder inProgressCount] + [copier inProgressCount]];
		[self setAddInProgress:[adder inProgressCount]];
		[self setCopyInProgress:[copier inProgressCount]];
	} else if (context == SECopyingCompletedCountChangedContext) {
		[self setCompleted:[adder completedCount] + [copier completedCount]];
		[self setAddCompleted:[adder completedCount]];
		[self setCopyCompleted:[copier completedCount]];
	}
}

@end
