/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIStringAdditions.h"

#ifndef BSD_LICENSE_ONLY

#import <Carbon/Carbon.h>
#import "AIColorAdditions.h"
#import "AIScannerAdditions.h"
#import "AIFunctions.h"
#import "AIApplicationAdditions.h"

#include <unistd.h>
#include <limits.h>

#endif //ndef BSD_LICENSE_ONLY

#include <wctype.h>

//From LMX. Included under the BSD license. http://trac.adiumx.com/wiki/LMXParser
static BOOL getSurrogatesForUnicodeScalarValue(const UTF32Char scalar, unichar *outHigh, unichar *outLow);

@implementation NSString (AIStringAdditions)

#ifndef BSD_LICENSE_ONLY

//Random alphanumeric string
+ (NSString *)randomStringOfLength:(unsigned int)inLength
{
	srandom(TickCount());

	if (!inLength) return [NSString string];

	NSString *string = nil;
	char *buf = malloc(inLength);

	if (buf) {
		static const char alphanumeric[] = {
			'0', '1', '2', '3', '4', '5', '6', '7',
			'8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
			'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
			'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
			'W', 'X', 'Y', 'Z'
		};
		register unsigned remaining = inLength;
		while (remaining--) {
			buf[remaining] = alphanumeric[random() % sizeof(alphanumeric)];
		}
		string = [NSString stringWithBytes:buf length:inLength encoding:NSASCIIStringEncoding];
		free(buf);
	}

	return string;
}

/*
 * @brief Read a string from a file, assuming it to be UTF8
 *
 * If it can not be read as UTF8, it will be read as ASCII.
 */
+ (NSString *)stringWithContentsOfUTF8File:(NSString *)path
{
	if (!path) return nil;

	NSString	*string;
	
	NSError	*error = nil;

	string = [NSString stringWithContentsOfFile:path
									   encoding:NSUTF8StringEncoding 
										  error:&error];

	if (error) {
		BOOL	handled = NO;

		if ([[error domain] isEqualToString:NSCocoaErrorDomain]) {
			int		errorCode = [error code];

			//XXX - I'm sure these constants are defined somewhere, but I can't find them. -eds
			if (errorCode == 260) {
				//File not found.
				string = nil;
				handled = YES;

			} else if (errorCode == 261) {
				/* Reason: File could not be opened using text encoding Unicode (UTF-8).
				 * Description: Text encoding Unicode (UTF-8) is not applicable.
				 *
				 * We couldn't read the file as UTF8.  Let the system try to determine the encoding.
				 */
				NSError				*newError = nil;

				string = [NSString stringWithContentsOfFile:path
												   encoding:NSASCIIStringEncoding
													  error:&newError];

				//If there isn't a new error, we recovered reasonably successfully...
				if (!newError) {
					handled = YES;
				}
			}
		}

		if (!handled) {
			NSLog(@"Error reading %@:\n%@; %@.",path,
				  [error localizedDescription], [error localizedFailureReason]);
		}
	}
	
	return string;
}

+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding
{
	return [[[self alloc] initWithData:data encoding:encoding] autorelease];
}
+ (id)stringWithBytes:(const void *)inBytes length:(unsigned)inLength encoding:(NSStringEncoding)inEncoding
{
	return [[[self alloc] initWithBytes:inBytes length:inLength encoding:inEncoding] autorelease];
}

+ (id)ellipsis
{
	return [NSString stringWithUTF8String:"\xE2\x80\xA6"];
}

- (NSString *)stringByAppendingEllipsis
{
	return [self stringByAppendingString:[NSString stringWithUTF8String:"\xE2\x80\xA6"]];
}

- (NSString *)stringByTranslatingByOffset:(int)offset
{
	NSMutableString	*newString = [NSMutableString string];
	unsigned		i, length = [self length];

	for (i = 0 ; i < length ; i++) {
		/* Offset by the desired amount */
		[newString appendFormat:@"%C",([self characterAtIndex:i] + offset)];
	}
	
	return newString;
}

/*	compactedString
 *	returns the string in all lowercase without spaces
 */
- (NSString *)compactedString
{
	NSMutableString 	*outName;
	unsigned			pos = 0, len;
	NSRange				range = NSMakeRange(0, 0);
	
	outName = [self mutableCopy];
	CFStringLowercase((CFMutableStringRef)outName, /*locale*/ NULL);
	len = [outName length];
	
	while (pos < len) {
		if ([outName characterAtIndex:pos] == ' ') {
			if (range.length++ == 0) {
				range.location = pos;
			}
			++pos;
		} else {
			if (range.length) {
				[outName deleteCharactersInRange:range];
				pos  = range.location;
				len -= range.length;
				range.length = 0;
			} else {
				++pos;
			}
		}
	}
	
	return [outName autorelease];
}

