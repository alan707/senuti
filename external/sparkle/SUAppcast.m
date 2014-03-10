//
//  SUAppcast.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/12/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SUUtilities.h"
#import "RSS.h"

@interface SUAppcast (PRIVATE)
- (void)setItems:(NSArray *)newItems; // July 2006 Whitney Young (Memory Management)
@end

@implementation SUAppcast

// July 2006 Whitney Young (Memory Magement)
// Let the class handle allocating and deallocating the object
+ (void)fetchAppcastFromURL:(NSURL *)url delegate:(id)delegate
{
	[NSThread detachNewThreadSelector:@selector(_fetchAppcastFromURL:) toTarget:self withObject:[NSArray arrayWithObjects:url, delegate, nil]]; // let's not block the main thread
}

//- (void)setDelegate:del
//{
//	delegate = del;
//}

- (void)dealloc
{
	[items release];
	[super dealloc];
}

- (SUAppcastItem *)newestItem
{
	return [items objectAtIndex:0]; // the RSS class takes care of sorting by published date, descending.
}

- (NSArray *)items
{
	return items;
}

- (void)setItems:(NSArray *)newItems
{
	// July 2006 Whitney Young (Memory Management)
	// properly retain and release objects
	if (items != newItems)
	{
		[items release];
		items = [newItems retain];
	}
}

+ (void)_fetchAppcastFromURL:(NSArray *)info
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    SUAppcast *object = [[self alloc] init];
    NSURL *url = [info objectAtIndex:0];
    id delegate = [info objectAtIndex:1];
	
    // allow the feed to always be released
	RSS *feed = nil; // July 2006 Whitney Young (Memory Management)
	@try
	{
		NSString *userAgent = [NSString stringWithFormat: @"%@/%@ (Mac OS X) Sparkle/1.0", SUHostAppName(), SUHostAppVersion()];
		
		feed = [[RSS alloc] initWithURL:url normalize:YES userAgent:userAgent];
		// Set up all the appcast items
		NSMutableArray *tempItems = [NSMutableArray array];
		id enumerator = [[feed newsItems] objectEnumerator], current;
		while ((current = [enumerator nextObject]))
		{
			[tempItems addObject:[[[SUAppcastItem alloc] initWithDictionary:current] autorelease]];
		}
		//items = [[NSArray arrayWithArray:tempItems] retain];
		// July 2006 Whitney Young (Memory Management)
		// to ensure that the items is immutable, the following line could read
		// [self setHeaderItems:[NSArray arrayWithArray:tempItems]];
		// but for speed and simplicity, it's easier to assume that whoever uses the object
		// returned by the items method on this class (which is typed (NSArray *)) will
		// adhere to the type specification and use the object only as an immutable instance	
		[object setItems:tempItems];
		
		if ([delegate respondsToSelector:@selector(appcastDidFinishLoading:)])
			[delegate performSelectorOnMainThread:@selector(appcastDidFinishLoading:) withObject:object waitUntilDone:NO];
		
	}
	@catch (NSException *e)
	{
		if ([delegate respondsToSelector:@selector(appcastDidFailToLoad:)])
			[delegate performSelectorOnMainThread:@selector(appcastDidFailToLoad:) withObject:object waitUntilDone:NO];
	}
	@finally
	{
        // the feed must be released
		[feed release]; // July 2006 Whitney Young (Memory Management)
	}
        
    [object release];
    [pool release];	
}

@end
