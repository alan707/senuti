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

#import "SEBaseTrack.h"
#import "SELibrary.h"

@interface SEBaseTrack (PRIVATE)
- (void)_getAACArtwork;
- (void)_getMP3Artwork;
- (void)_getArtwork;
- (void)_setArtwork:(NSImage *)newArtwork;
@end

@implementation SEBaseTrack

- (id)init {
	FSLog(@"Must initiate SEBaseTrack with initInLibrary:");
	return nil;
}

- (id)initInLibrary:(id <SELibrary>)lib {
	if ((self = [super init])) {
		library = lib;
		similarTracks = [[NSMutableSet alloc] init];
		duplicateTracks = [[NSMutableSet alloc] init];
	}
	return self;
}

- (void)dealloc {
	[similarTracks release];
	[duplicateTracks release];
	
	[title release];
	[path release];
	[album release];
	[artist release];
	[composer release];
	[genre release];
	[persistentID release];
	[type release];
	[comment release];
	[lastModified release];
	[lastPlayed release];
	[dateAdded release];
	[artwork release];
	
	[super dealloc];
}

- (NSSet *)similarTracks {
	return similarTracks;
}
- (void)addSimilarTrack:(id <SETrack>)aTrack {
	[self addSimilarTracks:[NSSet setWithObject:aTrack]];
}
- (void)addSimilarTracks:(NSSet *)tracks {
	@synchronized(self) {
		[self willChangeValueForKey:@"similarTracks"
					withSetMutation:NSKeyValueUnionSetMutation
					   usingObjects:tracks];
		[similarTracks unionSet:tracks];
		[self didChangeValueForKey:@"similarTracks"
				   withSetMutation:NSKeyValueUnionSetMutation
					  usingObjects:tracks];
	}
}
- (void)removeSimilarTrack:(id <SETrack>)aTrack {
	@synchronized(self) {
		NSSet *set = [NSSet setWithObject:aTrack];
		[self willChangeValueForKey:@"similarTracks"
					withSetMutation:NSKeyValueMinusSetMutation
					   usingObjects:set];
		[similarTracks minusSet:set];
		[self didChangeValueForKey:@"similarTracks"
				   withSetMutation:NSKeyValueMinusSetMutation
					  usingObjects:set];		
	}
}

- (id <SETrack>)duplicateIntoLibrary:(id <SELibrary>)lib {
	id <SETrack> track = [[[[lib class] trackClass] alloc] initInLibrary:lib];
	[track setTitle:[self title]];
	[track setPath:[self path]];
	[track setAlbum:[self album]];
	[track setArtist:[self artist]];
	[track setComposer:[self composer]];
	[track setGenre:[self genre]];
	[track setType:[self type]];
	[track setComment:[self comment]];
	[track setIdentifier:[self identifier]];
	[track setSize:[self size]];
	[track setLength:[self length]];
	[track setStartTime:[self startTime]];
	[track setStopTime:[self stopTime]];
	[track setPlayCount:[self playCount]];
	[track setLastModified:[self lastModified]];
	[track setLastPlayed:[self lastPlayed]];
	[track setDateAdded:[self dateAdded]];
	[track setYear:[self year]];
	[track setTrackNumber:[self trackNumber]];
	[track setTotalTrackNumbers:[self totalTrackNumbers]];
	[track setDiscNumber:[self discNumber]];
	[track setTotalDiscs:[self totalDiscs]];
	[track setRating:[self rating]];
	[track setBitRate:[self bitRate]];
	[track setVolumeAdjustment:[self volumeAdjustment]];
	[track setSoundCheck:[self soundCheck]];
	[track setArtwork:artwork];
	[track addSimilarTracks:[self similarTracks]];
	return track;
}

- (NSSet *)duplicateTracks {
	return duplicateTracks;
}

- (void)addDuplicateTrack:(id <SETrack>)track {
	@synchronized(duplicateTracks) {
		[duplicateTracks addObject:track];
	}
}

- (void)removeDuplicateTrack:(id <SETrack>)track {
	@synchronized(duplicateTracks) {
		[duplicateTracks removeObject:track];
	}	
}

- (id <SELibrary>)library {
	return library;
}

