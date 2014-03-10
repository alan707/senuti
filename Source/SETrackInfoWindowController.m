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

#import "SETrackInfoWindowController.h"

#import "SEInterfaceController.h"
#import "SEMainWindowController.h"

#import "SETrack.h"
#import "SEContentController.h"
#import "SETransparentImageView.h"
#import "SEMultiImageView.h"

#define INVALID_SELECTION_TAB 0
#define TRACK_INFO_TAB 1

static void *SESelectedContentObjectsChangeContext = @"SESelectedContentObjectsChangeContext";

@interface SETrackInfoWindowController (PRIVATE)
- (void)updateContent;
@end

@implementation SETrackInfoWindowController

+ (NSString *)nibName {
	return @"TrackInfo";
}

- (void)awakeFromNib {
	[[[senuti interfaceController] mainWindowController] addObserver:self forKeyPath:@"contentController.selectedObjects" options:0 context:SESelectedContentObjectsChangeContext];
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setLenient:YES];
	
	NSView *replace = rating;
	rating = [[SEMultiImageView alloc] initWithFrame:[replace frame]];
	[[replace superview] replaceSubview:replace with:rating];
	[rating setImage:[NSImage imageNamed:@"white_star"]];
	
	[created setFormatter:dateFormatter];
	[lastPlayed setFormatter:dateFormatter];
	[lastModified setFormatter:dateFormatter];				
	
	[self updateContent];
}

- (void)dealloc {
	[self removeControllerObservers];
	[super dealloc];
}

- (void)removeControllerObservers {
	if ([self isWindowLoaded]) {
		[[[senuti interfaceController] mainWindowController] removeObserver:self forKeyPath:@"contentController.selectedObjects"];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SESelectedContentObjectsChangeContext) {
		[self updateContent];
	}
}

- (void)updateContent {
	NSArray *objects = [[[[senuti interfaceController] mainWindowController] contentController] selectedObjects];
	if ([objects count] == 1) {
		[tabView selectTabViewItemAtIndex:TRACK_INFO_TAB];
		id <SETrack> track = [objects objectAtIndex:0];

		if ([track conformsToProtocol:@protocol(SETrack)]) {
			[image setImage:[track artwork]];
			[title setStringValue:[track title]];
			[artist setStringValue:[track artist]];
			[album setStringValue:[track album]];
			[genre setStringValue:[track genre]];
			[year setObjectValue:[[NSValueTransformer valueTransformerForName:@"SENotZeroTransformer"] transformedValue:[NSNumber numberWithInt:[track year]]]];
			[length setObjectValue:[[NSValueTransformer valueTransformerForName:@"SETimeTransformer"] transformedValue:[NSNumber numberWithInt:[track length]]]];
			if ([track startTime]) { [start setObjectValue:[[NSValueTransformer valueTransformerForName:@"SETimeTransformer"] transformedValue:[NSNumber numberWithInt:[track startTime]]]]; }
			else { [start setObjectValue:nil]; }
			if ([track startTime]) { [end setObjectValue:[[NSValueTransformer valueTransformerForName:@"SETimeTransformer"] transformedValue:[NSNumber numberWithInt:[track stopTime]]]]; }
			else { [end setObjectValue:nil]; }
			[size setObjectValue:[[NSValueTransformer valueTransformerForName:@"SESizeTransformer"] transformedValue:[NSNumber numberWithInt:[track size]]]];
			[type setStringValue:[track type]];
			[bitRate setObjectValue:[[NSValueTransformer valueTransformerForName:@"SEKBPSTransformer"] transformedValue:[NSNumber numberWithInt:[track bitRate]]]];
			[playCount setObjectValue:[NSNumber numberWithInt:[track playCount]]];
			[comment setStringValue:[track comment]];
			[location setStringValue:[track path]];
			[disc setObjectValue:[[NSValueTransformer valueTransformerForName:@"SETupleTransformer"] transformedValue:[track discData]]];
			[trackNumber setObjectValue:[[NSValueTransformer valueTransformerForName:@"SETupleTransformer"] transformedValue:[track trackData]]];
			[created setObjectValue:[track dateAdded]];
			[lastPlayed setObjectValue:[track lastPlayed]];
			[lastModified setObjectValue:[track lastModified]];
			[rating setObjectValue:[NSNumber numberWithInt:[track rating]]];
		}		
	} else {
		[tabView selectTabViewItemAtIndex:INVALID_SELECTION_TAB];
		if ([objects count] == 0) { [invalidTextField setStringValue:FSLocalizedString(@"Nothing selected", nil)]; }
		else { [invalidTextField setStringValue:FSLocalizedString(@"Select a single item", nil)]; }
	}
}

@end
