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

#import "SECopyingPreferenceViewController.h"
#import "SELibraryController.h"

#import "SEITunesLibrary.h"
#import "SELibrary.h"
#import "SEPlaylist.h"
#import "SECopyTrack.h"
#import "SECopyLocationViewController.h"

/* These constants cannot be easily changed.  The string values are also located in nib files.
 * If changing them, look very carefully in the nib files to make sure all occurrences of the
 * string have been changed. */
NSString *SEAskCopyLocationPreferenceKey = @"SEAskCopyLocation"; // CopyingPreferences.nib
NSString *SECopyLocationPreferenceKey = @"SECopyLocation"; // CopyingPreferences.nib
NSString *SEDuplicateFileHandlingPreferenceKey = @"SEDuplicateFileHandling"; // CopyingPreferences.nib
NSString *SEOrganizeCopiedTracksPreferenceKey = @"SEOrganizeCopiedTracks"; // CopyingPreferences.nib
NSString *SEAddToITunesPreferenceKey = @"SEAddToITunes"; // CopyingPreferences.nib, SetupAssistant.nib
NSString *SEAddToPlaylistPreferenceKey = @"SEAddToPlaylist"; // CopyingPreferences.nib
NSString *SEAddToPlaylistNamedPreferenceKey = @"SEAddToPlaylistNamed"; // CopyingPreferences.nib
NSString *SEReferenceHandingPreferenceKey = @"SEReferenceHanding"; // CopyingPreferences.nib
NSString *SECopyMetadataPreferenceKey = @"SECopyMetadata"; // CopyingPreferences.nib

@implementation SECopyingPreferenceViewController

+ (void)registerDefaults {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:FALSE], SEAskCopyLocationPreferenceKey,
		[NSNumber numberWithInt:SERenameDuplicatesType], SEDuplicateFileHandlingPreferenceKey,
		[NSNumber numberWithBool:TRUE], SEOrganizeCopiedTracksPreferenceKey,
		[NSNumber numberWithBool:FALSE], SEAddToITunesPreferenceKey,
		[NSNumber numberWithBool:FALSE], SEAddToPlaylistPreferenceKey,
		[NSNumber numberWithInt:SEReferenceOnlyReferenceType], SEReferenceHandingPreferenceKey,
		[NSNumber numberWithBool:FALSE], SECopyMetadataPreferenceKey,
		@"Senuti", SEAddToPlaylistNamedPreferenceKey, nil]];
}

+ (NSString *)nibName {
	return @"CopyingPreferences";
}

- (NSString *)label {
	return FSLocalizedString(@"Copying", nil);
}

- (NSImage *)image {
	return [NSImage imageNamed:@"pref_copying"];
}

- (void)awakeFromNib {
	[NSTimer scheduledTimerWithTimeInterval:0.1
									 target:self
								   selector:@selector(setupPlaylists:)
								   userInfo:nil
									repeats:YES];

	[copyLocationController bind:@"selectedLocation"
						toObject:[NSUserDefaults standardUserDefaults]
					 withKeyPath:SECopyLocationPreferenceKey
						 options:nil];
	[[copyLocationController view] setFrame:[copyLocationView frame]];
	[[copyLocationView superview] replaceSubview:copyLocationView with:[copyLocationController view]];
}

- (void)dealloc {
	[copyLocationController unbind:@"selectedLocation"];
	[super dealloc];
}

- (void)setupPlaylists:(NSTimer*)timer {
	if ([[senuti libraryController] iTunesLibrary]) {
		[spinner stopAnimation:nil];
		id <SEPlaylist> playlist;
		NSEnumerator *playlistEnumerator = [[[[senuti libraryController] iTunesLibrary] playlists] objectEnumerator];
		while (playlist = [playlistEnumerator nextObject]) {
			if ([playlist type] == SEStandardPlaylistType) {
				[playlists addObject:playlist];
			}
		}
		[playlists addObject:[NSDictionary dictionaryWithObject:@"" forKey:@"name"]];
		[playlists addObject:[NSDictionary dictionaryWithObject:@"Senuti" forKey:@"name"]];
		[timer invalidate];
	} else {
		[spinner startAnimation:nil];
	}	
}

#pragma mark copy location changes
// ----------------------------------------------------------------------------------------------------
// copy location changes
// ----------------------------------------------------------------------------------------------------

- (IBAction)changeCopyLocation:(id)sender {
	NSString *currentPreferenceValue = [[[NSUserDefaults standardUserDefaults] objectForKey:SECopyLocationPreferenceKey] stringByExpandingTildeInPath];	
	NSOpenPanel *open = [NSOpenPanel openPanel];
	[open setCanChooseFiles:NO];
	[open setCanChooseDirectories:YES];
	[open setAllowsMultipleSelection:NO];
	[open setPrompt:FSLocalizedString(@"Choose", @"Prompt in open panel for choosing a new copy location")];
	[open beginSheetForDirectory:[currentPreferenceValue stringByDeletingLastPathComponent]
							file:nil
						   types:nil
				  modalForWindow:[[self view] window]
				   modalDelegate:self
				  didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
					 contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[NSApp endSheet:sheet returnCode:returnCode];
	[sheet close];
	
    if (returnCode)
    {
		NSString *newValue = [[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath];
		[[NSUserDefaults standardUserDefaults] setObject:newValue forKey:SECopyLocationPreferenceKey];
    }
}

@end