- (int)intValueFromHex
{
    NSScanner	*scanner = [NSScanner scannerWithString:self];
    unsigned	value;

    [scanner scanHexInt:&value];

    return value;
}

#define BUNDLE_STRING	@"$$BundlePath$$"
//
- (NSString *)stringByExpandingBundlePath
{
    if ([self hasPrefix:BUNDLE_STRING]) {
        return [[[[NSBundle mainBundle] bundlePath] stringByExpandingTildeInPath] stringByAppendingString:[self substringFromIndex:[BUNDLE_STRING length]]];
    } else {
        return [[self copy] autorelease];
    }
}

//
- (NSString *)stringByCollapsingBundlePath
{
    NSString *bundlePath = [[[NSBundle mainBundle] bundlePath] stringByExpandingTildeInPath];

    if ([self hasPrefix:bundlePath]) {
        return [BUNDLE_STRING stringByAppendingString:[self substringFromIndex:[bundlePath length]]];
    } else {
        return [[self copy] autorelease];
    }
}


- (NSString *)stringByTruncatingTailToWidth:(float)inWidth
{
    NSMutableString 	*string = [self mutableCopy];
    
    //Use carbon to truncate the string (this only works when drawing in the system font!)
    TruncateThemeText((CFMutableStringRef)string, kThemeSmallSystemFont, kThemeStateActive, inWidth, truncEnd, NULL);
    
    return [string autorelease];
}

- (NSString *)stringWithEllipsisByTruncatingToLength:(unsigned int)length
{
	NSString *returnString;
	
	if (length < [self length]) {
		//Truncate and append the ellipsis
		returnString = [[self substringToIndex:length-1] stringByAppendingString:[NSString ellipsis]];
	} else {
		//We don't need to truncate, so don't append an ellipsis
		returnString = [[self copy] autorelease];
	}
	
	return (returnString);
}

- (NSString *)safeFilenameString
{
	unsigned length = [self length];
	
	if (!length)
		return self;

	if (length > NAME_MAX) {
		NSLog(@"-safeFilenameString called on a string longer than %u characters (it will be truncated): @\"%@\"", NAME_MAX, self);
		length = NAME_MAX;
	}

	NSMutableString *string = [self mutableCopy];

	[string replaceOccurrencesOfString:@"/" withString:@"-" options:NSLiteralSearch range:NSMakeRange(0, length)];

	return [string autorelease];
}

//- (NSString *)stringByEncodingURLEscapes
//{
//    NSScanner *s = [NSScanner scannerWithString:self];
//    NSCharacterSet *notUrlCode = [[NSCharacterSet characterSetWithCharactersInString:
//        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$-_.+!*'(),;/?:@=&"] 		invertedSet];
//    NSMutableString *encodedString = [[NSMutableString alloc] initWithString:@""];
//    NSString *read;
//    
//    while (![s isAtEnd])
//    {
//        [s scanUpToCharactersFromSet:notUrlCode intoString:&read];
//        if (read)
//            [encodedString appendString:read];
//        if (![s isAtEnd])
//        {
//            [encodedString appendFormat:@"%%%x", [self characterAtIndex:[s scanLocation]]];
//            [s setScanLocation:[s scanLocation]+1];
//        }
//    }
//    
//    return [encodedString autorelease];
//}
//
//- (NSString *)stringByDecodingURLEscapes
//{
//    NSScanner *s = [NSScanner scannerWithString:self];
//    NSMutableString *decodedString = [[NSMutableString alloc] initWithString:@""];
//    NSString *read;
//    
//    while (![s isAtEnd])
//    {
//        [s scanUpToString:@"%" intoString:&read];
//        if (read)
//            [decodedString appendString:read];
//        if (![s isAtEnd])
//        {
//            [decodedString appendString:[NSString stringWithFormat:@"%c", 
//                [[NSString stringWithFormat:@"%li",
//                    strtol([[self substringWithRange:NSMakeRange([s scanLocation]+1, 2)] cString], 
//                        NULL, 16)] 
//                intValue]]];
//                
//            [s setScanLocation:[s scanLocation]+3];
//
//        }
//    }
//    return [decodedString autorelease];
//
//}
//
//- (BOOL)isURLEncoded
//{
//    NSCharacterSet *notUrlCode = [[NSCharacterSet characterSetWithCharactersInString:
//        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$-_.+!*'(),;/?:@=&"] 		invertedSet];
//    NSCharacterSet *notHexSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCEFabcdef"]
//        invertedSet];
//    NSScanner *s = [NSScanner scannerWithString:self]; 
//    
//    if ([self rangeOfCharacterFromSet:notUrlCode].location != NSNotFound)
//        return NO;
//    
//    while (![s isAtEnd])
//    {
//        [s scanUpToString:@"%" intoString:nil];
//        
//        if ([[self substringWithRange:NSMakeRange([s scanLocation]+1, 2)] rangeOfCharacterFromSet:notHexSet].location != NSNotFound)
//            return NO;
//    }
//    
//    return YES;
//}








