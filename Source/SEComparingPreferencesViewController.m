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

#import "SEComparingPreferencesViewController.h"

NSString *SEExactComparisonPreferenceKey = @"SEExactComparison";
NSString *SEComparisonFieldsPreferenceKey = @"SEComparisonFields";

NSString *SEExactComparisonPreferenceChangeContext = @"SEExactComparisonPreferenceChangeContext";

@implementation SEComparingPreferencesViewController

#define NAME_KEY		@"name"
#define KEY_KEY			@"key"
#define ENABLED_KEY		@"enabled"

static NSArray *compareFields = nil;
+ (NSArray *)compareFields {
	if (!compareFields) {
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
		
		
		compareFields = [[NSArray alloc] initWithObjects:
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
			playCount,
			rating,
			nil];
	}
	return compareFields;
}

+ (void)registerDefaults {
	NSDictionary *enabled = [NSArray arrayWithObjects:@"title", @"album", @"artist", nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:FALSE], SEExactComparisonPreferenceKey,
		enabled, SEComparisonFieldsPreferenceKey, nil]];
}

+ (NSString *)nibName {
	return @"ComparingPreferences";
}

- (NSString *)label {
	return FSLocalizedString(@"Comparing", nil);
}

- (NSImage *)image {
	return [NSImage imageNamed:@"pref_comparing"];
}

- (void)awakeFromNib {
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:SEExactComparisonPreferenceKey
											   options:0
											   context:SEExactComparisonPreferenceChangeContext];
}

- (void)dealloc {
	if ([self isViewLoaded]) {
		[[NSUserDefaults standardUserDefaults] removeObserver:self
												   forKeyPath:SEExactComparisonPreferenceKey];	
	}
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SEExactComparisonPreferenceChangeContext) {
		[table display];
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[[self class] compareFields] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([[tableColumn identifier] isEqualToString:ENABLED_KEY]) {
		NSDictionary *compareFieldsSelection = [[[self class] compareFields] objectAtIndex:row];
		NSArray *savedValues = [[NSUserDefaults standardUserDefaults] objectForKey:SEComparisonFieldsPreferenceKey];
		return [NSNumber numberWithBool:[savedValues containsObject:[compareFieldsSelection objectForKey:KEY_KEY]]];
	} else {
		NSString *string = [[[[self class] compareFields] objectAtIndex:row] objectForKey:[tableColumn identifier]];
		NSColor *color;
		if ([[NSUserDefaults standardUserDefaults] boolForKey:SEExactComparisonPreferenceKey]) {
			color = [NSColor disabledControlTextColor];
		} else { color = [NSColor controlTextColor]; }
		return [[[NSAttributedString alloc] initWithString:string
												attributes:[NSDictionary dictionaryWithObject:color forKey:NSForegroundColorAttributeName]] autorelease];
	}	
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([[tableColumn identifier] isEqualToString:ENABLED_KEY]) {
		NSDictionary *compareFieldsSelection = [[[self class] compareFields] objectAtIndex:row];
		NSMutableArray *savedValues = [NSMutableArray arrayWithArray:
			[[NSUserDefaults standardUserDefaults] objectForKey:SEComparisonFieldsPreferenceKey]];
		
		[savedValues removeObject:[compareFieldsSelection objectForKey:KEY_KEY]];
		if ([value boolValue]) {
			[savedValues addObject:[compareFieldsSelection objectForKey:KEY_KEY]];
		}
		[[NSUserDefaults standardUserDefaults] setObject:savedValues forKey:SEComparisonFieldsPreferenceKey];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([[tableColumn identifier] isEqualToString:ENABLED_KEY]) { return TRUE; }
	else { return FALSE; }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:SEExactComparisonPreferenceKey]) {
		if ([cell respondsToSelector:@selector(setEnabled:)]) {
			[cell setEnabled:FALSE];
		}
	} else {
		if ([cell respondsToSelector:@selector(setEnabled:)]) {
			[cell setEnabled:TRUE];
		}		
	}
}

@end
