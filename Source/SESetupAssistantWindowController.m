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

#import "SESetupAssistantWindowController.h"
#import "SECopyLocationViewController.h"
#import "SECopyingPreferenceViewController.h"
#import "SELibraryController.h"

#import "SEITunesLibrary.h"

#define DONATION_URL			@"http://www.fadingred.org/senuti/donate/"

#define WELCOME_INDEX			0
#define LICENSE_INDEX			1
#define LOCATION_INDEX			2
#define IPOD_SETUP_INDEX		3
#define TIPS_INDEX				4
#define COMPLETE_INDEX			5

static void *SECopyLocationChangeContext = @"SECopyLocationChangeContext";

@interface SESetupAssistantWindowController (PRIVATE)

- (id)initWithDeleagte:(id)delegate
		didEndSelector:(SEL)didEndSelector
	didDismissSelector:(SEL)didDismissSelector;

- (BOOL)releaseWhenComplete;
- (void)setReleaseWhenComplete:(BOOL)flag;
- (void)runSetupAssistant;
- (void)finishRuningSeuptAssistant;

- (IBAction)activateWelcome:(id)sender;
- (BOOL)completeWelcome;
- (IBAction)activateLicense:(id)sender;
- (BOOL)completeLicense;
- (IBAction)activateCopyLocation:(id)sender;
- (BOOL)completeCopyLocation;
- (IBAction)activateIPodSetup:(id)sender;
- (BOOL)completeIPodSetup;
- (IBAction)activateTips:(id)sender;
- (BOOL)completeTips;
- (IBAction)activateComplete:(id)sender;
- (BOOL)completeComplete;

@end

@implementation SESetupAssistantWindowController


+ (NSString *)nibName {
	return @"SetupAssistant";
}

+ (void)runSetupAssistantWithDelegate:(id)del
					   didEndSelector:(SEL)didEnd
				   didDismissSelector:(SEL)didDismiss {

	SESetupAssistantWindowController *controller;
	controller = [[self alloc] initWithDeleagte:del
								 didEndSelector:didEnd
							 didDismissSelector:didDismiss];
	[controller setReleaseWhenComplete:TRUE];
	[controller runSetupAssistant];
}

- (id)initWithDeleagte:(id)del
		didEndSelector:(SEL)didEnd
	didDismissSelector:(SEL)didDismiss {
	
	if (self = [super init]) {
		delegate = del;
		didEndSelector = didEnd;
		didDismissSelector = didDismiss;
		releaseWhenComplete = FALSE;
		
		[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:SECopyLocationPreferenceKey options:0 context:SECopyLocationChangeContext];
	}
	return self;
}

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:SECopyLocationPreferenceKey];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)windowDidLoad {
	// Taken from Adium
	// Configure our background view; it should display the image transparently where our tabView overlaps it
	[backgroundView setBackgroundImage:[NSImage imageNamed:@"wheel" forClass:[self class]]];
	NSRect tabViewFrame = [tabView frame];
	NSRect backgroundViewFrame = [backgroundView frame];
	tabViewFrame.origin.x -= backgroundViewFrame.origin.x;
	tabViewFrame.origin.y -= backgroundViewFrame.origin.y;
	[backgroundView setTransparentRect:tabViewFrame];
	
	NSString	*licensePath = [[NSBundle mainBundle] pathForResource:@"License" ofType:@"txt"];
	[licenseText setString:[NSString stringWithContentsOfFile:licensePath]];
	
	[[copyLocationViewController view] setFrame:[copyLocationView frame]];
	[[copyLocationView superview] replaceSubview:copyLocationView with:[copyLocationViewController view]];
	[copyLocationViewController bind:@"selectedLocation"
							toObject:[NSUserDefaults standardUserDefaults]
						 withKeyPath:SECopyLocationPreferenceKey
							 options:nil];
	if (![[NSUserDefaults standardUserDefaults] objectForKey:SECopyLocationPreferenceKey]) {
		[copyLocationViewController setSelectedLocationToDefault];
	}
	
	// Get the setup text and append links to it
	NSMutableAttributedString *setup = [[[NSMutableAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"IPodSetup.rtf" ofType:nil] documentAttributes:nil] autorelease];
	
	NSString *linkFormat = @"\t%@\n";
	NSMutableAttributedString *link1 = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:linkFormat, FSLocalizedString(@"Senuti Support", nil)]] autorelease];
	[link1 addAttribute:NSLinkAttributeName value:@"http://www.fadingred.org/senuti/support/" range:NSMakeRange(0, [link1 length])];
	[link1 addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Lucida Grande" size:13] range:NSMakeRange(0, [link1 length])];

	NSMutableAttributedString *link2 = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:linkFormat, FSLocalizedString(@"Apple Support", nil)]] autorelease];
	[link2 addAttribute:NSLinkAttributeName value:@"http://docs.info.apple.com/article.html?artnum=61131" range:NSMakeRange(0, [link2 length])];
	[link2 addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Lucida Grande" size:13] range:NSMakeRange(0, [link2 length])];
	
	[setup appendAttributedString:link1];
	[setup appendAttributedString:link2];
	
	[[setupText textStorage] setAttributedString:setup];	
	[setupText setBackgroundColor:[NSColor blueColor]];
	[setupText setDrawsBackground:NO];
	[(NSScrollView *)[setupText superview] setDrawsBackground:NO];
	
	[[self window] center];
	[self activateWelcome:nil];
}

