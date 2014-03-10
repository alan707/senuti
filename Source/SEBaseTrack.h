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

#import "SETrack.h"

@protocol SELibrary;
@interface SEBaseTrack : NSObject <SETrack> {
	id <SELibrary> library;

	NSMutableSet *similarTracks;
	NSMutableSet *duplicateTracks;
	
	NSString *title;
	NSString *path;
	NSString *album;
	NSString *artist;
	NSString *composer;
	NSString *genre;
	NSString *type;
	NSString *comment;
	int identifier;
	NSString *persistentID;
	long size; /* in bytes */
	float length; /* in seconds */
	float startTime;
	float stopTime;
	int playCount;
	NSCalendarDate *lastModified;
	NSCalendarDate *lastPlayed;
	NSCalendarDate *dateAdded;
	int year;
	int trackNumber;
	int totalTrackNumbers;
	int discNumber;
	int totalDiscs;
	int rating;
	int bitRate;
	float volumeAdjustment;
	float soundCheck;
	NSImage *artwork;
}

- (id)initInLibrary:(id <SELibrary>)library;

// these methods may be overridden by subclasses
// they're used to read album art from the file
- (void *)openFileRead;
- (void)closeFile:(void *)file;
- (int)readFile:(void *)file into:(char *)buffer length:(int)len;
- (void)seekFile:(void *)file position:(int)position;

@end
