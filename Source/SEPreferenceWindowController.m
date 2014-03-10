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

#import "SEPreferenceWindowController.h"

#import "SEObject.h"
#import "SEGeneralPreferenceViewController.h"
#import "SECopyingPreferenceViewController.h"
#import "SEAdvancedPreferenceViewController.h"

@implementation SEPreferenceWindowController

+ (void)registerDefaults {
	[SEGeneralPreferenceViewController registerDefaults];
	[SECopyingPreferenceViewController registerDefaults];
	[SEAdvancedPreferenceViewController registerDefaults];
}

static SEPreferenceWindowController *sharedPreferenceWindowController = nil;

+ (void)openPreferenceWindow:(id)sender {
	if (!sharedPreferenceWindowController) {
		sharedPreferenceWindowController = [[self alloc] init];
	}

	[[sharedPreferenceWindowController window] makeKeyAndOrderFront:nil];
}

+ (void)closePreferenceWindow:(id)sender {
	if (sharedPreferenceWindowController) { [sharedPreferenceWindowController closeWindow:nil]; }
}

+ (NSString *)nibName {
	return @"PreferenceWindow";
}

- (id)init {
	if (self = [super init]) {
		senuti = [SEObject sharedSenutiInstance];
		[self setTitle:FSLocalizedString(@"Preferences : ", nil)];
		[self setAutosaveName:@"Preferences Window"];
		[self addView:[[[SEGeneralPreferenceViewController alloc] init] autorelease]];
		[self addView:[[[SECopyingPreferenceViewController alloc] init] autorelease]];
		[self addView:[[[SEAdvancedPreferenceViewController alloc] init] autorelease]];
	}
	return self;
}

- (void)windowDidLoad {
	[[self window] setDelegate:self];
	[super windowDidLoad];
}

- (void)windowWillClose:(id)sender {
	[sharedPreferenceWindowController autorelease];
	sharedPreferenceWindowController = nil;
}

@end
