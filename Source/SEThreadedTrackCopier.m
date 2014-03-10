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

#import "SEThreadedTrackCopier.h"
#import "SECopyController.h"

#import "SEObject.h"
#import "SECopyTrack.h"

@interface SEThreadedTrackCopier (PRIVATE)
- (void)copyFailedAt:(NSString *)info;
@end

@implementation SEThreadedTrackCopier

- (BOOL)shouldProcessObject:(SECopyTrack *)track {
	return ([track destinationRoot] != nil);
}

- (BOOL)processObject:(SECopyTrack *)track {		
	if ([track destinationRoot]) {
		NSFileManager *manager = [NSFileManager defaultManager];
		
		// create a string that represents the path of the file on the iPod
		NSString *extension = [[[track originTrack] path] pathExtension];
		
		// declare some stuff and make some changes for the way the filesystem works
		NSString *title = [NSFileManager safePathComponent:[[track originTrack] title]];
		NSString *destination = [track destinationRoot];
		
		// check for organization
		if ([track organize]) {
			NSString *artist;
			if ([[track originTrack] artist] && [[[track originTrack] artist] length]) { artist = [NSFileManager safePathComponent:[[track originTrack] artist]]; }
			else { artist = FSLocalizedString(@"Unknown Artist", nil); }
			destination = [destination stringByAppendingPathComponent:artist];
			if (![manager createDirectoryAtPath:destination attributes:nil checkExists:TRUE]) {
				[self copyFailedAt:@"create an artist directory"];
				return YES;
			}
						
			NSString *album;
			if ([[track originTrack] album] && [[[track originTrack] album] length]) { album = [NSFileManager safePathComponent:[[track originTrack] album]]; }
			else { album = FSLocalizedString(@"Unknown Album", nil); }
			destination = [destination stringByAppendingPathComponent:album];
			if (![manager createDirectoryAtPath:destination attributes:nil checkExists:TRUE]) {
				[self copyFailedAt:@"create an album directory"];
				return YES;
			}
			
			if ([[track originTrack] trackNumber]) {
				NSString *number = [NSString stringWithFormat:@"%i", [[track originTrack] trackNumber]];
				int length = 2 - [number length];
				NSString *padding = [@"" stringByPaddingToLength:length > 0 ? length : 0 withString:@"0" startingAtIndex:0];
				title = [NSString stringWithFormat:@"%@%@ %@", padding, number, [[track originTrack] title]];
			}
		}

		// create the destination path
		destination = [[destination stringByAppendingPathComponent:[NSFileManager safePathComponent:title]] stringByAppendingPathExtension:extension];
		
		// detect duplicates
		if ([manager fileExistsAtPath:destination]) {
			if ([track duplicateHandling] == SEAskDuplicatesType) {
				// notify copy controller to display an alert (on the main thread)
				[[[SEObject sharedSenutiInstance] copyController] performSelectorOnMainThread:@selector(chooseDuplicateStyle:)
																				   withObject:self
																				waitUntilDone:YES];
			}
			
			if ([track duplicateHandling] == SERenameDuplicatesType) {
				destination = [manager uniquePathForPath:destination];
			} else if ([track duplicateHandling] == SESkipDuplicatesType) {
				destination = nil; // skip
			} else if ([track duplicateHandling] == SEOverwriteDuplicatesType) {
				[manager trashFileAtPath:destination]; // move to trash
			}
		}
		
		// actually copy
		if (destination) {
			if(![[track originTrack] copyToPath:destination]) {
				[self copyFailedAt:@"copy the file"];
				return YES;
			}
		}
		
		[track setDestinationPath:destination];
	} else {
		[track setDestinationPath:nil];
	}
	return YES;
}

- (NSString *)failAction {
	return failAction;
}

- (void)copyFailedAt:(NSString *)info {
	failAction = info;
	[[[SEObject sharedSenutiInstance] copyController] performSelectorOnMainThread:@selector(cancelCopying:) withObject:self waitUntilDone:YES];
	failAction = nil;

	[[self currentObject] setDestinationRoot:nil];
	[[self currentObject] setDestinationPath:nil];
	FSDLog(@"Copying failed for track: %@ with message: %@", [[[self currentObject] originTrack] title], info);
}

@end
