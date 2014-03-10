//
//  SUUpdateAlert.h
//  Sparkle
//
//  Created by Andy Matuschak on 3/12/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
	SUInstallUpdateChoice,
	SURemindMeLaterChoice,
	SUSkipThisVersionChoice,
	SUCancelChoice
} SUUpdateAlertChoice;

@protocol SUUpdateAlertDelegateProtocol <NSObject>
- (NSString *)titleTextForUpdateAlert:(id)alert;
- (NSString *)descriptionTextForUpdateAlert:(id)alert;
- (BOOL)showReleaseNotesForUpdateAlert:(id)alert;
- (BOOL)allowAutomaticUpdateForUpdateAlert:(id)alert;
- (BOOL)displayCancelButtonForUpdateAlert:(id)alert;
- (NSImage *)applicationIconForUpdateAlert:(id)alert;
@end

@class WebView, SUAppcastItem;
@interface SUUpdateAlert : NSWindowController {
	SUAppcastItem *updateItem;
	id delegate;
	
	IBOutlet WebView *releaseNotesView;
	IBOutlet NSTextField *releaseNotesLabel;
	IBOutlet NSTextField *description;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSButton *remindButton;
	IBOutlet NSButton *skipButton;

	NSProgressIndicator *releaseNotesSpinner;
	BOOL webViewFinishedLoading;
}

- (id)initWithAppcastItem:(SUAppcastItem *)item delegate:(id <SUUpdateAlertDelegateProtocol>)delegate;

- (IBAction)installUpdate:(id)sender;
- (IBAction)skipThisVersion:(id)sender;
- (IBAction)remindMeLater:(id)sender;
- (IBAction)cancel:(id)sender;

@end

@interface NSObject (SUUpdateAlertDelegate)
- (void)updateAlert:(SUUpdateAlert *)updateAlert finishedWithChoice:(SUUpdateAlertChoice)updateChoice;
@end
