//
//  SUAutomaticUpdateAlert.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/18/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUAutomaticUpdateAlert.h"
#import "SUUtilities.h"
#import "SUAppcastItem.h"

@interface SUAutomaticUpdateAlert (PRIVATE)
// July 2006 Whitney Young (Localizations)
- (void)setAlternateButtonText:(NSString *)string;
- (void)setDefaultButtonText:(NSString *)string;
@end

@implementation SUAutomaticUpdateAlert

- initWithAppcastItem:(SUAppcastItem *)item delegate:(id <SUAutomaticUpdateAlertDelegateProtocol>)del
{
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"SUAutomaticUpdateAlert" ofType:@"nib"];
	if (!path) // slight hack to resolve issues with running with in configurations
	{
		NSBundle *current = [NSBundle bundleForClass:[self class]];
		NSString *frameworkPath = [[[NSBundle mainBundle] sharedFrameworksPath] stringByAppendingFormat:@"/Sparkle.framework", [current bundleIdentifier]];
		NSBundle *framework = [NSBundle bundleWithPath:frameworkPath];
		path = [framework pathForResource:@"SUAutomaticUpdateAlert" ofType:@"nib"];
	}
	
	delegate = del;
	    
	[super initWithWindowNibPath:path owner:self];
	
	updateItem = [item retain];
	[self setShouldCascadeWindows:NO];
	
	return self;
}

- (void)awakeFromNib
{
    [self setDefaultButtonText:SULocalizedString(@"Relaunch Now", nil)];
    [self setAlternateButtonText:SULocalizedString(@"Relaunch Later", nil)];
}

// July 2006 Whitney Young (Memory Management)
- (void)dealloc
{
    [defaultButtonText release];
    [alternateButtonText release];
    [updateItem release];
    [super dealloc];
}

- (IBAction)relaunchNow:sender
{
	[self close];
	[NSApp stopModalWithCode:NSAlertDefaultReturn];
}

- (IBAction)relaunchLater:sender
{
	[self close];
	[NSApp stopModalWithCode:NSAlertAlternateReturn];
}

- (NSImage *)applicationIcon
{
	return [delegate applicationIconForUpdateAlert:self];
}

- (NSString *)titleText
{
	return [delegate titleTextForUpdateAlert:self];
}

// July 2006 Whitney Young (Localizations)
- (NSString *)descriptionText
{
	return [delegate descriptionTextForUpdateAlert:self];
}

- (NSString *)checkboxText
{
	return SULocalizedString(@"Automatically download and install updates in the future", nil);
}

- (void)setDefaultButtonText:(NSString *)string
{
    if (defaultButtonText != string)
    {
        [self willChangeValueForKey:@"defaultButtonText"];
        [defaultButtonText release];
        defaultButtonText = [string retain];
        [self didChangeValueForKey:@"defaultButtonText"];
        
        // resize the buttons
        float width, addedWidth;
        width = [defaultButton frame].size.width;
        [defaultButton sizeToFit];
        NSRect frame = [defaultButton frame];
        frame.size.width += 15; // give it some padding
        addedWidth = frame.size.width - width;
        [defaultButton setFrame:NSMakeRect(frame.origin.x - addedWidth, frame.origin.y, frame.size.width, frame.size.height)];
        [[defaultButton superview] setNeedsDisplay:TRUE];
        frame = [alternateButton frame];
        [alternateButton setFrame:NSMakeRect(frame.origin.x - addedWidth, frame.origin.y, frame.size.width, frame.size.height)];
        [[alternateButton superview] setNeedsDisplay:TRUE];
    }
}

- (NSString *)defaultButtonText
{
	return defaultButtonText;
}

- (void)setAlternateButtonText:(NSString *)string
{
    if (alternateButtonText != string)
    {
        [self willChangeValueForKey:@"alternateButtonText"];
        [alternateButtonText release];
        alternateButtonText = [string retain];
        [self didChangeValueForKey:@"alternateButtonText"];
        
        // resize the button
        float width, addedWidth;
        width = [alternateButton frame].size.width;
        [alternateButton sizeToFit];
        NSRect frame = [alternateButton frame];
        frame.size.width += 14; // give it some padding
        addedWidth = frame.size.width - width;
        [alternateButton setFrame:NSMakeRect(frame.origin.x - addedWidth, frame.origin.y, frame.size.width, frame.size.height)];        
        [[alternateButton superview] setNeedsDisplay:TRUE];
    }
}

- (NSString *)alternateButtonText
{
	return alternateButtonText;
}

@end
