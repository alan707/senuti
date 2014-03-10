//
//  SUStatusWindow.h
//  Sparkle
//
//  Created by Whitney Young on 7/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SUStatusWindow : NSWindow

- (void)saveFrameUsingName:(NSString *)name;
- (BOOL)setFrameUsingName:(NSString *)name;
- (NSTimeInterval)animationResizeTime:(NSRect)newFrame;

@end
