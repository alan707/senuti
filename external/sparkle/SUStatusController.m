//
//  SUStatusController.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/14/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUStatusController.h"
#import "SUUtilities.h"

@interface SUStatusController (PRIVATE)
- (void)setTitle:(NSString *)aTitleText; // July 2006 Whitney Young (Memory Management)
@end

@implementation SUStatusController

- (id)initWithDelegate:(id <SUStatusControllerDelegateProtocol>)del;
{
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"SUStatus" ofType:@"nib"];
	if (!path) // slight hack to resolve issues with running in debug configurations
	{
		NSBundle *current = [NSBundle bundleForClass:[self class]];
		NSString *frameworkPath = [[[NSBundle mainBundle] sharedFrameworksPath] stringByAppendingFormat:@"/Sparkle.framework", [current bundleIdentifier]];
		NSBundle *framework = [NSBundle bundleWithPath:frameworkPath];
		path = [framework pathForResource:@"SUStatus" ofType:@"nib"];
	}

	delegate = del;
	[super initWithWindowNibPath:path owner:self];
	[self setShouldCascadeWindows:NO];
	return self;
}

- (void)dealloc
{
	[title release];
	[statusText release];
	[buttonTitle release];
	[appPath release];  // Whitney Young (Update a different application from the one running)
	[super dealloc];
}

- (void)awakeFromNib
{
    originalHeight = [[self window] frame].size.height - 14; // July 2006 Whitney Young (Interface)
	[[self window] center];
	[[self window] setFrameAutosaveName:@"SUStatusFrame"];
}

- (NSString *)windowTitle
{
	return [delegate windowTitleForStatusController:self];
}

- (NSImage *)applicationIcon
{
	return [delegate applicationIconForStatusController:self];
}

- (void)beginActionWithTitle:(NSString *)aTitle maxProgressValue:(double)aMaxProgressValue statusText:(NSString *)aStatusText
{
	[self setStatusText:aStatusText allowHeightChange:YES]; // July 2006 Whitney Young (Interface)
	[self setTitle:aTitle]; // July 2006 Whitney Young (Memory Management)	
	[self setMaxProgressValue:aMaxProgressValue];
}

// July 2006 Whitney Young (Interface)
- (void)setAlternateButtonTitle:(NSString *)aButtonTitle target:target action:(SEL)action
{
	// July 2006 Whitney Young (Memory Management)
	// properly retain and release objects
	if (alternateButtonTitle != aButtonTitle)
	{
		[self willChangeValueForKey:@"alternateButtonTitle"];
		[alternateButtonTitle release];
		alternateButtonTitle = [aButtonTitle copy];
		[self didChangeValueForKey:@"alternateButtonTitle"];			
        
        float width, addedWidth;
        width = [alternateActionButton frame].size.width;
        [alternateActionButton sizeToFit];
        NSRect frame = [alternateActionButton frame];
        frame.size.width += 15; // give it some padding
        addedWidth = frame.size.width - width;
        [alternateActionButton setFrame:NSMakeRect(frame.origin.x - addedWidth, frame.origin.y, frame.size.width, frame.size.height)];
        [[actionButton superview] setNeedsDisplay:TRUE];
	}
    
	[alternateActionButton setTarget:target];
	[alternateActionButton setAction:action];
}

