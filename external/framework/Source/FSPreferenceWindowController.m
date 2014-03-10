/* 
 * The FadingRed Shared Framework (FSFramework) is the legal property of its developers, whose names
 * are listed in the copyright file included with this source distribution.
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

#import "FSPreferenceWindowController.h"
#import "FSViewController.h"
#import "FSControlledView.h"
#import "FSArrayAdditions.h"

#define FRAME_AUTOSAVE_NAME			([NSString stringWithFormat:@"FSPreferenceWindow Frame %@", [self autosaveName]])
#define IDENTIFIER_AUTOSAVE_NAME	([NSString stringWithFormat:@"FSPreferenceWindow SelectedItemIdentifier %@", [self autosaveName]])

@interface FSPreferenceToolbarItem : NSToolbarItem {
	FSViewController <FSPreferenceViewController> *viewController;
}
- (FSViewController <FSPreferenceViewController> *)preferenceViewController;
- (void)setPreferenceViewController:(FSViewController <FSPreferenceViewController> *)viewController;
@end

@implementation FSPreferenceToolbarItem : NSToolbarItem
- (FSViewController <FSPreferenceViewController> *)preferenceViewController {
	return viewController;
}
- (void)setPreferenceViewController:(FSViewController <FSPreferenceViewController> *)aController {
	if (aController != viewController) {
		[viewController release];
		viewController = [aController retain];
	}
}
- (void)dealloc {
	[viewController release];
	[super dealloc];
}
@end

@interface FSPreferenceWindowController (PRIVATE)
- (NSString *)selectedIdentifier;
- (void)windowWillResignKey:(NSNotification *)notificaiton;
- (void)setSelectedIdentifier:(NSString *)sel;
- (void)changePreferenceView:(id)sender;
- (void)saveSelectedIdentifierIfNeeded;
- (void)saveFrameIfNeeded;
- (void)updateForAutosaveName;
- (void)updateTitle;
@end

@implementation FSPreferenceWindowController

- (id)init {
	if (self = [super init]) {
		views = [[NSMutableArray alloc] init];
		toolbar = [[NSToolbar alloc] initWithIdentifier:@"Preference Toolbar"];
		[toolbar setAutosavesConfiguration:YES];
		[toolbar setDelegate:self];
		[toolbar setAllowsUserCustomization:NO];
		[self setShouldCascadeWindows:NO];
		if ([self isWindowLoaded]) {
			[[self window] setToolbar:toolbar];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillResignKey:) name:NSWindowDidResignKeyNotification object:[self window]];
		}
	}
	return self;
}

- (void)windowDidLoad {
	
	[[self window] setToolbar:toolbar];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillResignKey:) name:NSWindowDidResignKeyNotification object:[self window]];
	
	[self updateTitle];
	[self updateForAutosaveName]; // update for the autosave name
	
	// if nothing's selected, select the first one
	if (![self selectedIdentifier] && [[toolbar items] count]) {
		[self changePreferenceView:[[toolbar items] objectAtIndex:0]];
		[toolbar setSelectedItemIdentifier:[[[toolbar items] objectAtIndex:0] itemIdentifier]];
	}
	
	[super windowDidLoad];
}

- (void)windowWillResignKey:(NSNotification *)notificaiton {
	[self saveFrameIfNeeded];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[toolbar release];
	[views release];
	[title release];
	[selected release];
	[autosaveName release];
	[super dealloc];
}

#pragma mark autosaving
// ----------------------------------------------------------------------------------------------------
// autosaving
// ----------------------------------------------------------------------------------------------------

- (NSString *)autosaveName {
	return autosaveName;
}

- (void)setAutosaveName:(NSString *)name {
	if (autosaveName != name) {
		[autosaveName release];
		autosaveName = [name copy];
		if ([self isWindowLoaded]) { [self updateForAutosaveName]; }
	}
}

- (void)updateForAutosaveName {
	NSDictionary *savedFrame;
	NSString *selectedItemIdentifier;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (savedFrame = [defaults objectForKey:FRAME_AUTOSAVE_NAME]) {		
		[[self window] setFrame:NSMakeRect([[savedFrame objectForKey:@"X Origin"] floatValue],
										   [[savedFrame objectForKey:@"Y Max Origin"] floatValue] - [[self window] frame].size.height,
										   [[self window] frame].size.width,
										   [[self window] frame].size.height) display:YES];		
	}
	
	selectedItemIdentifier = [defaults objectForKey:IDENTIFIER_AUTOSAVE_NAME];
	if (selectedItemIdentifier) {
		NSEnumerator *enumerator = [[toolbar items] objectEnumerator];
		FSPreferenceToolbarItem *toolbarItem;
		while (toolbarItem = [enumerator nextObject]) {
			if ([[toolbarItem itemIdentifier] isEqualToString:selectedItemIdentifier]) {
				[self changePreferenceView:toolbarItem];
				[toolbar setSelectedItemIdentifier:[toolbarItem itemIdentifier]];
			}
		}
	}
}

- (void)saveFrameIfNeeded {
	if (autosaveName) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithFloat:[[self window] frame].origin.x], @"X Origin",
			[NSNumber numberWithFloat:[[self window] frame].origin.y + [[self window] frame].size.height], @"Y Max Origin",
			nil, nil] forKey:FRAME_AUTOSAVE_NAME];
	}	
}

- (void)saveSelectedIdentifierIfNeeded {
	if (autosaveName) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:[self selectedIdentifier] ? [self selectedIdentifier] : @""
					 forKey:IDENTIFIER_AUTOSAVE_NAME];
	}
}

#pragma mark getter/setter methods
// ----------------------------------------------------------------------------------------------------
// getter/setter methods
// ----------------------------------------------------------------------------------------------------

- (NSString *)selectedIdentifier {
	return selected;
}

- (void)setSelectedIdentifier:(NSString *)sel {
	if (sel != selected) {
		[selected release];
		selected = [sel retain];
	}
}

- (void)setTitle:(NSString *)new_title {
	if (title != new_title) {
		[title release];
		title = [new_title retain];
		if ([self isWindowLoaded]) { [self updateTitle]; }
	}
}

- (NSString *)title {
	return title;
}

- (void)updateTitle {
	if ([self title] && [views count]) {
		[[self window] setTitle:[NSString stringWithFormat:@"%@%@", [self title], [[views objectAtIndex:0] label]]];
	} else {
		[[self window] setTitle:@""];
	}
}

#pragma mark adding/changing views
// ----------------------------------------------------------------------------------------------------
// adding/changing views
// ----------------------------------------------------------------------------------------------------

- (void)addView:(FSViewController <FSPreferenceViewController> *)view {
	[views addObject:view];
	[toolbar insertItemWithItemIdentifier:[view label] atIndex:[[toolbar items] count]];
}

- (void)changePreferenceView:(id)sender {
	if ([sender itemIdentifier] != [self selectedIdentifier])
	{
		[self setSelectedIdentifier:[sender itemIdentifier]];
		
		// set title stuff
		if (title) { [[self window] setTitle:[NSString stringWithFormat:@"%@%@", title, [sender itemIdentifier]]]; }
		else { [[self window] setTitle:[sender itemIdentifier]]; }
		
		// declare some stuff
		NSView *content = [[NSView alloc] init];
		FSViewController <FSPreferenceViewController> *newViewController = [sender preferenceViewController];
		NSView *newView = [newViewController view];
		
		float height_difference = [newView frame].size.height - [[[self window] contentView] frame].size.height;
		float width_difference = [[[self window] contentView] frame].size.width - [newView frame].size.width;
				
		// make view blank and resize the window (nicely)
		[[self window] setContentView:[[[NSView alloc] init] autorelease]];
		[[self window] setFrame:NSMakeRect([[self window] frame].origin.x, [[self window] frame].origin.y - height_difference, [[self window] frame].size.width, [[self window] frame].size.height + height_difference) display:YES animate:YES];

		// set up internal view
		[newView setFrame:NSMakeRect((int)width_difference / 2, 0, [newView frame].size.width, [newView frame].size.height)]; // approximate centering by using int so that pixles aren't funky
		[newView setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin];
		
		// show the view we want to be shown
		[[self window] setContentView:content];
		[content addSubview:newView];
		
		// release things
		[content release];
		
		[self saveSelectedIdentifierIfNeeded]; // autosave?
	}
}

#pragma mark toolbar
// ----------------------------------------------------------------------------------------------------
// toolbar
// ----------------------------------------------------------------------------------------------------

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag; {
	int counter;
	for (counter = 0; counter < [views count]; counter++)
	{
		FSViewController <FSPreferenceViewController> *viewController = [views objectAtIndex:counter];
		if ([[viewController label] isEqualToString:itemIdentifier])
		{
			FSPreferenceToolbarItem *item = [[[FSPreferenceToolbarItem alloc] initWithItemIdentifier:[viewController label]] autorelease];
			[item setLabel:[viewController label]];
			[item setImage:[viewController image]];
			[item setPreferenceViewController:viewController];
			[item setTarget:self];
			[item setAction:@selector(changePreferenceView:)];
			return item;
		}
	}
	// all other cases
	return nil;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
	return [views arrayByPerformingSelectorOnObjects:@selector(label)];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
	return [views arrayByPerformingSelectorOnObjects:@selector(label)];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return [views arrayByPerformingSelectorOnObjects:@selector(label)];
}

@end