//char intToHex(int digit)
//{
//    if (digit > 9) {
//        return ('a' + digit - 10);
//    } else {
//        return ('0' + digit);
//    }
//}
//
//int hexToInt(char hex)
//{
//    if (hex >= '0' && hex <= '9') {
//        return (hex - '0');
//		
//    } else if (hex >= 'a' && hex <= 'f') {
//        return (hex - 'a' + 10);
//		
//    } else if (hex >= 'A' && hex <= 'F') {
//        return (hex - 'A' + 10);
//		
//    } else {
//        return 0;
//		
//    }
//}

//stringByEncodingURLEscapes
// Percent escape all characters except for a-z, A-Z, 0-9, '_', and '-'
// Convert spaces to '+'
- (NSString *)stringByEncodingURLEscapes
{
	NSData				*UTF8Data = [self dataUsingEncoding:NSUTF8StringEncoding];
	const char			*UTF8 = [UTF8Data bytes];
	char				*destPtr;
	NSMutableData		*destData;
	register unsigned	 sourceIndex = 0;
	unsigned			 sourceLength = [UTF8Data length];
	register unsigned	 destIndex = 0;

	//this table translates plusses to spaces, and flags all characters that need hex-encoding with 0x00.
	static const char translationTable[256] = {
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		 ' ',  '!',  '"',  '#',   '$',  '%',  '&', '\'',
		 '(',  ')',  '*',  ' ',   ',',  '-',  '.',  '/',
		 '0',  '1',  '2',  '3',   '4',  '5',  '6',  '7',
		 '8',  '9',  ':',  ';',   '<',  '=',  '>',  '?',
		 '@',  'A',  'B',  'C',   'D',  'E',  'F',  'G',
		 'H',  'I',  'J',  'K',   'L',  'M',  'N',  'O',
		 'P',  'Q',  'R',  'S',   'T',  'U',  'V',  'W',
		 'X',  'Y',  'Z',  '[',  '\\',  ']',  '^',  '_',
		 '`',  'a',  'b',  'c',   'd',  'e',  'f',  'g',
		 'h',  'i',  'j',  'k',   'l',  'm',  'n',  'o',
		 'p',  'q',  'r',  's',   't',  'u',  'v',  'w',
		 'x',  'y',  'z',  '{',   '|',  '}',  '~', 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00
	};

	//Worst case scenario is 3 times the original length (every character escaped)
	destData = [NSMutableData dataWithLength:(sourceLength * 3)];
	destPtr  = [destData mutableBytes];

	while (sourceIndex < sourceLength) {
		unsigned char	ch = UTF8[sourceIndex];
		destPtr[destIndex++] = translationTable[ch];

		if (!translationTable[ch]) {
			//hex-encode.
			destPtr[destIndex-1] = '%';
			destPtr[destIndex++] = intToHex(ch / 0x10);
			destPtr[destIndex++] = intToHex(ch % 0x10);
		}

		sourceIndex++;
	}

	return [[[NSString alloc] initWithBytes:destPtr length:destIndex encoding:NSASCIIStringEncoding] autorelease];
}

