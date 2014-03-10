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

#import "SEAdvancedPreferenceViewController.h"
#import "SEAutomaticUpdatesPreferenceViewController.h"
#import "SEITunesAdvancedPreferencesViewController.h"
#import "SEComparingPreferencesViewController.h"

#define SELECTED_ADVANCED_PREF_INDEX	@"SESelectedAdvancedPrefIndex"

@implementation SEAdvancedPreferenceViewController

+ (void)registerDefaults {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:0], SELECTED_ADVANCED_PREF_INDEX, nil]];
	
	[SEAutomaticUpdatesPreferenceViewController registerDefaults];
	[SEITunesAdvancedPreferencesViewController registerDefaults];
	[SEComparingPreferencesViewController registerDefaults];
}

+ (NSString *)nibName {
	return @"AdvancedPreferences";
}

- (NSString *)label {
	return FSLocalizedString(@"Advanced", nil);
}

- (NSImage *)image {
	return [NSImage imageNamed:@"pref_advanced"];
}

- (void)awakeFromNib {
	SEViewController <FSPreferenceViewController> *automaticUpdates;
	SEViewController <FSPreferenceViewController> *advancedITunes;
	SEViewController <FSPreferenceViewController> *comparing;

	automaticUpdates = [[[SEAutomaticUpdatesPreferenceViewController alloc] init] autorelease];
	advancedITunes = [[[SEITunesAdvancedPreferencesViewController alloc] init] autorelease];
	comparing = [[[SEComparingPreferencesViewController alloc] init] autorelease];

	[advancedPreferences setContent:[NSArray arrayWithObjects:automaticUpdates, advancedITunes, comparing, nil]];
	[advancedPreferences setSelectionIndex:[[[NSUserDefaults standardUserDefaults] objectForKey:SELECTED_ADVANCED_PREF_INDEX] intValue]];
	[self tableViewSelectionDidChange:nil]; // make sure the tab view is updated

	[advancedPreferenceTable setDelegate:self]; // set delegate after updating selection index
	[advancedPreferenceTable setIntercellSpacing:NSMakeSize(0, 0)];
	[[[advancedPreferenceTable tableColumns] objectAtIndex:0] setDataCell:[[[AIImageTextCell alloc] init] autorelease]];	
	
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {

	SEViewController *advancedPreference = [[advancedPreferences selectedObjects] firstObject];
	if (advancedPreference) {
		NSView *newView;
		NSRect frame;
		float offset;
		
		newView = [advancedPreference view];
		frame = [newView frame];
		offset = ([advancedPreferenceView frame].size.width - [newView frame].size.width) / 2;
		frame.origin.x = floor(offset);
		offset = ([advancedPreferenceView frame].size.height - [newView frame].size.height);
		frame.origin.y = floor(offset);
		[newView setFrame:frame];

		// remove any subviews
		while ([[advancedPreferenceView subviews] count]) { [[[advancedPreferenceView subviews] objectAtIndex:0] removeFromSuperview]; }
		
		// add our view
		[advancedPreferenceView addSubview:newView];
	}
	
	// save the index
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[advancedPreferences selectionIndex]] forKey:SELECTED_ADVANCED_PREF_INDEX];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([cell isKindOfClass:[AIImageTextCell class]]) {
		[cell setImage:[[[advancedPreferences arrangedObjects] objectAtIndex:row] image]];
	}
}

@end