- (BOOL)copyToPath:(NSString *)destination {
	return [[NSFileManager defaultManager] copyPath:[self path] toPath:destination handler:nil];
}

- (NSString *)title {
	return title;
}
- (void)setTitle:(NSString *)new_title {
	if (title != new_title) {
		[title release];
		title = [new_title retain];
	}
}

- (NSString *)path {
	return path;
}
- (void)setPath:(NSString *)new_path {
	if (path != new_path) {
		[path release];
		path = [new_path retain];
	}
}

- (BOOL)fileExists {
	return [[NSFileManager defaultManager] fileExistsAtPath:[self path]];
}

- (NSString *)album {
	return album;
}
- (void)setAlbum:(NSString *)new_album {
	if (album != new_album) {
		[album release];
		album = [new_album retain];
	}
}

- (NSString *)artist {
	return artist;
}
- (void)setArtist:(NSString *)new_artist {
	if (artist != new_artist) {
		[artist release];
		artist = [new_artist retain];
	}
}

- (NSString *)composer {
	return composer;
}
- (void)setComposer:(NSString *)new_composer {
	if (composer != new_composer) {
		[composer release];
		composer = [new_composer retain];
	}
}

- (NSString *)genre {
	return genre;
}
- (void)setGenre:(NSString *)new_genre {
	if (genre != new_genre) {
		[genre release];
		genre = [new_genre retain];
	}
}

- (NSString *)type {
	return type;
}
- (void)setType:(NSString *)new_type {
	if (type != new_type) {
		[type release];
		type = [new_type retain];
	}
}

- (NSString *)comment {
	return comment;
}
- (void)setComment:(NSString *)new_comment {
	if (comment != new_comment) {
		[comment release];
		comment = [new_comment retain];
	}
}

- (int)identifier {
	return identifier;
}
- (void)setIdentifier:(int)ident {
	identifier = ident;
}

- (NSString *)persistentID {
	return persistentID;
}
- (void)setPersistentID:(NSString *)ident {
	if (persistentID != ident) {
		[persistentID release];
		persistentID = [ident retain];
	}
}

- (long)size { /* in bytes */
	return size;
}
- (void)setSize:(long)new_size {
	size = new_size;
}

- (float)length { /* in seconds */
	return length;
}
- (void)setLength:(float)new_length {
	length = new_length;
}

- (float)startTime {
	return startTime;
}
- (void)setStartTime:(float)new_startTime {
	startTime = new_startTime;
}

- (float)stopTime {
	return stopTime;
}
- (void)setStopTime:(float)new_stopTime {
	stopTime = new_stopTime;
}

- (int)playCount {
	return playCount;
}
- (void)setPlayCount:(int)new_playCount {
	playCount = new_playCount;
}

- (NSCalendarDate *)lastModified {
	return lastModified;
}
- (void)setLastModified:(NSCalendarDate *)new_lastModified {
	if (lastModified != new_lastModified) {
		[lastModified release];
		lastModified = [new_lastModified retain];
	}
}

- (NSCalendarDate *)lastPlayed {
	return lastPlayed;
}
- (void)setLastPlayed:(NSCalendarDate *)new_lastPlayed {
	if (lastPlayed != new_lastPlayed) {
		[lastPlayed release];
		lastPlayed = [new_lastPlayed retain];
	}
}

- (NSCalendarDate *)dateAdded {
	return dateAdded;
}
- (void)setDateAdded:(NSCalendarDate *)new_dateAdded {
	if (dateAdded != new_dateAdded) {
		[dateAdded release];
		dateAdded = [new_dateAdded retain];
	}
}

- (int)year {
	return year;
}
- (void)setYear:(int)new_year {
	year = new_year;
}

- (NSArray *)trackData {
	if (trackNumber) {
		return [NSArray arrayWithObjects:[NSNumber numberWithInt:trackNumber], [NSNumber numberWithInt:totalTrackNumbers], nil];
	}
	return nil;
}
- (int)trackNumber {
	return trackNumber;
}
- (void)setTrackNumber:(int)new_trackNumber {
	[self willChangeValueForKey:@"trackData"];
	trackNumber = new_trackNumber;
	[self didChangeValueForKey:@"trackData"];
}