//stringByDecodingURLEscapes
// Remove percent escapes for all characters except for a-z, A-Z, 0-9, '_', and '-', converting to original character
// Convert '+' back to a space
- (NSString *)stringByDecodingURLEscapes
{
	NSData				*UTF8Data = [self dataUsingEncoding:NSUTF8StringEncoding];
	const char			*UTF8 = [UTF8Data bytes];
	char				*destPtr;
	NSMutableData		*destData;
	register unsigned	 sourceIndex = 0;
	unsigned			 sourceLength = [UTF8Data length];
	register unsigned	 destIndex = 0;

	//this table translates spaces to plusses, and vice versa.
	static const char translationTable[256] = {
		0x00, 0x01, 0x02, 0x03,  0x04, 0x05, 0x06, 0x07,
		0x08, 0x09, 0x0a, 0x0b,  0x0c, 0x0d, 0x0e, 0x0f,
		0x10, 0x11, 0x12, 0x13,  0x14, 0x15, 0x16, 0x17,
		0x18, 0x19, 0x1a, 0x1b,  0x1c, 0x1d, 0x1e, 0x1f,
		 '+',  '!',  '"',  '#',   '$',  '%',  '&', '\'',
		 '(',  ')',  '*',  ' ',   ',',  '-',  '.',  '/',
		 '0',  '1',  '2',  '3',   '4',  '5',  '6',  '7',
		 '8',  '9',  ':',  ';',   '<',  '=',  '>',  '?',
		 '@',  'A',  'B',  'C',   'D',  'E',  'F',  'G',
		 'H',  'I',  'J',  'K',   'L',  'M',  'N',  'O',
		 'P',  'Q',  'R',  'S',   'T',  'U',  'V',  'W',
		 'X',  'Y',  'Z',  '[',  '\\',  ']',  '^',  '_',
		 '`',  'a',  'b',  'c',   'd',  'e',  'f',  'g',
		 'h',  'i',  'j',  'k',   'l',  'm',  'n',  'o',
		 'p',  'q',  'r',  's',   't',  'u',  'v',  'w',
		 'x',  'y',  'z',  '{',   '|',  '}',  '~', 0x7f,
		0x80, 0x81, 0x82, 0x83,  0x84, 0x85, 0x86, 0x87,
		0x88, 0x89, 0x8a, 0x8b,  0x8c, 0x8d, 0x8e, 0x8f,
		0x90, 0x91, 0x92, 0x93,  0x94, 0x95, 0x96, 0x97,
		0x98, 0x99, 0x9a, 0x9b,  0x9c, 0x9d, 0x9e, 0x9f,
		0xa0, 0xa1, 0xa2, 0xa3,  0xa4, 0xa5, 0xa6, 0xa7,
		0xa8, 0xa9, 0xaa, 0xab,  0xac, 0xad, 0xae, 0xaf,
		0xb0, 0xb1, 0xb2, 0xb3,  0xb4, 0xb5, 0xb6, 0xb7,
		0xb8, 0xb9, 0xba, 0xbb,  0xbc, 0xbd, 0xbe, 0xbf,
		0xc0, 0xc1, 0xc2, 0xc3,  0xc4, 0xc5, 0xc6, 0xc7,
		0xc8, 0xc9, 0xca, 0xcb,  0xcc, 0xcd, 0xce, 0xcf,
		0xd0, 0xd1, 0xd2, 0xd3,  0xd4, 0xd5, 0xd6, 0xd7,
		0xd8, 0xd9, 0xda, 0xdb,  0xdc, 0xdd, 0xde, 0xdf,
		0xe0, 0xe1, 0xe2, 0xe3,  0xe4, 0xe5, 0xe6, 0xe7,
		0xe8, 0xe9, 0xea, 0xeb,  0xec, 0xed, 0xee, 0xef,
		0xf0, 0xf1, 0xf2, 0xf3,  0xf4, 0xf5, 0xf6, 0xf7,
		0xf8, 0xf9, 0xfa, 0xfb,  0xfc, 0xfd, 0xfe, 0xff
	};

	//Best case scenario is 1/3 the original length (every character escaped); worst should be the same length
	destData = [NSMutableData dataWithLength:sourceLength];
	destPtr = [destData mutableBytes];
	
	while (sourceIndex < sourceLength) {
		unsigned char	ch = UTF8[sourceIndex++];

		if (ch == '%') {
			destPtr[destIndex] = ( hexToInt(UTF8[sourceIndex]) * 0x10 ) + hexToInt(UTF8[sourceIndex+1]);
			sourceIndex += 2;
		} else {
			destPtr[destIndex] = translationTable[ch];
		}

		destIndex++;
	}

	return [[[NSString alloc] initWithBytes:destPtr length:destIndex encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString *)string
{
	return self;
}

#endif //ndef BSD_LICENSE_ONLY

//stringByEscapingForXMLWithEntities: and stringByUnescapingFromXMLWithEntities: were written by Peter Hosey and are explicitly released under the BSD license.
/*
 Copyright © 2006 Peter Hosey
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of Peter Hosey nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
- (NSString *)stringByEscapingForXMLWithEntities:(NSDictionary *)entities
{
	static const unichar nbsp = 0xa0;
	NSDictionary *realEntities = entities;

	if ([NSApp isOnTigerOrBetter]) {
		//We can use CF here.
		if (!entities) {
			realEntities = [NSDictionary dictionaryWithObjectsAndKeys:
				@"amp",  @"&",
				@"lt",   @"<",
				@"gt",   @">",
				@"quot", @"\"",
				@"apos", @"'",
				@"nbsp", [NSString stringWithCharacters:&nbsp length:1],
				//Also escape whitespace. CF doesn't do this by default.
				@"#x09", @"\t",
				@"#x0a", @"\n",
				@"#x0b", @"\v",
				@"#x0c", @"\f",
				@"#x0d", @"\r",
				nil];
		}

		return [(NSString *)CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef)self, (CFDictionaryRef)realEntities) autorelease];
	} else {
		//COMPAT 10.3
		//CFXMLCreateStringByEscapingEntities is broken on 10.3.x. We must reinvent the wheel.

		if (entities) {
			//CF expects name=>expansion (the same as the unescape function). We do too, for compatibility with CF, but this is inconvenient to us (we look up entity names by characters, not the other way around).
			//So, we flip the dictionary around so that keys are objects and objects are keys. This way, keys will be characters and objects will be entity names.
			realEntities = [NSDictionary dictionaryWithObjects:[entities allKeys] forKeys:[entities allValues]];
		} else {
			realEntities = [NSDictionary dictionaryWithObjectsAndKeys:
				@"amp",  @"&",
				@"lt",   @"<",
				@"gt",   @">",
				@"quot", @"\"",
				@"apos", @"'",
				@"nbsp", [NSString stringWithCharacters:&nbsp length:1],
				nil];
		}

		NSMutableString *result = [NSMutableString stringWithCapacity:[self length]];

		NSZone *zone = [self zone];
		unsigned i = 0, len = [self length];
		unsigned bufsize = sizeof(unichar) * (len < 4096 ? len : 4096);
		unichar *buf = NSZoneMalloc(zone, bufsize);
		NSAssert1(buf, @"(in stringByEscapingForXMLWithEntities:) Could not allocate %u bytes", bufsize);
		BOOL inSurrogatePair = NO;
		unichar highSurrogateFromPrevBuf = 0;
		while (len) {
			if (len < bufsize)
				bufsize = len;

			[self getCharacters:buf range:(NSRange){ i, bufsize }];

			if (highSurrogateFromPrevBuf) {
				[result appendFormat:@"&#x%@;", UCGetUnicodeScalarValueForSurrogatePair(highSurrogateFromPrevBuf, buf[0])];
			}

			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			for (unsigned j = (highSurrogateFromPrevBuf != 0); j < bufsize; ++j) {
				if ((!inSurrogatePair) && (UCIsSurrogateHighCharacter(buf[j]))) {
					inSurrogatePair = YES;
					continue;
				}

				NSString *str = [NSString stringWithCharacters:&buf[j - inSurrogatePair] length:1 + inSurrogatePair];
				NSString *entityName = [realEntities objectForKey:str];
				if (entityName) {
					[result appendFormat:@"&%@;", entityName];
				} else if (inSurrogatePair) {
					[result appendFormat:@"&#x%@;", UCGetUnicodeScalarValueForSurrogatePair(buf[j - 1], buf[j])];
				} else {
					/* A character that doesn't require surrogates must be escaped if it:
					 *		- is 0x7f (DEL) or higher, or
					 *		- is not printable.
					 *
					 * This includes whitespace. We escape whitespace so that it will not be collapsed by the parser.
					 */
					if ((buf[j] > 0x7e) || !isprint(buf[j])) {
						[result appendFormat:@"&#x%02x;", buf[j]];
					} else {
						[result appendString:str];
					}
				}
			}
			[pool release];

			if (inSurrogatePair) {
				highSurrogateFromPrevBuf = buf[bufsize - 1];
			} else {
				highSurrogateFromPrevBuf = 0;
			}

			len -= bufsize;
		}
		NSZoneFree(zone, buf);

		return [NSString stringWithString:result];
	}
}
- (NSString *)stringByUnescapingFromXMLWithEntities:(NSDictionary *)entities
{
	if ([NSApp isOnTigerOrBetter]) {
		return [(NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)self, (CFDictionaryRef)entities) autorelease];
	} else {
		//COMPAT 10.3

		if (!entities) {
			static const unichar nbsp = 0xa0;
			entities = [NSDictionary dictionaryWithObjectsAndKeys:
				@"&",  @"amp",
				@"<",  @"lt",
				@">",  @"gt",
				@"\"", @"quot",
				@"'",  @"apos",
				[NSString stringWithCharacters:&nbsp length:1], @"nbsp",
				nil];
		}

		unsigned len = [self length];
		NSMutableString *result = [NSMutableString stringWithCapacity:len];
		NSScanner *scanner = [NSScanner scannerWithString:self];
		[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithRange:(NSRange){ 0, 0 }]];

		NSString *chunk = nil;
		while (YES) { //Actual condition is below.
			chunk = nil;
			if ([scanner scanUpToString:@"&" intoString:&chunk]) {
				[result appendString:chunk];
			}
			[scanner scanString:@"&" intoString:NULL];

			//Condition is here.
			if ([scanner scanLocation] >= len)
				break;

			if ([scanner scanString:@"#" intoString:NULL]) {
				NSString *hexIdentifier = nil;
				if ([scanner scanString:@"x" intoString:&hexIdentifier] || [scanner scanString:@"X" intoString:&hexIdentifier]) {
					//Probably hex.
					unsigned unichar32 = 0xffff;
					if (![scanner scanHexInt:&unichar32]) {
						[result appendFormat:@"&#%@", hexIdentifier];
					} else if (![scanner scanString:@";" intoString:NULL]) {
						[result appendFormat:@"&#%@%u", hexIdentifier, unichar32];
					} else {
						unichar high, low;
						if (getSurrogatesForUnicodeScalarValue(unichar32, &high, &low)) {
							[result appendFormat:@"%C%C", high, low];
						} else {
							[result appendFormat:@"%C", low];
						}
					}
				} else {
					//Not hex. Hopefully decimal.
					int unichar32 = 65535; //== 0xffff
					if (![scanner scanInt:&unichar32]) {
						[result appendString:@"&#"];
					} else if (![scanner scanString:@";" intoString:NULL]) {
						[result appendFormat:@"&#%i", unichar32];
					} else {
						unichar high, low;
						if (getSurrogatesForUnicodeScalarValue(unichar32, &high, &low)) {
							[result appendFormat:@"%C%C", high, low];
						} else {
							[result appendFormat:@"%C", low];
						}
					}
				}
			} else {
				//Not a numeric entity. Should be a named entity.
				NSString *entityName = nil;
				if (![scanner scanUpToString:@";" intoString:&entityName]) {
					[result appendString:@"&"];
				} else {
					//Strip the semicolon.
					NSString *entity = [entities objectForKey:entityName];
					if (entity) {
						[result appendString:entity];

					} else {
						NSLog(@"-[NSString(AIStringAdditions) stringByUnescapingFromXMLWithEntities]: Named entity %@ unknown.", entityName);
					}
					[scanner scanString:@";" intoString:NULL];
				}
			}
		}

		return [NSString stringWithString:result];
	}
}

