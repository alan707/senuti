//
//  SUUpdateAlert.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/12/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUUpdateAlert.h"
#import "SUAppcastItem.h"
#import "SUUtilities.h"
#import <WebKit/WebKit.h>

@implementation SUUpdateAlert

- (id)initWithAppcastItem:(SUAppcastItem *)item delegate:(id <SUUpdateAlertDelegateProtocol>)del
{
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"SUUpdateAlert" ofType:@"nib"];
	if (!path) // slight hack to resolve issues with running with in configurations
	{
		NSBundle *current = [NSBundle bundleForClass:[self class]];
		NSString *frameworkPath = [[[NSBundle mainBundle] sharedFrameworksPath] stringByAppendingFormat:@"/Sparkle.framework", [current bundleIdentifier]];
		NSBundle *framework = [NSBundle bundleWithPath:frameworkPath];
		path = [framework pathForResource:@"SUUpdateAlert" ofType:@"nib"];
	}
	
	delegate = del;
	
	[super initWithWindowNibPath:path owner:self];
	
	updateItem = [item retain];
	[self setShouldCascadeWindows:NO];
	
	return self;
}

- (void)dealloc
{
	[updateItem release];
	[super dealloc];
}

- (void)endWithSelection:(SUUpdateAlertChoice)choice
{
	[releaseNotesView stopLoading:self];
	[releaseNotesView setFrameLoadDelegate:nil];
	[releaseNotesView setPolicyDelegate:nil];
	[self close];
	if ([delegate respondsToSelector:@selector(updateAlert:finishedWithChoice:)])
		[delegate updateAlert:self finishedWithChoice:choice];
}

- (IBAction)installUpdate:(id)sender
{
	[self endWithSelection:SUInstallUpdateChoice];
}

- (IBAction)skipThisVersion:(id)sender
{
	[self endWithSelection:SUSkipThisVersionChoice];
}

- (IBAction)remindMeLater:(id)sender
{
	[self endWithSelection:SURemindMeLaterChoice];
}

- (IBAction)cancel:(id)sender
{
	[self endWithSelection:SUCancelChoice];
}

- (void)displayReleaseNotes
{
	[releaseNotesView setFrameLoadDelegate:self];
	[releaseNotesView setPolicyDelegate:self];
	
	// Stick a nice big spinner in the middle of the web view until the page is loaded.
	NSRect frame = [[releaseNotesView superview] frame];
	releaseNotesSpinner = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(NSMidX(frame)-16, NSMidY(frame)-16, 32, 32)] autorelease];
	[releaseNotesSpinner setStyle:NSProgressIndicatorSpinningStyle];
	[releaseNotesSpinner startAnimation:self];
	webViewFinishedLoading = NO;
	[[releaseNotesView superview] addSubview:releaseNotesSpinner];
	
	// If there's a release notes URL, load it; otherwise, just stick the contents of the description into the web view.
	if ([updateItem releaseNotesURL])
	{
		[[releaseNotesView mainFrame] loadRequest:[NSURLRequest requestWithURL:[updateItem releaseNotesURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30]];
	}
	else
	{
		[[releaseNotesView mainFrame] loadHTMLString:[updateItem description] baseURL:nil];
	}	
}

- (BOOL)showsReleaseNotes
{
	return [delegate showReleaseNotesForUpdateAlert:self];
}

- (BOOL)allowsAutomaticUpdates
{
	return [delegate allowAutomaticUpdateForUpdateAlert:self];
}

- (void)awakeFromNib
{
	// set the proper button scheme
	if ([delegate displayCancelButtonForUpdateAlert:self]) {
		[skipButton setHidden:YES];
		[remindButton setHidden:YES];
		[cancelButton setHidden:NO];
	}
	
	[[self window] setLevel:NSFloatingWindowLevel];
	[[self window] setFrameAutosaveName:@"SUUpdateAlertFrame"];
		
	// We're gonna do some frame magic to match the window's size to the description field and the presence of the release notes view.
	NSRect frame = [[self window] frame];
	
	if (![self showsReleaseNotes])
	{
		// Resize the window to be appropriate for not having a huge release notes view.
		frame.size.height -= [releaseNotesView frame].size.height;
		// No resizing!
		[[self window] setShowsResizeIndicator:NO];
		[[self window] setMinSize:frame.size];
		[[self window] setMaxSize:frame.size];
	}
	
	float descriptionHeightChange, descriptionDesiredHeight, descriptionHeight;
	descriptionHeight = [description frame].size.height;
	descriptionDesiredHeight = [[description cell] cellSizeForBounds:NSMakeRect(0, 0, [description frame].size.width, FLT_MAX)].height;
	descriptionHeightChange = descriptionDesiredHeight - descriptionHeight;
	
	// change the height of the description item
	[description setFrame:NSMakeRect([description frame].origin.x, [description frame].origin.y - descriptionHeightChange, [description frame].size.width, descriptionDesiredHeight)];
	// move the release notes label down as well
	[releaseNotesLabel setFrame:NSMakeRect([releaseNotesLabel frame].origin.x, [releaseNotesLabel frame].origin.y - descriptionHeightChange, [releaseNotesLabel frame].size.width, [releaseNotesLabel frame].size.height)];
	
	if (![self allowsAutomaticUpdates])
	{
		NSRect boxFrame = [[[releaseNotesView superview] superview] frame];
		boxFrame.origin.y -= 20;
		boxFrame.size.height += 20;
		// make a little space for the height change of the description
		boxFrame.size.height -= descriptionHeightChange;
		[[[releaseNotesView superview] superview] setFrame:boxFrame];
	}
	
	[[self window] setFrame:frame display:NO];
	[[self window] center];
	
	if ([self showsReleaseNotes])
	{
		[self displayReleaseNotes];
	}
}

- (BOOL)windowShouldClose:note
{
	[self endWithSelection:SURemindMeLaterChoice];
	return YES;
}

- (NSImage *)applicationIcon
{
	return [delegate applicationIconForUpdateAlert:self];
}

- (NSString *)titleText
{
	return [delegate titleTextForUpdateAlert:self];
}

- (NSString *)descriptionText
{
	return [delegate descriptionTextForUpdateAlert:self];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:frame
{
    if ([frame parentFrame] == nil) {
        webViewFinishedLoading = YES;
		[releaseNotesSpinner setHidden:YES];
		[sender display]; // necessary to prevent weird scroll bar artifacting
    }
}

- (void)webView:sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:frame decisionListener:listener
{
    if (webViewFinishedLoading == YES) {
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
		
        [listener ignore];
    }    
    else {
        [listener use];
    }
}

- (void)setDelegate:(id <SUUpdateAlertDelegateProtocol>)del
{
	delegate = del;
}

@end
