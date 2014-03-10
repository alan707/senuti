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

#import "SEMenuController.h"

#import "SEInterfaceController.h"
#import "SEMainWindowController.h"
#import "SELibraryController.h"
#import "SECopyController.h"
#import "SECopyingPreferenceViewController.h"

#import "SELibrary.h"
#import "SEPlaylist.h"
#import "SEITunesLibrary.h"

#define DEVICES_MENU_INITIAL_IEM_COUNT 2

static void *SEMainWindowVisibleTableColumnsChangeContext = @"SEMainWindowVisibleTableColumnsChangeContext";
static void *SEMainWindowAvailableTableColumnsChangeContext = @"SEMainWindowAvailableTableColumnsChangeContext";
static void *SESourceListSelectedPlaylistChangeContext = @"SESourceListSelectedPlaylistChangeContext";
static void *SEAvailableFilterLibrariesChangeContext = @"SEAvailableFilterLibrariesChangeContext";
static void *SECopyLocationAskChangeContext = @"SECopyLocationAskChangeContext";

@interface SEMenuController (PRIVATE)
- (void)updateTransferMenuItemTitle;

- (void)rebuildColumnsMenu;
- (void)updateColumnsMenuStates;
- (void)updateEnabledOfStaticMenuItems;
- (void)keyWindowChange:(NSNotification *)notification;

- (void)rebuildFilterLibraryMenu;
- (void)filterLibrary:(NSMenuItem *)sender;
- (void)informAboutFilteringLibraries;

- (BOOL)canEject;
- (BOOL)canCopy;
@end

@implementation SEMenuController

- (id)init {
	if ((self = [super init])) {
		filteringLibraries = [[NSMutableArray alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyWindowChange:) name:NSWindowDidBecomeKeyNotification object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[filteringLibraries release];
	[super dealloc];
}

- (void)awakeFromNib {
	[self updateTransferMenuItemTitle];
	
#ifdef BETA
	NSMenu *betaMenu = [[[NSMenu alloc] initWithTitle:FSLocalizedString(@"Debug", nil)] autorelease];
	NSMenuItem *betaMenuItem = [[[NSMenuItem alloc] initWithTitle:FSLocalizedString(@"Debug", nil) action:NULL keyEquivalent:@""] autorelease];

	NSMenuItem *testCrashReporter = [betaMenu addItemWithTitle:FSLocalizedString(@"Test Crash Reporter (Crash)", nil) action:@selector(testCrashReporter:) keyEquivalent:@""];
	[testCrashReporter setTarget:self];

	testCrashReporter = [betaMenu addItemWithTitle:FSLocalizedString(@"Test Crash Reporter (Exception)", nil) action:@selector(testExceptionReporter:) keyEquivalent:@""];
	[testCrashReporter setTarget:self];

	[betaMenuItem setSubmenu:betaMenu];
	[[NSApp mainMenu] insertItem:betaMenuItem atIndex:[[NSApp mainMenu] numberOfItems] - 1];
#endif
}

#ifdef BETA
- (void)testCrashReporter:(id)sender {
	NSLog(@"%@");
}
- (void)testExceptionReporter:(id)sender {
	[NSException raise:@"SETextException" format:@"Testing crash reporter"];
}
#endif

- (void)controllerDidLoad {
	[self rebuildColumnsMenu];
	
	[[[senuti interfaceController] mainWindowController] addObserver:self forKeyPath:@"visibleTableColumns" options:0 context:SEMainWindowVisibleTableColumnsChangeContext];
	[[[senuti interfaceController] mainWindowController] addObserver:self forKeyPath:@"availableTableColumns" options:0 context:SEMainWindowAvailableTableColumnsChangeContext];

	[[[senuti interfaceController] mainWindowController] addObserver:self forKeyPath:@"selectedPlaylist" options:0 context:SESourceListSelectedPlaylistChangeContext];	
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:SEAskCopyLocationPreferenceKey options:0 context:SECopyLocationAskChangeContext];
	
	[[senuti libraryController] addObserver:self forKeyPath:@"iPodLibraries" options:0 context:SEAvailableFilterLibrariesChangeContext];
	[[senuti libraryController] addObserver:self forKeyPath:@"iTunesLibrary" options:0 context:SEAvailableFilterLibrariesChangeContext];
}

- (void)controllerWillClose {
	[[[senuti interfaceController] mainWindowController] removeObserver:self forKeyPath:@"visibleTableColumns"];
	[[[senuti interfaceController] mainWindowController] removeObserver:self forKeyPath:@"availableTableColumns"];
	
	[[[senuti interfaceController] mainWindowController] removeObserver:self forKeyPath:@"selectedPlaylist"];
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:SEAskCopyLocationPreferenceKey];
	
	[[senuti libraryController] removeObserver:self forKeyPath:@"iPodLibraries"];
	[[senuti libraryController] removeObserver:self forKeyPath:@"iTunesLibrary"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SEMainWindowAvailableTableColumnsChangeContext) {
		[self rebuildColumnsMenu];
	} else if (context == SEMainWindowVisibleTableColumnsChangeContext) {
		[self updateColumnsMenuStates];
	} else if (context == SESourceListSelectedPlaylistChangeContext) {
		[self clearFilterMenu:nil];
	} else if (context == SEAvailableFilterLibrariesChangeContext) {
		[self rebuildFilterLibraryMenu];
	} else if (context == SECopyLocationAskChangeContext) {
		[self updateTransferMenuItemTitle];
	}
}