- (BOOL)windowShouldClose:(id)sender {
	if ([self releaseWhenComplete]) { [self autorelease]; }
	return YES;
}

- (BOOL)releaseWhenComplete {
	return releaseWhenComplete;
}
- (void)setReleaseWhenComplete:(BOOL)flag {
	releaseWhenComplete = flag;
}

- (void)runSetupAssistant {
	[[self window] makeKeyAndOrderFront:nil];
}

- (void)finishRuningSeuptAssistant {
	[self closeWindow:nil];
	if (delegate && didEndSelector) {
		[delegate performSelector:didEndSelector withObject:self];
	}	
}

#pragma mark observing changes
// ----------------------------------------------------------------------------------------------------
// observing changes
// ----------------------------------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == SECopyLocationChangeContext) {
		copyLocationSet = ([[NSUserDefaults standardUserDefaults] objectForKey:SECopyLocationPreferenceKey] != nil);
		if (selectedIndex == LOCATION_INDEX) { [continueButton setEnabled:copyLocationSet]; }
	}
}

#pragma mark interface actions
// ----------------------------------------------------------------------------------------------------
// interface actions
// ----------------------------------------------------------------------------------------------------

- (IBAction)continueClick:(id)sender {
	switch (selectedIndex) {
		case WELCOME_INDEX:
			if ([self completeWelcome]) { [self activateLicense:nil]; }
			break;
		case LICENSE_INDEX:
			if ([self completeLicense]) { [self activateCopyLocation:nil]; }
			break;
		case LOCATION_INDEX:
			if ([self completeCopyLocation]) { [self activateIPodSetup:nil]; }
			break;
		case IPOD_SETUP_INDEX:
			if ([self completeIPodSetup]) { [self activateTips:nil]; }
			break;
		case TIPS_INDEX:
			if ([self completeTips]) { [self activateComplete:nil]; }
			break;
		case COMPLETE_INDEX:
			if ([self completeComplete]) { [self finishRuningSeuptAssistant]; }
			break;
		default:
			break;
	}
}

- (IBAction)goBackClick:(id)sender {
	switch (selectedIndex) {
		case WELCOME_INDEX:
			break;
		case LICENSE_INDEX:
			[self activateWelcome:nil];
			break;
		case LOCATION_INDEX:
			[self activateLicense:nil];
			break;
		case IPOD_SETUP_INDEX:
			[self activateCopyLocation:nil];
			break;
		case TIPS_INDEX:
			[self activateIPodSetup:nil];
			break;
		case COMPLETE_INDEX:
			[self activateTips:nil];
			break;
		default:
			break;
	}	
}

- (IBAction)cancelClick:(id)sender {
	[self closeWindow:nil];
	if (delegate && didDismissSelector) {
		[delegate performSelector:didDismissSelector withObject:self];
	}
}

- (IBAction)moreInformationClick:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:DONATION_URL]];
}

#pragma mark chaning views
// ----------------------------------------------------------------------------------------------------
// chaning views
// ----------------------------------------------------------------------------------------------------

- (IBAction)activateWelcome:(id)sender {
	[continueButton setEnabled:TRUE];
	[continueButton setTitle:FSLocalizedString(@"Continue", nil)];
	[goBackButton setEnabled:NO];
	selectedIndex = WELCOME_INDEX;
	[tabView selectTabViewItemAtIndex:selectedIndex];
}

- (BOOL)completeWelcome {
	return YES;
}

- (IBAction)activateLicense:(id)sender {
	[continueButton setEnabled:TRUE];
	[continueButton setTitle:FSLocalizedString(@"Continue", nil)];
	[goBackButton setEnabled:YES];
	selectedIndex = LICENSE_INDEX;
	[tabView selectTabViewItemAtIndex:selectedIndex];
}

- (BOOL)completeLicense {
	return YES;
}

- (IBAction)activateCopyLocation:(id)sender {
	[continueButton setEnabled:copyLocationSet];
	[continueButton setTitle:FSLocalizedString(@"Continue", nil)];
	[goBackButton setEnabled:YES];
	selectedIndex = LOCATION_INDEX;
	[tabView selectTabViewItemAtIndex:selectedIndex];	
}

- (BOOL)completeCopyLocation {
	return YES;
}

- (IBAction)activateIPodSetup:(id)sender {
	[continueButton setEnabled:TRUE];
	[continueButton setTitle:FSLocalizedString(@"Continue", nil)];
	[goBackButton setEnabled:YES];
	selectedIndex = IPOD_SETUP_INDEX;
	[tabView selectTabViewItemAtIndex:selectedIndex];
}

- (BOOL)completeIPodSetup {
	return YES;
}

- (IBAction)activateTips:(id)sender {
	[continueButton setEnabled:TRUE];
	[continueButton setTitle:FSLocalizedString(@"Continue", nil)];
	[goBackButton setEnabled:YES];
	selectedIndex = TIPS_INDEX;
	[tabView selectTabViewItemAtIndex:selectedIndex];
}

- (BOOL)completeTips {
	return YES;
}

- (IBAction)activateComplete:(id)sender {
	[continueButton setEnabled:TRUE];
	[continueButton setTitle:FSLocalizedString(@"Done", nil)];
	selectedIndex = COMPLETE_INDEX;
	[tabView selectTabViewItemAtIndex:selectedIndex];
}

- (BOOL)completeComplete {
	return YES;
}

@end
