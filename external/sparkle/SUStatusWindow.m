//
//  SUStatusWindow.m
//  Sparkle
//
//  Created by Whitney Young on 7/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SUStatusWindow.h"


@implementation SUStatusWindow

- (void)saveFrameUsingName:(NSString *)name
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSString stringWithFormat:@"%f %f", [self frame].origin.x, [self frame].origin.y + [self frame].size.height]
                 forKey:[NSString stringWithFormat:@"SUStatusWindow Position", name]];
}

- (BOOL)setFrameUsingName:(NSString *)name
{
	NSString *saved = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"SUStatusWindow Position", name]];
	if (saved)
    {
        NSArray *parts = [saved componentsSeparatedByString:@" "];
        float x = [[parts objectAtIndex:0] floatValue];
        float y_max = [[parts objectAtIndex:1] floatValue];
        [self setFrame:NSMakeRect(x, y_max - [self frame].size.height, [self frame].size.width, [self frame].size.height) display:NO];
        return TRUE;
	}
    return FALSE;
}

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame { // resize slower than default
	return [[[NSUserDefaults standardUserDefaults] objectForKey:@"NSWindowResizeTime"] doubleValue] * 1.5;
}

@end
