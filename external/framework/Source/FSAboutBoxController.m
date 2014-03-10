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

/*
 * This code is orinally from Adium.
 * Visit http://www.adiumx.com/ for more information.
 */

#import "FSAboutBoxController.h"
#import "FSApplicationAdditions.h"

#define ABOUT_BOX_NIB					@"AboutBox"
#define ABOUT_SCROLL_FPS				30.0
#define ABOUT_SCROLL_RATE				1.0

@interface FSAboutBoxController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (NSString *)_applicationVersion;
- (void)_loadBuildInformation;
@end

@implementation FSAboutBoxController

//Returns the shared about box instance
FSAboutBoxController *sharedAboutBoxInstance = nil;
+ (FSAboutBoxController *)aboutBoxController {
	if(!sharedAboutBoxInstance) {
		sharedAboutBoxInstance = [[self alloc] initWithWindowNibName:ABOUT_BOX_NIB];
	}
	return(sharedAboutBoxInstance);
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName {
	if (self = [super initWithWindowNibName:windowNibName]) {
		numberOfBuildFieldClicks = -1;
		[self setShouldCascadeWindows:NO];
	}
	return self;
}

//Dealloc
- (void)dealloc {
	[buildInfo release];
	[buildInfoKeys release];
	[homepage release];
	
	[super dealloc];
}

//Prepare the about box window
- (void)windowDidLoad {
	NSAttributedString		*creditsString;

	//Load our build information and avatar list
	[self _loadBuildInformation];

	//Credits
	creditsString = [[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"About.rtf" ofType:nil] documentAttributes:nil] autorelease];
	[[textView_credits textStorage] setAttributedString:creditsString];
	[[textView_credits enclosingScrollView] setLineScroll:0.0];
	[[textView_credits enclosingScrollView] setPageScroll:0.0];

	//Start scrolling
	scrollLocation = 0; 
	scrollRate = ABOUT_SCROLL_RATE;
	maxScroll = [[textView_credits textStorage] size].height - [[textView_credits enclosingScrollView] documentVisibleRect].size.height;
	scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/ABOUT_SCROLL_FPS)
													target:self
												  selector:@selector(scrollTimer:)
												  userInfo:nil
												   repeats:YES] retain];
	eventLoopScrollTimer = [[NSTimer timerWithTimeInterval:(1.0/ABOUT_SCROLL_FPS)
												   target:self
												 selector:@selector(scrollTimer:)
												 userInfo:nil
												  repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:eventLoopScrollTimer forMode:NSEventTrackingRunLoopMode];
	
	//Setup the build date / version
	[textField_name setStringValue:[self _applicationVersion]];
	[self buildFieldClicked:nil];

	//Set the localized values
	[button_homepage setTitle:FSLocalizedString(@"Homepage", nil)];
	[button_license setTitle:FSLocalizedString(@"License", nil)];

	[[self window] center];
}

//Cleanup as the window is closing
- (void)windowWillClose:(id)sender {
	[sharedAboutBoxInstance autorelease]; sharedAboutBoxInstance = nil;
	[scrollTimer invalidate]; [scrollTimer release]; scrollTimer = nil;
	[eventLoopScrollTimer invalidate]; [eventLoopScrollTimer release]; eventLoopScrollTimer = nil;
}

//Visit the homepage
- (IBAction)visitHomepage:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:homepage]];
}

- (void)setHomepage:(NSString *)string {
	if (homepage != string) {
		[homepage release];
		homepage = [string retain];
	}
}

- (void)setBuildInfoDisplayKeys:(NSArray *)keys {
	if (keys != buildInfoKeys) {
		[buildInfoKeys release];
		buildInfoKeys = [keys retain];
	}	
}

//Scrolling Credits ----------------------------------------------------------------------------------------------------
#pragma mark Scrolling Credits
//Scroll the credits
- (void)scrollTimer:(NSTimer *)scrollTimer {
	scrollLocation += scrollRate;
	
	if(scrollLocation > maxScroll) scrollLocation = 0;
	if(scrollLocation < 0) scrollLocation = maxScroll;
	
	[textView_credits scrollPoint:NSMakePoint(0, scrollLocation)];
}

//Receive the flags changed event for reversing the scroll direction via option
- (void)flagsChanged:(NSEvent *)theEvent {
	if(([theEvent modifierFlags] & NSAlternateKeyMask) != 0) {
		scrollRate = -ABOUT_SCROLL_RATE;
	}else{
		scrollRate = ABOUT_SCROLL_RATE;
	}
}

//Receive the key down event for pausing and starting the scroll
- (void)keyDown:(NSEvent *)theEvent {
	if ([[theEvent characters] characterAtIndex:0] == ' ')
	{
		if((++numberOfSpaceKeyDowns) % 2 == 0) {
			scrollRate = ABOUT_SCROLL_RATE;
		} else {
			scrollRate = 0;
		}
	} else {
		[super keyDown:theEvent];
	}
}


//Build Information ----------------------------------------------------------------------------------------------------
#pragma mark Build Information
//Toggle build date/number display
- (IBAction)buildFieldClicked:(id)sender {
	int index = ++numberOfBuildFieldClicks % [buildInfoKeys count];	
	id value = [buildInfo objectForKey:[buildInfoKeys objectAtIndex:index]];
	// convert all values to strings
	if ([value isKindOfClass:[NSDate class]]) {
		NSDateFormatter *dateFormatter;
		if ([NSApp isOnTigerOrBetter]) {
			dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		} else {
			dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:[[NSUserDefaults standardUserDefaults] objectForKey:NSDateFormatString]
																 allowNaturalLanguage:NO] autorelease];
		}
		value = [dateFormatter stringForObjectValue:value];			
	} else if (![value isKindOfClass:[NSString class]]) { value = [value description]; }

	[button_version setTitle:value];
}

//Returns the current version of the Application
- (NSString *)_applicationVersion {
	NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	
	return [NSString stringWithFormat:@"%@ %@", (name ? name : @""), (version ? version : @"")];
}

//Load the current build date and our cryptic, non-sequential build number ;)
- (void)_loadBuildInformation {	
	NSString *buildInfoPath = [[NSBundle mainBundle] pathForResource:@"BuildInfo" ofType:@"plist"];
	buildInfo = [[NSMutableDictionary dictionaryWithContentsOfFile:buildInfoPath] retain];
}

//Software License -----------------------------------------------------------------------------------------------------
#pragma mark Software License
//Display the software license sheet
- (IBAction)showLicense:(id)sender {
	NSString	*licensePath = [[NSBundle mainBundle] pathForResource:@"License" ofType:@"txt"];
	[textView_license setString:[NSString stringWithContentsOfFile:licensePath]];
	
	[NSApp beginSheet:panel_licenseSheet
	   modalForWindow:[self window]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

//Close the software license sheet
- (IBAction)hideLicense:(id)sender {
	[panel_licenseSheet orderOut:nil];
	[NSApp endSheet:panel_licenseSheet returnCode:0];
}

@end