#ifndef BSD_LICENSE_ONLY

enum characterNatureMask {
	whitespaceNature = 0x1, //space + \t\n\r\f\a 
	shellUnsafeNature, //backslash + !$`"'
};
static enum characterNatureMask characterNature[USHRT_MAX+1] = {
	//this array is initialised such that the space character (0x20)
	//	does not have the whitespace nature.
	//this was done for brevity, as the entire array is bzeroed and then
	//	properly initialised in -stringByEscapingForShell below.
	0,0,0,0, 0,0,0,0, //0x00..0x07
	0,0,0,0, 0,0,0,0, //0x08..0x0f
	0,0,0,0, 0,0,0,0, //0x10..0x17
	0,0,0, //0x18..0x20
};

- (NSString *)stringByEscapingForShell
{
	if (!(characterNature[' '] & whitespaceNature)) {
		//if space doesn't have the whitespace nature, clearly we need to build the nature array.

		//first, set all characters to zero.
		bzero(&characterNature, sizeof(characterNature));

		//then memorise which characters have the whitespace nature.
		characterNature['\a'] = whitespaceNature;
		characterNature['\t'] = whitespaceNature;
		characterNature['\n'] = whitespaceNature;
		characterNature['\f'] = whitespaceNature;
		characterNature['\r'] = whitespaceNature;
		characterNature[' ']  = whitespaceNature;
		//NOTE: if you give more characters the whitespace nature, be sure to
		//	update escapeNames below.

		//finally, memorise which characters have the unsafe (for shells) nature.
		characterNature['\\'] = shellUnsafeNature;
		characterNature['\''] = shellUnsafeNature;
		characterNature['"']  = shellUnsafeNature;
		characterNature['`']  = shellUnsafeNature;
		characterNature['!']  = shellUnsafeNature;
		characterNature['$']  = shellUnsafeNature;
		characterNature['&']  = shellUnsafeNature;
		characterNature['|']  = shellUnsafeNature;
	}

	unsigned myLength = [self length];
	unichar *myBuf = malloc(sizeof(unichar) * myLength);
	if (!myBuf) return nil;
	[self getCharacters:myBuf];
	const unichar *myBufPtr = myBuf;

	size_t buflen = 0;
	unichar *buf = NULL;

	const size_t buflenIncrement = getpagesize() / sizeof(unichar);

	/*the boundary guard happens everywhere that i increases, and MUST happen
	 *	at the beginning of the loop.
	 *
	 *initialising buflen to 0 and buf to NULL as we have done above means that
	 *	realloc will act as malloc:
	 *	-	i is 0 at the beginning of the loop
	 *	-	so is buflen
	 *	-	and buf is NULL
	 *	-	realloc(NULL, ...) == malloc(...)
	 *
	 *oh, and 'SBEFS' stands for String By Escaping For Shell
	 *	(the name of this method).
	 */
#define SBEFS_BOUNDARY_GUARD \
	do { \
		if (i == buflen) { \
			buf = realloc(buf, sizeof(unichar) * (buflen += buflenIncrement)); \
			if (!buf) { \
				NSLog(@"in stringByEscapingForShell: could not allocate %lu bytes", (unsigned long)(sizeof(unichar) * buflen)); \
				free(myBuf); \
				return nil; \
			} \
		} \
	} while (0)

	unsigned i = 0;
	for (; myLength--; ++i) {
		SBEFS_BOUNDARY_GUARD;

		if (characterNature[*myBufPtr] & whitespaceNature) {
			//escape this character using a named escape
			static unichar escapeNames[] = {
				0, 0, 0, 0, 0, 0, 0,
				'a', //0x07 BEL: '\a' 
				0,
				't', //0x09 HT: '\t'
				'n', //0x0a LF: '\n'
				0,
				'f', //0x0c FF: '\f'
				'r', //0x0d CR: '\r'
				0, 0, //0x0e-0x0f
				0, 0, 0, 0,  0, 0, 0, 0, //0x10-0x17
				0, 0, 0, 0,  0, 0, 0, 0, //0x18-0x1f
				' ', //0x20 SP: '\ '
			};
			buf[i++] = '\\';
			SBEFS_BOUNDARY_GUARD;
			buf[i] = escapeNames[*myBufPtr];
		} else {
			if (characterNature[*myBufPtr] & shellUnsafeNature) {
				//escape this character
				buf[i++] = '\\';
				SBEFS_BOUNDARY_GUARD;
			}

			buf[i] = *myBufPtr;
		}
		++myBufPtr;
	}

#undef SBEFS_BOUNDARY_GUARD

	free(myBuf);

	NSString *result = [NSString stringWithCharacters:buf length:i];
	free(buf);

	return result;
}