- (int)totalTrackNumbers {
	return totalTrackNumbers;
}
- (void)setTotalTrackNumbers:(int)new_totalTrackNumbers {
	[self willChangeValueForKey:@"trackData"];
	totalTrackNumbers = new_totalTrackNumbers;
	[self didChangeValueForKey:@"trackData"];
}

- (NSArray *)discData {
	if (discNumber) {
		return [NSArray arrayWithObjects:[NSNumber numberWithInt:discNumber], [NSNumber numberWithInt:totalDiscs], nil];
	}
	return nil;
}
- (int)discNumber {
	return discNumber;
}
- (void)setDiscNumber:(int)new_discNumber {
	[self willChangeValueForKey:@"discData"];
	discNumber = new_discNumber;
	[self didChangeValueForKey:@"discData"];
}

- (int)totalDiscs {
	return totalDiscs;
}
- (void)setTotalDiscs:(int)new_totalDiscs {
	[self willChangeValueForKey:@"discData"];
	totalDiscs = new_totalDiscs;
	[self didChangeValueForKey:@"discData"];
}

- (int)rating {
	return rating;
}
- (void)setRating:(int)new_rating {
	rating = new_rating;
}

- (int)bitRate {
	return bitRate;
}
- (void)setBitRate:(int)new_bitRate {
	bitRate = new_bitRate;
}

- (float)volumeAdjustment {
	return volumeAdjustment;
}
- (void)setVolumeAdjustment:(float)new_volumeAdjustment {
	volumeAdjustment = new_volumeAdjustment;
}

- (float)soundCheck {
	return soundCheck;
}
- (void)setSoundCheck:(float)new_soundCheck {
	soundCheck = new_soundCheck;
}

- (NSImage *)artwork {
	if (!artwork) { [self _getArtwork]; }
	return artwork;
}

- (void)_setArtwork:(NSImage *)newArtwork {
	if (artwork != newArtwork) {
		[artwork release];
		artwork = [newArtwork retain];
	}
}

- (void)setArtwork:(NSImage *)newArtwork {
	[self _setArtwork:newArtwork];
}

long longFromBigEndian(const char *string) {
	long test;
	memcpy(&test,string,4);
    return test;
}

// this search will search THROUGH null characters.  needed for parsing
const char * strsearch(const char *string1, long len1, const char *string2, long len2) {
	int counter = 0;
	while (counter < len1)
	{
		if (strncmp(&string1[counter], string2, len2) == 0)
		{
			return &string1[counter];
		}
		counter++;
	}
	return NULL;
}

- (void *)openFileRead {
	return fopen([[self path] UTF8String], "r");
}

- (void)closeFile:(void *)file {
	fclose((FILE *)file);
}

- (int)readFile:(void *)file into:(char *)buffer length:(int)len {
	return fread(buffer, 1, len, (FILE *)file);
}

- (void)seekFile:(void *)file position:(int)position {
	fseek((FILE *)file, position, SEEK_SET);
}

- (void)_getAACArtwork {
	
	FILE *file = [self openFileRead];
	if (file != NULL)
	{
		char *data = (char *) malloc(12);
		if (data == NULL) return;
		long dataSize = 0;
		long jump = 0;
		
		[self readFile:file into:data length:12];
		if (data[4] == 'f' && data[5] == 't' && data[6] == 'y' && data[7] == 'p')
		{
			jump += longFromBigEndian(data);
			[self seekFile:file position:jump];
		} else {
			NSLog(@"Bad AAC File");
			free(data);
			data = NULL;
			return;
		}
		[self readFile:file into:data length:12];
		if (data[4] == 'm' && data[5] == 'o' && data[6] == 'o' && data[7] == 'v')
		{
			jump += longFromBigEndian(&data[8]) + 8; // plus 8 accounts for 4 byte identifier and 4 byte size
			[self seekFile:file position:jump];
		} else {
			NSLog(@"Bad AAC File");
			free(data);
			data = NULL;
			return;
		}
		[self readFile:file into:data length:12];
		if (data[4] == 't' && data[5] == 'r' && data[6] == 'a' && data[7] == 'k')
		{
			jump += longFromBigEndian(data);
			[self seekFile:file position:jump];
		} else {
			NSLog(@"Bad AAC File");
			free(data);
			data = NULL;
			return;
		}
		[self readFile:file into:data length:12];
		if (data[4] == 'u' && data[5] == 'd' && data[6] == 't' && data[7] == 'a')
		{
			jump += 8;
			dataSize = longFromBigEndian(&data[8]);
			
			free(data);
			data = (char *) malloc(dataSize);
			if (data != NULL)
			{
				[self readFile:file into:data length:dataSize];
			}
		} else {
			NSLog(@"Bad AAC File");
			free(data);
			data = NULL;
			return;
		}
		
		[self closeFile:file];
		
		if (data != NULL)
		{
			const char *cover = strsearch(data, dataSize, "covr", 4);
			if (cover != NULL)
			{
				long coverSize = longFromBigEndian(&cover[4]) - 16; // everything except the stuff we don't need
				cover = &cover[20]; // real start of the data
				
				NSImage *art = [[[NSImage alloc] initWithData:[NSData dataWithBytes:cover length:(unsigned)coverSize]] autorelease];
				[self _setArtwork:art];
			}
		}
		free(data);
	}
}

