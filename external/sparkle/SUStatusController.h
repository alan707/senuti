//
//  SUStatusController.h
//  Sparkle
//
//  Created by Andy Matuschak on 3/14/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SUStatusController;
@protocol SUStatusControllerDelegateProtocol <NSObject>
- (NSString *)windowTitleForStatusController:(SUStatusController *)alert;
- (NSImage *)applicationIconForStatusController:(SUStatusController *)alert;
@end

@interface SUStatusController : NSWindowController {
	id delegate;
	double progressValue, maxProgressValue;
	NSString *title, *statusText, *buttonTitle, *alternateButtonTitle;
	IBOutlet NSButton *actionButton, *alternateActionButton;
    float originalHeight; // July 2006 Whitney Young (Interface Changes)
    IBOutlet NSTextField *statusTextField;
	NSString *appPath; // Whitney Young (Update a different application from the one running)
}

- (id)initWithDelegate:(id <SUStatusControllerDelegateProtocol>)delegate;

// Pass 0 for the max progress value to get an indeterminate progress bar.
// Pass nil for the status text to not show it.
- (void)beginActionWithTitle:(NSString *)title maxProgressValue:(double)maxProgressValue statusText:(NSString *)statusText;

// If isDefault is YES, the button's key equivalent will be \r.
- (void)setButtonTitle:(NSString *)buttonTitle target:target action:(SEL)action isDefault:(BOOL)isDefault;
- (void)setButtonEnabled:(BOOL)enabled;

- (void)setAlternateButtonTitle:(NSString *)aButtonTitle target:target action:(SEL)action;

- (double)progressValue;
- (void)setProgressValue:(double)value;
- (double)maxProgressValue;
- (void)setMaxProgressValue:(double)value;

- (void)setStatusText:(NSString *)statusText;
- (void)setStatusText:(NSString *)aStatusText allowHeightChange:(BOOL)allow;

@end
