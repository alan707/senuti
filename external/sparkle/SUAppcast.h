//
//  SUAppcast.h
//  Sparkle
//
//  Created by Andy Matuschak on 3/12/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RSS, SUAppcastItem;
@interface SUAppcast : NSObject {
	NSArray *items;
	//id delegate;
}

// July 2006 Whitney Young (Thread Safety)
+ (void)fetchAppcastFromURL:(NSURL *)url delegate:(id)delegate;
//- (void)setDelegate:delegate;

- (SUAppcastItem *)newestItem;
- (NSArray *)items;

@end

@interface NSObject (SUAppcastDelegate)
- (void)appcastDidFinishLoading:(SUAppcast *)appcast;
- (void)appcastDidFailToLoad:(SUAppcast *)appcast;
@end