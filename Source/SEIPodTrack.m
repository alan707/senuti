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

#import <Libxpod/LXMobile.h>
#import "SEIPodTrack.h"
#import "SETrack.h"
#import "SEIPodLibrary.h"

@interface SEIPodTrack (PRIVATE)
- (NSString *)hexFrom64:(guint64)number;
@end

@implementation SEIPodTrack

- (id)init {
	FSLog(@"Must initiate SEIPodTrack with initWithData:");
	return nil;
}

- (id)initWithData:(Itdb_Track *)track {
	if (track && (self = [super initInLibrary:(SEIPodLibrary *)track->itdb->userdata])) {
		if (!track->ipod_path) {
			[self release];
			return nil;
		}
		_track = track;
		
		NSMutableString *part = [NSMutableString stringWithUTF8String:track->ipod_path];
		[part replaceOccurrencesOfString:@":" withString:@"/" options:NSLiteralSearch range:NSMakeRange(0, [part length])];
		[super setPath:[[(SEIPodLibrary *)track->itdb->userdata iPodPath] stringByAppendingString:part]];
		
		[super setTitle:track->title ? [NSString stringWithUTF8String:track->title] : @""];
		[super setAlbum:track->album ? [NSString stringWithUTF8String:track->album] : @""];
		[super setArtist:track->artist ? [NSString stringWithUTF8String:track->artist] : @""];
		[super setGenre:track->genre ? [NSString stringWithUTF8String:track->genre] : @""];
		[super setComposer:track->composer ? [NSString stringWithUTF8String:track->composer] : @""];
		[super setType:track->filetype ? [NSString stringWithUTF8String:track->filetype] : @""];
		[super setComment:track->comment ? [NSString stringWithUTF8String:track->comment] : @""];
		[super setIdentifier:track->id];
		[super setPersistentID:[self hexFrom64:track->dbid]];
		[super setSize:track->size];
		[super setLength:(float)track->tracklen / 1000];
		[super setStartTime:(float)track->starttime / 1000];
		[super setStopTime:(float)track->stoptime / 1000];
		[super setPlayCount:track->playcount + track->recent_playcount];
		[super setYear:track->year];
		[super setTrackNumber:track->track_nr];
		[super setTotalTrackNumbers:track->tracks];
		[super setDiscNumber:track->cd_nr];
		[super setTotalDiscs:track->cds];
		[super setRating:track->rating / ITDB_RATING_STEP];
		[super setBitRate:track->bitrate];
		[super setVolumeAdjustment:track->volume];
		[super setSoundCheck:track->soundcheck];
		
		if (track->time_added > 0) {
			[super setDateAdded:[NSCalendarDate dateWithTimeIntervalSince1970:itdb_time_mac_to_host(track->time_added)]];
		} else {
			[super setDateAdded:nil];
		}
		
		if (track->time_played > 0) {
			[super setLastPlayed:[NSCalendarDate dateWithTimeIntervalSince1970:itdb_time_mac_to_host(track->time_played)]];
		} else {
			[super setLastPlayed:nil];
		}
		
		if (track->time_modified > 0) {
			[super setLastModified:[NSCalendarDate dateWithTimeIntervalSince1970:itdb_time_mac_to_host(track->time_modified)]];
		} else {
			[super setLastModified:nil];
		}
		
		[super setArtwork:nil];
	}
	return self;
}

- (void)dealloc {
	
	[super dealloc];
}

- (BOOL)copyToPath:(NSString *)destination {
	if ([(SEIPodLibrary *)[self library] mobile]) {
		return [[(SEIPodLibrary *)[self library] mobile] copyPath:[self path] toPath:destination];
	} else {
		return [super copyToPath:destination];		
	}
}

- (void *)openFileRead {
	if ([(SEIPodLibrary *)[self library] mobile]) {
		int *file = malloc(sizeof(int));
		*file = [[(SEIPodLibrary *)[self library] mobile] openFile:[[self path] UTF8String] read:TRUE];
		return file;
	} else {
		return [super openFileRead];		
	}	
}

- (void)closeFile:(void *)file {
	if ([(SEIPodLibrary *)[self library] mobile]) {
		[[(SEIPodLibrary *)[self library] mobile] closeFile:*(int *)file];
		free((int *)file);
	} else {
		[super closeFile:(void *)file];		
	}	
}

- (int)readFile:(void *)file into:(char *)buffer length:(int)len {
	if ([(SEIPodLibrary *)[self library] mobile]) {
		return [[(SEIPodLibrary *)[self library] mobile] readFile:*(int *)file into:buffer length:len];
	} else {
		return [super readFile:(void *)file into:(char *)buffer length:(int)len];		
	}	
}

- (void)seekFile:(void *)file position:(int)position {
	if ([(SEIPodLibrary *)[self library] mobile]) {
		[[(SEIPodLibrary *)[self library] mobile] seekFile:*(int *)file position:position];
	} else {
		[super seekFile:(void *)file position:(int)position];		
	}
}

- (void)setTitle:(NSString *)new_title {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setPath:(NSString *)new_path {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setAlbum:(NSString *)new_album {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setArtist:(NSString *)new_artist {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setComposer:(NSString *)composer {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setGenre:(NSString *)new_genre {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setType:(NSString *)new_type {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setComment:(NSString *)new_comment {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setIdentifier:(int)ident {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setFileSize:(long)new_size {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setLength:(float)new_length {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setStartTime:(float)new_time {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setStopTime:(float)new_time {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setPlayCount:(int)new_count {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setLastModified:(NSCalendarDate *)date {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setLastPlayed:(NSCalendarDate *)date {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setDateAdded:(NSCalendarDate *)date {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setYear:(int)new_year {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setTrack:(int)new_track {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setTotalTracks:(int)total_tracks {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setDiscNumber:(int)number {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setTotalDiscs:(int)number {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setRating:(int)number {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setBitRate:(int)number {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setVolumeAdjustment:(float)percent {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setSoundCheck:(float)decibel {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (void)setArtwork:(NSImage *)image {
	FSLog(@"SEIPodTrack cannot set any fields.  Not supported (yet).");
}

- (NSString *)hexFrom64:(guint64)number {
	NSMutableString *result = [NSMutableString string];
	
	/* take pieces half a byte at a time */
	short count = sizeof(guint64) * 2;
	while (count--) {
		short part = (number & 0xf);
		char character = intToHex(part);
		number = number >> 4;
		[result insertString:[NSString stringWithCString:&character length:1] atIndex:0];
	}
	return result;
}

@end