- (void)updateTransferMenuItemTitle {
	NSString *title = FSLocalizedString(@"Transfer Songs", nil);
	if ([[NSUserDefaults standardUserDefaults] boolForKey:SEAskCopyLocationPreferenceKey]) {
		title = [title stringByAppendingEllipsis];
	}
	[transferMenuItem setTitle:title];
}

#pragma mark interface builder actions
// ----------------------------------------------------------------------------------------------------
// interface builder actions
// ----------------------------------------------------------------------------------------------------

- (IBAction)donate:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.fadingred.org/senuti/donate/"]];
}

- (IBAction)contribute:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.fadingred.org/senuti/contribute/"]];
}

- (IBAction)supportWiki:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.fadingred.org/senuti/support/"]];
}

- (IBAction)cancelCopying:(id)sender {
	[[senuti copyController] cancelCopying:sender];
}

- (BOOL)canEject {
	return [[[NSApp keyWindow] windowController] respondsToSelector:@selector(canEject)] &&
		[(id)[[NSApp keyWindow] windowController] canEject];
}

- (IBAction)eject:(id)sender {
	if ([self canEject]) { [(id)[[NSApp keyWindow] windowController] eject:nil]; }
	else { NSBeep(); }
}

- (BOOL)canCopy {
	return [[[NSApp keyWindow] windowController] respondsToSelector:@selector(canCopy)] &&
		[(id)[[NSApp keyWindow] windowController] canCopy];
}

- (IBAction)copy:(id)sender {
	if ([self canCopy]) { [(id)[[NSApp keyWindow] windowController] copy:nil]; }
	else { NSBeep(); }
}


#pragma mark notifications
// ----------------------------------------------------------------------------------------------------
// notifications
// ----------------------------------------------------------------------------------------------------

- (void)keyWindowChange:(NSNotification *)notification {
	[self updateEnabledOfStaticMenuItems];
}


#pragma mark menu item validation
// ----------------------------------------------------------------------------------------------------
// menu item validation
// ----------------------------------------------------------------------------------------------------

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	if ((id)menuItem == cancelCopyingMenuItem) {
		return [[senuti copyController] isCopying];
	} else if ((id)menuItem == ejectMenuItem) {
		return [self canEject];
	} else if ((id)menuItem == transferMenuItem) {
		return [self canCopy];
	} else {
		return YES;
	}
}

- (void)updateEnabledOfStaticMenuItems {
	[librariesMenuItem setEnabled:[librariesMenu numberOfItems] > DEVICES_MENU_INITIAL_IEM_COUNT &&
		[[[NSApp keyWindow] windowController] respondsToSelector:@selector(filterLibraries:)]];
	[columnsMenuItem setEnabled:[librariesMenu numberOfItems] > DEVICES_MENU_INITIAL_IEM_COUNT &&
		[[[NSApp keyWindow] windowController] respondsToSelector:@selector(toggleTableColumnVisibility:)]];
}


#pragma mark filter libraries states
// ----------------------------------------------------------------------------------------------------
// filter libraries states
// ----------------------------------------------------------------------------------------------------

- (void)filterLibrary:(NSMenuItem *)sender {
	id <SELibrary> library = [sender representedObject];
	if ([filteringLibraries containsObject:library]) {
		[filteringLibraries removeObject:library];
		[sender setState:NSOffState];
	} else {
		[filteringLibraries addObject:library];
		[sender setState:NSOnState];
	}
	[self informAboutFilteringLibraries];
}

