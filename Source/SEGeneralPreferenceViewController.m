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

#import "SEGeneralPreferenceViewController.h"

/* These constants cannot be easily changed.  The string values are also located in nib files.
 * If changing them, look very carefully in the nib files to make sure all occurrences of the
 * string have been changed. */
NSString *SESourceListTextSizeKey = @"SESourceListTextSize"; // GeneralPreferences.nib, SourceList.nib
NSString *SETrackListTextSizeKey = @"SETrackListTextSize"; // GeneralPreferences.nib, TrackList.nib
NSString *SEPauseITunesOnPlayKey = @"SEPauseITunesOnPlay"; // GeneralPreferences.nib

@implementation SEGeneralPreferenceViewController

+ (void)registerDefaults {
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:12], SESourceListTextSizeKey,
		[NSNumber numberWithInt:12], SETrackListTextSizeKey,
		[NSNumber numberWithBool:TRUE], SEPauseITunesOnPlayKey, nil]];
}

+ (NSString *)nibName {
	return @"GeneralPreferences";
}

- (NSString *)label {
	return FSLocalizedString(@"General", nil);
}

- (NSImage *)image {
	return [NSImage imageNamed:@"pref_general"];
}

@end
