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

#import "SECopyLocationViewController.h"
#import "SELibraryController.h"
#import "SEITunesLibrary.h"

#define DESKTOP_LOCATION	[NSString stringWithFormat:@"~/%@", FSLocalizedString(@"Desktop", nil)]
#define HOME_LOCATION		@"~"
#define CHOICE_INDEX		4
#define NAME_KEY			@"name"
#define SELECTED_LOCATION	@"selectedLocation"

static void *SECopyLocationChangeContext = @"SECopyLocationChangeContext";
static void *SECopyLocationSelectedLocationBindingContext = @"SECopyLocationSelectedLocationBindingContext";

@interface SECopyLocationViewController (PRIVATE)
- (void)_setSelectedLocation:(NSString *)location informObservers:(BOOL)inform;
- (SEITunesLibrary *)iTunesLibrary;
- (void)waitForITunes:(NSTimer *)timer;
- (void)updateButtonForSelection;
- (void)setLocationToITunesMusicFolder;
- (IBAction)changeCopyLocation:(id)sender;
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@implementation SECopyLocationViewController

+ (void)initialize {
	[self exposeBinding:SELECTED_LOCATION];
}

+ (NSString *)nibName {
	return @"CopyLocation";
}

- (id)init {
	if (self = [super init]) {
		delayed = [[NSMutableArray alloc] init];
		observedObjects = [[NSMutableDictionary alloc] init];
		observedKeyPaths = [[NSMutableDictionary alloc] init];
		enabled = TRUE;
	}
	return self;
}

- (void)dealloc {
	[self unbind:SELECTED_LOCATION];
	if ([self isViewLoaded]) {
		[locations removeObserver:self
					   forKeyPath:@"selection"];
	}
	
	[delayed release];
	[observedObjects release];
	[observedKeyPaths release];
	[choice release];
	[iTunes release];
	[desktop release];
	[home release];
	[other release];
	[super dealloc];
}

- (void)awakeFromNib {
	iTunes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"::%@|itunes_folder", FSLocalizedString(@"iTunes Music Folder", nil)], NAME_KEY, nil];
	desktop = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"::%@|desktop", FSLocalizedString(@"Desktop", nil)], NAME_KEY, nil];
	home = [[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"::%@|home", FSLocalizedString(@"Home Folder", nil)], NAME_KEY, nil];
	other = [[NSDictionary alloc] initWithObjectsAndKeys:FSLocalizedString(@"Other...", nil), NAME_KEY, nil];
	
	[locations addObject:iTunes];
	[locations addObject:desktop];
	[locations addObject:home];
	[locations addObject:[NSDictionary dictionaryWithObject:@"" forKey:NAME_KEY]];
	if (choice) { [locations addObject:choice]; }
	[locations addObject:other];
	[self updateButtonForSelection];
	
	[locations addObserver:self
				forKeyPath:@"selection"
				   options:0
				   context:SECopyLocationChangeContext];
	
	[button setEnabled:enabled];
}


#pragma mark interface related
// ----------------------------------------------------------------------------------------------------
// interface related
// ----------------------------------------------------------------------------------------------------

- (void)setLocationToITunesMusicFolder {
	SEITunesLibrary *iTunesLibrary = [self iTunesLibrary];
	if (iTunesLibrary) {
		[self _setSelectedLocation:[[[iTunesLibrary musicFolderLocation] path] stringByAbbreviatingWithTildeInPath] informObservers:TRUE];
	} else {
		SEL selector = @selector(setLocationToITunesMusicFolder);
		[delayed addObject:NSStringFromSelector(selector)];
	}	
}

- (void)updateButtonForSelection {
	
	if (![self selectedLocation]) { return; }
	
	if ([[self selectedLocation] isEqualToString:DESKTOP_LOCATION]) {
		[locations setSelectedObjects:[NSArray arrayWithObject:desktop]];
		return;
	}
	
	if ([[self selectedLocation] isEqualToString:HOME_LOCATION]) {
		[locations setSelectedObjects:[NSArray arrayWithObject:home]];
		return;
	}
	
	SEITunesLibrary *iTunesLibrary = [self iTunesLibrary];
	if (iTunesLibrary) {
		if ([[self selectedLocation] isEqualToString:[[[iTunesLibrary musicFolderLocation] path] stringByAbbreviatingWithTildeInPath]]) {
			[locations setSelectedObjects:[NSArray arrayWithObject:iTunes]];
			return;
		}
	} else {
		SEL selector = @selector(updateButtonForSelection);
		[delayed addObject:NSStringFromSelector(selector)];
		return;
	}
	
	// the default is to always update the choice
	// to whatever they want it to be
	if (!choice) {
		choice = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[self selectedLocation], NAME_KEY, nil];
		[locations insertObject:choice atArrangedObjectIndex:CHOICE_INDEX];
	} else {
		[choice setObject:[self selectedLocation] forKey:NAME_KEY];
	}
	[locations setSelectedObjects:[NSArray arrayWithObject:choice]];
}


#pragma mark bindings
// ----------------------------------------------------------------------------------------------------
// bindings
// ----------------------------------------------------------------------------------------------------