- (IBAction)clearFilterMenu:(id)sender {
	[filteringLibraries removeAllObjects];
	[self rebuildFilterLibraryMenu];
	[self informAboutFilteringLibraries];
}

- (void)rebuildFilterLibraryMenu {
	while ([librariesMenu numberOfItems] > DEVICES_MENU_INITIAL_IEM_COUNT) { [librariesMenu removeItemAtIndex:0]; }
	
	id <SELibrary> visibleLibrary = [[[[senuti interfaceController] mainWindowController] selectedPlaylist] library];
	id <SELibrary> iTunesLibrary = [[senuti libraryController] iTunesLibrary];

	NSMutableSet *available = [NSMutableSet setWithSet:[[senuti libraryController] iPodLibraries]];
	if (iTunesLibrary && [iTunesLibrary masterPlaylist]) { [available addObject:iTunesLibrary]; }
	if (visibleLibrary) { [available minusSet:[NSSet setWithObject:visibleLibrary]]; } // don't display the visible library as a choice
	
	if ([available count]) {
		id <SELibrary> library;
		NSEnumerator *libraryEnumerator = [available objectEnumerator];
		while (library = [libraryEnumerator nextObject]) {
			NSMenuItem *item = [librariesMenu insertItemWithTitle:[NSString stringWithFormat:FSLocalizedString(@"In %@", @"Prefix for items in 'Hide Songs' menu"), [library name]]
														 action:@selector(filterLibrary:)
												  keyEquivalent:@""
														atIndex:[librariesMenu numberOfItems] - DEVICES_MENU_INITIAL_IEM_COUNT];
			if ([filteringLibraries containsObject:library]) { [item setState:NSOnState]; }
			[item setTarget:self];
			[item setRepresentedObject:library];
		}
	}
	
	[self updateEnabledOfStaticMenuItems];
}

- (void)informAboutFilteringLibraries {
	id controller = [[NSApp keyWindow] windowController];
	if ([controller respondsToSelector:@selector(filterLibraries:)]) {
		[controller filterLibraries:[NSSet setWithArray:filteringLibraries]];
	}
}


#pragma mark columns menu
// ----------------------------------------------------------------------------------------------------
// columns menu
// ----------------------------------------------------------------------------------------------------

- (void)updateColumnsMenuStates {
	if ([NSApp isOnLeopardOrBetter]) {
		return;
	} else {
		NSArray *visible = [[[senuti interfaceController] mainWindowController] visibleTableColumns];
		NSMenuItem *menuItem;
		NSEnumerator *menuItemEnumerator = [[columnsMenu itemArray] objectEnumerator];
		while (menuItem = [menuItemEnumerator nextObject]) {
			NSTableColumn *column = [menuItem representedObject];
			if ([visible indexOfObjectIdenticalTo:column] != NSNotFound) {
				[menuItem setState:NSOnState];
			} else {
				[menuItem setState:NSOffState];
			}
		}
	}
}

- (void)rebuildColumnsMenu {
	while ([columnsMenu numberOfItems]) {
		if ([NSApp isOnLeopardOrBetter]) { [(NSTableColumn *)[columnsMenu itemAtIndex:0] unbind:@"state"]; }
		[columnsMenu removeItemAtIndex:0];
	}
	
	NSArray *available = [[[senuti interfaceController] mainWindowController] availableTableColumns];
	NSArray *visible = [[[senuti interfaceController] mainWindowController] visibleTableColumns];
	NSTableColumn *column;
	NSEnumerator *columnEnumerator = [available objectEnumerator];
	while (column = [columnEnumerator nextObject]) {
		NSMenuItem *item = [columnsMenu addItemWithTitle:[[column headerCell] title] action:@selector(toggleTableColumn:) keyEquivalent:@""];
		[item setTarget:self];
		[item setRepresentedObject:column];
		if ([NSApp isOnLeopardOrBetter]) {
			[item bind:@"state"
			  toObject:column
		   withKeyPath:@"hidden"
			   options:[NSDictionary dictionaryWithObjectsAndKeys:
						[NSValueTransformer valueTransformerForName:NSNegateBooleanTransformerName], 
						NSValueTransformerBindingOption, nil]];
		} else {
			if ([visible indexOfObjectIdenticalTo:column] != NSNotFound) {
				[item setState:NSOnState];
			}
		}
	}

	[self updateEnabledOfStaticMenuItems];
}

- (void)toggleTableColumn:(id)sender {
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		[[[senuti interfaceController] mainWindowController] toggleTableColumnVisibility:[sender representedObject]];
	}
}

@end