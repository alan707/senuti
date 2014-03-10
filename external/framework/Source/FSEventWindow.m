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

#import "FSEventWindow.h"

@implementation FSEventWindow

- (void)sharedInit {
	mouseMovedResponders = [[NSMutableArray alloc] init];
}

- (id)init {
	if ((self = [super init])) {
		[self sharedInit];
	}
	return self;
}

- (id)initWithContentRect:(NSRect)contentRect
				styleMask:(unsigned int)aStyle
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)flag {
	if ((self = [super initWithContentRect:contentRect
								 styleMask:aStyle
								   backing:bufferingType
									 defer:flag])) {
		[self sharedInit];
	}
	return self;
}

- (id)initWithContentRect:(NSRect)contentRect
				styleMask:(unsigned int)aStyle
				  backing:(NSBackingStoreType)bufferingType
					defer:(BOOL)flag
				   screen:(NSScreen *)screen {
	if ((self = [super initWithContentRect:contentRect
								 styleMask:aStyle
								   backing:bufferingType
									 defer:flag
									screen:screen])) {
		[self sharedInit];
	}
	return self;
}

- (void)dealloc {
	[mouseMovedResponders release];
	[super dealloc];
}

- (void)addMouseMovedResponder:(NSResponder *)responder {
	if (![mouseMovedResponders containsObject:responder]) {
		[mouseMovedResponders addObject:responder];
	}
}

- (void)removeMouseMovedResponder:(NSResponder *)responder {
	[mouseMovedResponders removeObjectIdenticalTo:responder];	
}

- (void)mouseMoved:(NSEvent *)theEvent {
	[super mouseMoved:theEvent];

	NSEnumerator *respondersEnumerator = [mouseMovedResponders objectEnumerator];
	NSResponder *responder;
	while (responder = [respondersEnumerator nextObject]) {
		// first responder already gets the response
		// so don't send it to them
		if (responder != [self firstResponder]) {
			[responder mouseMoved:theEvent];
		}
	}
	
}

@end