unsigned long longFromSyncsafeBigEndian(const char *string)
{
	unsigned long ret = 0;
	ret = ((ret << 7) | (string[0] & 0x7F));
	ret = ((ret << 7) | (string[1] & 0x7F));
	ret = ((ret << 7) | (string[2] & 0x7F));
	ret = ((ret << 7) | (string[3] & 0x7F));
	return ret;
}

- (void)_getMP3Artwork {
//	const char *path = [[self path] UTF8String];
//	FILE *file = fopen(path, "r");
//	if (file != NULL)
//	{
//		char *data = (char *) malloc(12);
//		if (data == NULL) return;
//		long dataSize = 0;
//		
//		fread(data, 1, 12, file);
//		if (data[0] == 'I' && data[1] == 'D' && data[2] == '3')
//		{
//			dataSize = longFromSyncsafeBigEndian(&data[8]);
//			NSLog(@"%i", dataSize);
//			
//			free(data);
//			data = (char *) malloc(dataSize);
//			if (data != NULL)
//			{
//				fread(data, 1, dataSize, file);
//			}
//		} else {
//			NSLog(@"MP3 with no ID3 tag at beginning");
//			free(data);
//			data = NULL;
//			return;
//		}
//		
//		fclose(file);
//		
//		if (data != NULL)
//		{
//			const char *cover = strsearch(data, dataSize, "PIC", 3)-1;
//			if (cover != NULL)
//			{
//				unsigned long coverSize = longFromSyncsafeBigEndian(&cover[4]) - 10; // everything except the stuff we don't need
//				NSLog(@"%u %x", coverSize, longFromBigEndian(&cover[4]));
//				
//				const char *end_first_string = strsearch(cover+12, coverSize, "\0\0", 2);
//				end_first_string+=3; // skip the 00 and the next piece of data
//				NSLog(@"%i", end_first_string - cover);
//				const char *end_second_string = strsearch(end_first_string, coverSize, "\0\0", 2);
//				end_second_string+=2; // skip the 00
//				
//				coverSize = coverSize - (end_second_string - cover);
//				cover = end_second_string;
//				
//				NSLog(@"a %i %@", coverSize, [NSString stringWithCString:cover]);
//				//				cover = &cover[22]; // real start of the data
//				NSLog(@"Yea");
//				NSImage *artwork = [[NSImage alloc] initWithData:[NSData dataWithBytes:cover length:(unsigned)coverSize]];
//				[self _setArtwork:artwork];
//				[artwork release];
//			}
//		}
//		free(data);
//	}
}

- (void)_getArtwork {
	const char *filePath = [[self path] UTF8String];
	if (strncmp(&filePath[strlen(filePath)-4], ".m4a", 4) == 0 || strncmp(&filePath[strlen(filePath)-4], ".m4p", 4) == 0) {
		[self _getAACArtwork];
	} else if (strncmp(&filePath[strlen(filePath)-4], ".mp3", 4) == 0) {
		[self _getMP3Artwork];
	}
}

@end