- (NSString *)volumePath
{
	NSEnumerator *pathEnum = [[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] objectEnumerator];
	NSString *volumePath;
	while ((volumePath = [pathEnum nextObject])) {
		if ([self hasPrefix:[volumePath stringByAppendingString:@"/"]])
			break;
	}
	if (!volumePath)
		volumePath = @"/";
	return volumePath;
}

- (unichar)lastCharacter {
	unsigned length = [self length];
	if (length < 1)
		return 0xffff;
	else
		return [self characterAtIndex:length - 1];
}
- (unichar)nextToLastCharacter {
	unsigned length = [self length];
	if (length < 2)
		return 0xffff;
	else
		return [self characterAtIndex:length - 2];
}
- (UTF32Char)lastLongCharacter {
	unichar nextToLast = [self nextToLastCharacter];
	unichar last       = [self lastCharacter];
	if (UCIsSurrogateHighCharacter(nextToLast) && UCIsSurrogateLowCharacter(last)) {
		return UCGetUnicodeScalarValueForSurrogatePair(nextToLast, last);
	} else {
		return last;
	}
}

- (NSString *) trimWhiteSpace {
	
	NSMutableString *s = [[self mutableCopy] autorelease];
	
	CFStringTrimWhitespace ((CFMutableStringRef) s);
	
	return (NSString *) [[s copy] autorelease];
} /*trimWhiteSpace*/