- (void)setButtonTitle:(NSString *)aButtonTitle target:target action:(SEL)action isDefault:(BOOL)isDefault
{
	// July 2006 Whitney Young (Memory Management)
	// properly retain and release objects
	if (buttonTitle != aButtonTitle)
	{
		[self willChangeValueForKey:@"buttonTitle"];
		[buttonTitle release];
		buttonTitle = [aButtonTitle copy];
		[self didChangeValueForKey:@"buttonTitle"];			
	
		// July 2006 Whitney Young (Interface)
        float width, addedWidth;
        width = [actionButton frame].size.width;
        [actionButton sizeToFit];
        NSRect frame = [actionButton frame];
        frame.size.width += 15; // give it some padding
        addedWidth = frame.size.width - width;
        [actionButton setFrame:NSMakeRect(frame.origin.x - addedWidth, frame.origin.y, frame.size.width, frame.size.height)];
        [[actionButton superview] setNeedsDisplay:TRUE];
        frame = [alternateActionButton frame];
        [alternateActionButton setFrame:NSMakeRect(frame.origin.x - addedWidth, frame.origin.y, frame.size.width, frame.size.height)];
        [[alternateActionButton superview] setNeedsDisplay:TRUE];
        
        //[actionButton sizeToFit];
		//// Except we're going to add 15 px for padding.
		//[actionButton setFrameSize:NSMakeSize([actionButton frame].size.width + 15, [actionButton frame].size.height)];
		//// Now we have to move it over so that it's always 15px from the side of the window.
		//[actionButton setFrameOrigin:NSMakePoint([[self window] frame].size.width - 15 - [actionButton frame].size.width, [actionButton frame].origin.y)];	
		//// Redisplay superview to clean up artifacts
		//[[actionButton superview] setNeedsDisplay:TRUE]; // July 2006 Whitney Young (Performance)
	}
		
	[actionButton setTarget:target];
	[actionButton setAction:action];
	[actionButton setKeyEquivalent:isDefault ? @"\r" : @""];
}

- (void)setButtonEnabled:(BOOL)enabled
{
	[actionButton setEnabled:enabled];
}

- (double)progressValue
{
	return progressValue;
}

- (void)setProgressValue:(double)value
{
	[self willChangeValueForKey:@"progressValue"];
	progressValue = value;
	[self didChangeValueForKey:@"progressValue"];	
}

- (double)maxProgressValue
{
	return maxProgressValue;
}

- (void)setMaxProgressValue:(double)value
{
	[self willChangeValueForKey:@"maxProgressValue"];
	maxProgressValue = value;
	[self didChangeValueForKey:@"maxProgressValue"];
	[self setProgressValue:0];
}

// 7/14/06 Whitney Young (Interface)
// Keep default implementation working
- (void)setStatusText:(NSString *)aStatusText
{
    [self setStatusText:aStatusText allowHeightChange:NO];
}

- (void)setStatusText:(NSString *)aStatusText allowHeightChange:(BOOL)allow
{
	// 7/13/06 Whitney Young (Memory Management)
	// properly retain and release objects
	if (statusText != aStatusText)
	{
		[self willChangeValueForKey:@"statusText"];
		[statusText release];
		statusText = [aStatusText copy];
		[self didChangeValueForKey:@"statusText"];
    }
	
    // 7/14/06 Whitney Young (Interface)
    // Allow the initial height of statusText to dictate the window size
	if (allow) {
		float height;
		if (aStatusText) {
			height = [[statusTextField cell] cellSizeForBounds:NSMakeRect(0, 0, [statusTextField frame].size.width, FLT_MAX)].height;
			height = (height < 14) ? 14 : height;
		} else {
			height = 0;
		}
		
		NSRect frame = [[self window] frame];
        if (originalHeight + height != frame.size.height)
        {
            // hide the text if resizing the window because it looks better
            [statusTextField setHidden:TRUE];
        }        
        [[self window] setFrame:NSMakeRect(frame.origin.x, frame.origin.y - originalHeight + frame.size.height - height, frame.size.width, originalHeight + height) display:YES animate:YES];                    
        [statusTextField setHidden:FALSE];		
	}
}

- (void)setTitle:(NSString *)aTitleText
{
	// 7/13/06 Whitney Young (Memory Management)
	// properly retain and release objects
	if (title != aTitleText)
	{
		[self willChangeValueForKey:@"title"];
		[title release];
		title = [aTitleText copy];
		[self didChangeValueForKey:@"title"];	
	}
}

@end
