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

#import "FSPasteboardAdditions.h"

#define DELEGATE_POINTER_KEY		@"FSPasteboardDelegateKey"
#define CONTEXT_KEY					@"FSPastboardContextKey"

@implementation NSPasteboard (FSPasteboardAdditions)

- (BOOL)setDataDelegate:(id)object withContext:(id)context forType:(NSString *)dataType {
	NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSData dataWithBytes:&object length:sizeof(void *)], DELEGATE_POINTER_KEY,
		context, CONTEXT_KEY, nil, nil];
	return [self setData:[NSKeyedArchiver archivedDataWithRootObject:data] forType:dataType];;
}

- (id)dataFromDelegateForType:(NSString *)dataType {
	NSDictionary *data = [NSKeyedUnarchiver unarchiveObjectWithData:[self dataForType:dataType]];

	id context = [data objectForKey:CONTEXT_KEY];
	id delegate;
	[[data objectForKey:DELEGATE_POINTER_KEY] getBytes:&delegate];
	
	if ([delegate respondsToSelector:@selector(pasteboard:dataForContext:)]) {
		return [delegate pasteboard:self dataForContext:context];
	} else {
		return nil;
	}
}

@end