- (NSString *) ellipsizeAfterNWords: (int) n {
	
	NSArray *stringComponents = [self componentsSeparatedByString: @" "];
	NSMutableArray *componentsCopy = [stringComponents mutableCopy];
	int ix = n;
	int len = [componentsCopy count];
	
	if (len < n)
		ix = len;
	
	[componentsCopy removeObjectsInRange: NSMakeRange (ix, len - ix)];
	
	return [componentsCopy componentsJoinedByString: @" "];
} /*ellipsizeAfterNWords*/


- (NSString *) stripHTML {
	
	int len = [self length];
	NSMutableString *s = [NSMutableString stringWithCapacity: len];
	int i = 0, level = 0;
	
	for (i = 0; i < len; i++) {
		
		NSString *ch = [self substringWithRange: NSMakeRange (i, 1)];
		
		if ([ch isEqualTo: @"<"])
			level++;
		
		else if ([ch isEqualTo: @">"]) {
			
			level--;
			
			if (level == 0)			
				[s appendString: @" "];
		} /*else if*/
		
		else if (level == 0)			
			[s appendString: ch];
	} /*for*/
	
	return (NSString *) [[s copy] autorelease];
} /*stripHTML*/


+ (BOOL) stringIsEmpty: (NSString *) s {
	
	NSString *copy;
	
	if (s == nil)
		return (YES);
	
	if ([s isEqualTo: @""])
		return (YES);
	
	copy = [[s copy] autorelease];
	
	if ([[copy trimWhiteSpace] isEqualTo: @""])
		return (YES);
	
	return (NO);
} /*stringIsEmpty*/

