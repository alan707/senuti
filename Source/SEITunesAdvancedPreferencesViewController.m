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

#import "SEITunesAdvancedPreferencesViewController.h"

NSString *SECopyITunesMetadataPreferenceKey = @"SECopyITunesMetadata";

#define NAME_KEY		@"name"
#define KEY_KEY			@"key"
#define ENABLED_KEY		@"enabled"

@implementation SEITunesAdvancedPreferencesViewController

static NSArray *metadata = nil;
+ (NSArray *)metadata {
	if (!metadata) {
		NSMutableDictionary *title = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"title", KEY_KEY,
			FSLocalizedString(@"Title", nil), NAME_KEY,
			nil];
		NSMutableDictionary *album = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"album", KEY_KEY,
			FSLocalizedString(@"Album", nil), NAME_KEY,
			nil];
		NSMutableDictionary *artist = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"artist", KEY_KEY,
			FSLocalizedString(@"Artist", nil), NAME_KEY,
			nil];
		NSMutableDictionary *composer = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"composer", KEY_KEY,
			FSLocalizedString(@"Composer", nil), NAME_KEY,
			nil];
		NSMutableDictionary *genre = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"genre", KEY_KEY,
			FSLocalizedString(@"Genre", nil), NAME_KEY,
			nil];
		NSMutableDictionary *comment = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"comment", KEY_KEY,
			FSLocalizedString(@"Comment", nil), NAME_KEY,
			nil];
		NSMutableDictionary *playCount = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"playCount", KEY_KEY,
			FSLocalizedString(@"Play Count", nil), NAME_KEY,
			nil];
		NSMutableDictionary *lastPlayed = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"lastPlayed", KEY_KEY,
			FSLocalizedString(@"Last Played", nil), NAME_KEY,
			nil];
		NSMutableDictionary *year = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"year", KEY_KEY,
			FSLocalizedString(@"Year", nil), NAME_KEY,
			nil];
		NSMutableDictionary *trackNumber = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"trackNumber", KEY_KEY,
			FSLocalizedString(@"Track Number", nil), NAME_KEY,
			nil];
		NSMutableDictionary *totalTrackNumbers = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"totalTrackNumbers", KEY_KEY,
			FSLocalizedString(@"Total Tracks", nil), NAME_KEY,
			nil];
		NSMutableDictionary *discNumber = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"discNumber", KEY_KEY,
			FSLocalizedString(@"Disc Number", nil), NAME_KEY,
			nil];
		NSMutableDictionary *totalDiscs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"totalDiscs", KEY_KEY,
			FSLocalizedString(@"Total Discs", nil), NAME_KEY,
			nil];
		NSMutableDictionary *rating = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			@"rating", KEY_KEY,
			FSLocalizedString(@"Rating", nil), NAME_KEY,
			nil];
		
		
		metadata = [[NSArray alloc] initWithObjects:
			playCount,
			rating,
			title,
			album,
			artist,
			composer,
			genre,
			comment,
			lastPlayed,
			year,
			trackNumber,
			totalTrackNumbers,
			discNumber,
			totalDiscs,
			nil];
	}
	return metadata;
}

+ (void)registerDefaults {
	NSDictionary *enabled = [NSArray arrayWithObjects:@"rating", @"playCount", nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		enabled, SECopyITunesMetadataPreferenceKey, nil]];
}

+ (NSString *)nibName {
	return @"iTunesAdvancedPreferences";
}

- (NSString *)label {
	return @"iTunes";
}

- (NSImage *)image {
	return [NSImage imageNamed:@"pref_itunes"];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[[self class] metadata] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([[tableColumn identifier] isEqualToString:ENABLED_KEY]) {
		NSDictionary *metadataSelection = [[[self class] metadata] objectAtIndex:row];
		NSArray *savedValues = [[NSUserDefaults standardUserDefaults] objectForKey:SECopyITunesMetadataPreferenceKey];
		return [NSNumber numberWithBool:[savedValues containsObject:[metadataSelection objectForKey:KEY_KEY]]];
	} else {
		return [[[[self class] metadata] objectAtIndex:row] objectForKey:[tableColumn identifier]];
	}	
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([[tableColumn identifier] isEqualToString:ENABLED_KEY]) {
		NSDictionary *metadataSelection = [[[self class] metadata] objectAtIndex:row];
		NSMutableArray *savedValues = [NSMutableArray arrayWithArray:
			[[NSUserDefaults standardUserDefaults] objectForKey:SECopyITunesMetadataPreferenceKey]];
		
		[savedValues removeObject:[metadataSelection objectForKey:KEY_KEY]];
		if ([value boolValue]) {
			[savedValues addObject:[metadataSelection objectForKey:KEY_KEY]];
		}
		[[NSUserDefaults standardUserDefaults] setObject:savedValues forKey:SECopyITunesMetadataPreferenceKey];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([[tableColumn identifier] isEqualToString:ENABLED_KEY]) { return TRUE; }
	else { return FALSE; }
}

@end
