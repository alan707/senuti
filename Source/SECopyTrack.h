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

typedef enum _SEDuplicateHandlingType {
	SERenameDuplicatesType = 0,
	SESkipDuplicatesType = 1,
	SEOverwriteDuplicatesType = 2,
	SEAskDuplicatesType = 3
} SEDuplicateHandlingType;

typedef enum _SEReferenceHandlingType {
	SEReferenceOnlyReferenceType = 0,
	SECopyFileReferenceType = 1,
	SESkipReferenceType = 2
} SEReferenceHandlingType;

@protocol SEPlaylist;
@interface SECopyTrack : NSObject {
	BOOL organize;
	BOOL copyMetadata;
	NSString *destinationPath;
	NSString *destinationRoot;
	id <SETrack> reference;
	id <SETrack> origTrack;
	id <SETrack> dupTrack;
	id <SEPlaylist> destinationPlaylist;
	SEDuplicateHandlingType duplicateHandling;
}

+ (NSArray *)copyTracksFromArray:(NSArray *)standardTracks;
+ (id)trackWithOrigin:(id <SETrack>)track;

- (id)initWithOrigin:(id <SETrack>)track;

- (id <SETrack>)originTrack; // the track being copied

- (id <SETrack>)reference; // the track a reference is being created from
- (void)setReference:(id <SETrack>)track;

- (id <SETrack>)duplicateTrack; // the track that was created as a duplicate when copied
- (void)setDuplicateTrack:(id <SETrack>)track;

- (BOOL)organize;
- (void)setOrganize:(BOOL)organize;

- (BOOL)copyMetadata;
- (void)setCopyMetadata:(BOOL)flag;

- (SEDuplicateHandlingType)duplicateHandling;
- (void)setDuplicateHandling:(SEDuplicateHandlingType)type;

// This is the directory in which the file should go, but
// it may end up in a sub directory.  The destination
// path indicates the full path for the file.
- (NSString *)destinationRoot;
- (void)setDestinationRoot:(NSString *)path;

// This is the full path of the file.  The destination
// root indicates the directory under which the file
// should end up.
- (NSString *)destinationPath;
- (void)setDestinationPath:(NSString *)path;

- (id <SEPlaylist>)destinationPlaylist;
- (void)setDestinationPlaylist:(id <SEPlaylist>)playlist;

@end