+ (NSString *)uuid
{
	CFUUIDRef	uuid;
	NSString	*uuidStr;
	
	uuid = CFUUIDCreate(NULL);
	uuidStr = (NSString *)CFUUIDCreateString(NULL, uuid);
	CFRelease(uuid);
	
	return [uuidStr autorelease];
}

+ (NSString *)stringWithFloat:(float)f maxDigits:(unsigned)numDigits
{
	//012345678 <-Indices.
	//42.123400 <-Assuming numDigits = 6.
	//^-----^   <-Returns this substring.
	//42.000000
	//^^        <-Returns this substring (everything before the decimal point) for a whole number.
	NSString *format = numDigits ? [NSString stringWithFormat:@"%%.%uf", numDigits] : @"%f";
	NSString *str = [NSString stringWithFormat:format, (double)f];
	unsigned i = [str length];
	while (i-- > 0) {
		if ([str characterAtIndex:i] != '0') {
			//If we have run out of zeroes, this is a whole number. Leave off the decimal point.
			//Not incrementing i means that the decimal point will be dropped.
			if ([str characterAtIndex:i] != '.') ++i;
			break;
		}
	}
	return [str substringToIndex:i];
}

- (NSArray *)allLinesWithSeparator:(NSObject *)separatorObj
{
	NSMutableArray *lines = [NSMutableArray array];

	enum { LINE_SEPARATOR = 0x2028, PARAGRAPH_SEPARATOR = 0x2029 };

	BOOL lastWasCR = NO;
	BOOL lastWasNewline = NO;
	NSRange captureRange = { 0, 0 };
	unsigned length = [self length];
	for (unsigned i = 0; i < length; ++i) {
		unichar ch = [self characterAtIndex:i];
		if (ch == '\r' || ch == '\n' || ch == LINE_SEPARATOR || ch == PARAGRAPH_SEPARATOR) {
			if (lastWasCR && ch == '\n') {
				lastWasCR = NO;
				++captureRange.location;
				continue;
			}

			captureRange.length = i - captureRange.location;
			[lines addObject:[self substringWithRange:captureRange]];
			if (separatorObj) [lines addObject:separatorObj];

			captureRange.location = i + 1;

			lastWasNewline = YES;
		} else {
			lastWasNewline = lastWasCR = NO;
		}
	}

	captureRange.length = length - captureRange.location;
	if (captureRange.length) {
		[lines addObject:[self substringWithRange:captureRange]];
	}

	return [NSArray arrayWithArray:lines];
}
- (NSArray *)allLines
{
	return [self allLinesWithSeparator:nil];
}

#endif //ndef BSD_LICENSE_ONLY

@end

static BOOL getSurrogatesForUnicodeScalarValue(const UTF32Char scalar, unichar *outHigh, unichar *outLow) {
	if(scalar <= 0xffff) {
		if(outHigh)
			*outHigh = 0x0000;
		if(outLow)
			*outLow  = scalar;
		return NO;
	}

	//note: names uuuuu, wwww, and xxxxx+ are taken from the Unicode book (section 3.9, table 3-4).
	union {
		UTF32Char scalar;
		struct {
			unsigned unused:     11;
			unsigned uuuuu:       5;
			unsigned xxxxxx:      6;
			unsigned xxxxxxxxxx: 10;
		} components;
	} componentsUnion = {
		.scalar = scalar
	};

	if(outHigh) {
		union {
			struct {
				unsigned highPrefix: 6;
				unsigned wwww:       4;
				unsigned xxxxxx:     6;
			} highComponents;
			unichar codeUnit;
		} highUnion = {
			.highComponents = {
				.highPrefix = 0x36, //0b110110
				.wwww   = componentsUnion.components.uuuuu - 1,
				.xxxxxx = componentsUnion.components.xxxxxx,
			}
		};
		*outHigh = highUnion.codeUnit;
	}

	if(outLow) {
		union {
			struct {
				unsigned lowPrefix:   6;
				unsigned xxxxxxxxxx: 10;
			} lowComponents;
			unichar codeUnit;
		} lowUnion = {
			.lowComponents = {
				.lowPrefix = 0x37, //0b110111
				.xxxxxxxxxx = componentsUnion.components.xxxxxxxxxx,
			}
		};
		*outLow = lowUnion.codeUnit;
	};

	return YES;
}