- (void)bind:(NSString *)name toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options {
    if ([name isEqualToString:SELECTED_LOCATION]) {
		[observable addObserver:self
					 forKeyPath:keyPath 
						options:0
						context:SECopyLocationSelectedLocationBindingContext];
		
		[observedObjects setObject:observable forKey:SELECTED_LOCATION];
		[observedKeyPaths setObject:keyPath forKey:SELECTED_LOCATION];
	}
	[super bind:name toObject:observable withKeyPath:keyPath options:options];
}


- (void)unbind:(NSString *)name {
	if (![name isEqualToString:SELECTED_LOCATION]) { return; }
	
	id object = [observedObjects objectForKey:name];
	NSString *keyPath = [observedKeyPaths objectForKey:name];
	[object removeObserver:self forKeyPath:keyPath];
	[observedObjects removeObjectForKey:name];
	[observedKeyPaths removeObjectForKey:name];
	
	[super unbind:name];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SECopyLocationChangeContext) {
		id selection = [[locations selectedObjects] firstObject];
		if (selection == iTunes) {
			[self setLocationToITunesMusicFolder];
		} else if (selection == desktop) {
			[self _setSelectedLocation:DESKTOP_LOCATION informObservers:TRUE];
		} else if (selection == home) {
			[self _setSelectedLocation:HOME_LOCATION informObservers:TRUE];
		} else if (selection == choice) {
			[self _setSelectedLocation:[choice objectForKey:NAME_KEY] informObservers:TRUE];
		} else if (selection == other) {
			[self changeCopyLocation:nil];
		} else {
			[NSException raise:@"InvalidSelection" format:@"Selection not implemented for copy location"];
		}		
	} else if (context == SECopyLocationSelectedLocationBindingContext) {
		id object = [observedObjects objectForKey:SELECTED_LOCATION];
		NSString *keyPath = [observedKeyPaths objectForKey:SELECTED_LOCATION];
		[self setSelectedLocation:[object valueForKey:keyPath]];
	}
}


#pragma mark itunes library
// ----------------------------------------------------------------------------------------------------
// itunes library
// ----------------------------------------------------------------------------------------------------

- (void)waitForITunes:(NSTimer *)timer {
	SEITunesLibrary *iTunesLibrary = [[senuti libraryController] iTunesLibrary];
	if (iTunesLibrary) {
		[waitForITunesTimer invalidate];
		[waitForITunesTimer release];
		waitForITunesTimer = nil;
		
		[button setEnabled:enabled];
		[spinner stopAnimation:nil];

		NSString *selectorString;
		NSEnumerator *selectorEnumerator = [delayed objectEnumerator];
		while (selectorString = [selectorEnumerator nextObject]) {
			SEL selector = NSSelectorFromString(selectorString);
			[self performSelector:selector];
		}
	} else {
		[button setEnabled:NO];
		[spinner startAnimation:nil];
	}
}

- (SEITunesLibrary *)iTunesLibrary {
	if (!waitForITunesTimer) {
		SEITunesLibrary *iTunesLibrary = [[senuti libraryController] iTunesLibrary];
		if (iTunesLibrary) { return iTunesLibrary; }
		else {
			waitForITunesTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(waitForITunes:) userInfo:nil repeats:YES] retain];
		}		
	}
	return nil;
}


#pragma mark selected location
// ----------------------------------------------------------------------------------------------------
// selected location
// ----------------------------------------------------------------------------------------------------

- (NSString *)selectedLocation {
	return selectedLocation;
}

- (void)setSelectedLocation:(NSString *)location {
	[self _setSelectedLocation:location informObservers:FALSE];
	[self updateButtonForSelection];
}

- (void)setSelectedLocationToDefault {
	[self setLocationToITunesMusicFolder];
}

- (void)_setSelectedLocation:(NSString *)location informObservers:(BOOL)inform {
	if (selectedLocation != location) {
		[selectedLocation release];
		selectedLocation = [location retain];

		if (inform) {
			id object = [observedObjects objectForKey:SELECTED_LOCATION];
			NSString *keyPath = [observedKeyPaths objectForKey:SELECTED_LOCATION];
			[object setValue:location forKeyPath:keyPath];
		}		
	}
}


#pragma mark other dialog
// ----------------------------------------------------------------------------------------------------
// other dialog
// ----------------------------------------------------------------------------------------------------

- (IBAction)changeCopyLocation:(id)sender {
	NSString *location = [self selectedLocation];
	NSOpenPanel *open = [NSOpenPanel openPanel];
	[open setCanChooseFiles:NO];
	[open setCanChooseDirectories:YES];
	[open setAllowsMultipleSelection:NO];
	[open setPrompt:FSLocalizedString(@"Choose", @"Prompt in open panel for choosing a new copy location")];
	[open beginSheetForDirectory:[location stringByDeletingLastPathComponent]
							file:nil
						   types:nil
				  modalForWindow:[[self view] window]
				   modalDelegate:self
				  didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
					 contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[NSApp endSheet:sheet returnCode:returnCode];
	[sheet close];
	
    if (returnCode) {
		NSString *newValue = [[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath];
		[self _setSelectedLocation:newValue informObservers:TRUE];
    }
	[self updateButtonForSelection];
}

@end
