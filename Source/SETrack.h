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

@protocol SELibrary;
@protocol SETrack <NSObject>

- (NSSet *)similarTracks;
- (void)addSimilarTrack:(id <SETrack>)track;
- (void)addSimilarTracks:(NSSet *)tracks;
- (void)removeSimilarTrack:(id <SETrack>)track;

- (id <SETrack>)duplicateIntoLibrary:(id <SELibrary>)library;
- (NSSet *)duplicateTracks;
- (void)addDuplicateTrack:(id <SETrack>)track;
- (void)removeDuplicateTrack:(id <SETrack>)track;

- (BOOL)copyToPath:(NSString *)path;

- (id <SELibrary>)library;

- (NSString *)title;
- (void)setTitle:(NSString *)new_title;

- (NSString *)path;
- (void)setPath:(NSString *)new_path;
- (BOOL)fileExists;

- (NSString *)album;
- (void)setAlbum:(NSString *)new_album;

- (NSString *)artist;
- (void)setArtist:(NSString *)new_artist;

- (NSString *)composer;
- (void)setComposer:(NSString *)composer;

- (NSString *)genre;
- (void)setGenre:(NSString *)new_genre;

- (NSString *)type;
- (void)setType:(NSString *)new_type;

- (NSString *)comment;
- (void)setComment:(NSString *)new_comment;

- (int)identifier;
- (void)setIdentifier:(int)ident;

- (NSString *)persistentID;
- (void)setPersistentID:(NSString *)id;

- (long)size; /* in bytes */
- (void)setSize:(long)new_size;

- (float)length; /* in seconds */
- (void)setLength:(float)new_length;

- (float)startTime;
- (void)setStartTime:(float)new_time;

- (float)stopTime;
- (void)setStopTime:(float)new_time;

- (int)playCount;
- (void)setPlayCount:(int)new_count;

- (NSCalendarDate *)lastModified;
- (void)setLastModified:(NSCalendarDate *)date;

- (NSCalendarDate *)lastPlayed;
- (void)setLastPlayed:(NSCalendarDate *)date;

- (NSCalendarDate *)dateAdded;
- (void)setDateAdded:(NSCalendarDate *)date;

- (int)year;
- (void)setYear:(int)new_year;

- (NSArray *)trackData;
- (int)trackNumber;
- (void)setTrackNumber:(int)new_track;

- (int)totalTrackNumbers;
- (void)setTotalTrackNumbers:(int)total_tracks;

- (NSArray *)discData;
- (int)discNumber;
- (void)setDiscNumber:(int)number;

- (int)totalDiscs;
- (void)setTotalDiscs:(int)number;

- (int)rating;
- (void)setRating:(int)number;

- (int)bitRate;
- (void)setBitRate:(int)number;

- (float)volumeAdjustment;
- (void)setVolumeAdjustment:(float)percent;

- (float)soundCheck;
- (void)setSoundCheck:(float)decibel;

- (NSImage *)artwork;
- (void)setArtwork:(NSImage *)image;

@end