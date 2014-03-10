//
//  SUAutomaticUpdateAlert.h
//  Sparkle
//
//  Created by Andy Matuschak on 3/18/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SUAutomaticUpdateAlertDelegateProtocol <NSObject>
- (NSString *)titleTextForUpdateAlert:(id)alert;
- (NSString *)descriptionTextForUpdateAlert:(id)alert;
@end

@class SUAppcastItem;
@interface SUAutomaticUpdateAlert : NSWindowController {
	SUAppcastItem *updateItem;
	id delegate;

    IBOutlet NSButton *defaultButton, *alternateButton;
    NSString *defaultButtonText, *alternateButtonText;
}

- (id)initWithAppcastItem:(SUAppcastItem *)item delegate:(id <SUAutomaticUpdateAlertDelegateProtocol>)delegate;

- (IBAction)relaunchNow:sender;
- (IBAction)relaunchLater:sender;

@end
