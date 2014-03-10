//
//  AIViewAdditions.h
//  CrashReporter
//
//  Created by Whitney Young on 8/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
    AIExpandTowardMinXMask			=  1,
    AIExpandTowardMaxXMask			=  2,
    AIExpandTowardMinYMask			=  4,
    AIExpandTowardMaxYMask			=  16,
};

@interface NSView (AIViewAdditions)

/*!
    @method     resizeViewToSize:expandToward:moveViews:shrinkViews:
    @abstract   resizes a view to a specified size
    @discussion resizes the view, but allows for easy manipulation of views around it
    @param      expandingMask the way to resize in relation to the parent.
				you can C wise or masks together to get something like AIExpandTowardMinXMask | AIExpandTowardMinYMask
    @param      edge the edge that the view should expand toward
    @param      moveViews views that should be moved in the same direction that the view is expanding
    @param      shrinkViews view that should be made smaller to make room for the view
    @result     the change in height
*/
- (NSSize)resizeViewToSize:(NSSize)size
			  expandToward:(unsigned int)expandingMask
				 moveViews:(NSArray *)moveViews
			   shrinkViews:(NSArray *)shrinkViews;
@end

@interface NSControl (AIViewAdditions)

- (NSSize)sizeToFitWithPadding:(NSSize)padding
				  expandToward:(unsigned)expandingMask
					 moveViews:(NSArray *)moveViews
				   shrinkViews:(NSArray *)shrinkViews;
@end

@interface NSTextField (AIViewAdditions)

- (int)heightForText;

@end