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

#include <unistd.h>
#include <limits.h>
#include <wctype.h>

@implementation NSString (AICrashReporterStringAdditions)

//stringByEncodingURLEscapes
// Percent escape all characters except for a-z, A-Z, 0-9, '.', '_', and '-'
// Convert spaces to '+'
- (NSString *)stringByEncodingURLEscapes
{
	const char			*UTF8 = [self UTF8String];
	char				*destPtr;
	NSMutableData		*destData;
	register unsigned	 sourceIndex = 0;
	unsigned			 sourceLength = strlen(UTF8);
	register unsigned	 destIndex = 0;

	//this table translates plusses to spaces, and flags all characters that need hex-encoding with 0x00.
	static const char translationTable[256] = {
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		 ' ', 0x00, 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,  0x00,  '-',  '.', 0x00,
		 '0',  '1',  '2',  '3',   '4',  '5',  '6',  '7',
		 '8',  '9', 0x00, 0x00,  0x00, 0x00, 0x00, 0x00,
		0x00,  'A',  'B',  'C',   'D',  'E',  'F',  'G',
		 'H',  'I',  'J',  'K',   'L',  'M',  'N',  'O',
		 'P',  'Q',  'R',  'S',   'T',  'U',  'V',  'W',
		 'X',  'Y',  'Z', 0x00,  0x00, 0x00, 0x00,  '_',
		0x00,  'a',  'b',  'c',   'd',  'e',  'f',  'g',
		 'h',  'i',  'j',  'k',   'l',  'm',  'n',  'o',
		 'p',  'q',  'r',  's',   't',  'u',  'v',  'w',
		 'x',  'y',  'z', 0x00,  0x00, 0x00, 0x00, 0x00,
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
			destPtr[destIndex++] = convertIntToHex(ch / 0x10);
			destPtr[destIndex++] = convertIntToHex(ch % 0x10);
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
	const char			*UTF8 = [self UTF8String];
	char				*destPtr;
	NSMutableData		*destData;
	register unsigned	 sourceIndex = 0;
	unsigned			 sourceLength = strlen(UTF8);
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
			destPtr[destIndex] = ( convertHexToInt(UTF8[sourceIndex]) * 0x10 ) + convertHexToInt(UTF8[sourceIndex+1]);
			sourceIndex += 2;
		} else {
			destPtr[destIndex] = translationTable[ch];
		}

		destIndex++;
	}

	return [[[NSString alloc] initWithBytes:destPtr length:destIndex encoding:NSASCIIStringEncoding] autorelease];
}


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

- (NSString *)stringByAppendingEllipsis
{
	return [self stringByAppendingString:[NSString stringWithUTF8String:"\xE2\x80\xA6"]];
}

@end