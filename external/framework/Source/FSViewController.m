/* 
 * The FadingRed Shared Framework (FSFramework) is the legal property of its developers, whose names
 * are listed in the copyright file included with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "FSViewController.h"
#import "FSControlledView.h"

@implementation FSViewController

+ (NSString *)nibName  {
	return nil;
}

+ (id)controller {
	return [[[self alloc] init] autorelease];
}

- (id)init {
	NSAssert([[self class] nibName],
			 @"FSViewController is designed for subclasses to use.  "
			 "You must implement the +(NSString *)nibName method");
	
	if (self = [super init]) {
		view = nil;
		topLevelObjects = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	FSDLog(@"");
		
	// It is important to note that the when setting a viewController
	// on a FSControlledView that it is not retained.  If it were,
	// then neither the controller nor the view would ever be deallocated.
	// It is therefore EXTREMELY important that when this object IS
	// deallocated, that the viewController on the FSControlledView is
	// set to nil.  If it isn't, then the application WILL CRASH.

	// IMPORTANT: make sure the view knows that this controller no longer exists
	[view setViewController:nil];
	
	// only now is it safe to release the view
	// and all other top level objects
	id object;
	NSEnumerator *enumerator = [topLevelObjects objectEnumerator];
	while (object = [enumerator nextObject]) {
		[object release];
	}

	[topLevelObjects release];	
	[super dealloc];
}

- (FSControlledView *)view {
    if (!view) {
		NSDictionary *table = [NSDictionary dictionaryWithObjectsAndKeys:self, NSNibOwner,
			topLevelObjects, NSNibTopLevelObjects, nil];
		[[NSBundle bundleForClass:[self class]] loadNibFile:[[self class] nibName]
										  externalNameTable:table
												   withZone:[self zone]];
		
		NSAssert(view && [view isKindOfClass:[FSControlledView class]],
				 @"The nib file must load a view of type FSControlledView");
		[view setViewController:self]; // make sure the view knows that we're the controller
    }
    return view;
}

- (BOOL)isViewLoaded {
	return (view != nil);
}

// these are for subclassers,
// default implemenations do nothing
- (void)viewWillActivate { }
- (void)viewDidActivate { }
- (void)viewWillInactivate { }
- (void)viewDidInactivate { }

@end