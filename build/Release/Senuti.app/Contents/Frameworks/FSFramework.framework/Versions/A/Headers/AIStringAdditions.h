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

@interface NSString (AIStringAdditions)

+ (NSString *)randomStringOfLength:(unsigned int)inLength;

+ (NSString *)stringWithContentsOfUTF8File:(NSString *)path;

+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
+ (id)stringWithBytes:(const void *)inBytes length:(unsigned)inLength encoding:(NSStringEncoding)inEncoding;

+ (id)ellipsis;
- (NSString *)stringByAppendingEllipsis;

- (NSString *)stringByTranslatingByOffset:(int)offset;

- (NSString *)compactedString;

- (int)intValueFromHex;

- (NSString *)stringByExpandingBundlePath;
- (NSString *)stringByCollapsingBundlePath;

- (NSString *)stringByTruncatingTailToWidth:(float)inWidth;

- (NSString *)stringByEncodingURLEscapes;
- (NSString *)stringByDecodingURLEscapes;

- (NSString *)safeFilenameString;

- (NSString *)stringWithEllipsisByTruncatingToLength:(unsigned int)length;

- (NSString *)string;

- (NSString *)stringByEscapingForXMLWithEntities:(NSDictionary *)entities;
- (NSString *)stringByUnescapingFromXMLWithEntities:(NSDictionary *)entities;

- (NSString *)stringByEscapingForShell;
//- (BOOL)isURLEncoded;

/*examples:
 *	receiver                            result
 *	========                            ======
 *	/                                   /
 *	/Users/boredzo                      /
 *	/Volumes/Repository                 /Volumes/Repository
 *	/Volumes/Repository/Downloads       /Volumes/Repository
 *and if /Volumes/Toolbox is your startup disk (as it is mine):
 *	/Volumes/Toolbox/Applications       /
 */
- (NSString *)volumePath;

- (unichar)lastCharacter;
- (unichar)nextToLastCharacter;
- (UTF32Char)lastLongCharacter;
- (NSString *) trimWhiteSpace;

- (NSString *) stripHTML;

- (NSString *) ellipsizeAfterNWords: (int) n;

+ (BOOL) stringIsEmpty: (NSString *) s;

+ (NSString *)uuid;

+ (NSString *)stringWithFloat:(float)f maxDigits:(unsigned)numDigits;

//If you provide a separator object, it will be recorded in the array whenever a newline is encountered.
//Newline is any of CR, LF, CRLF, LINE SEPARATOR, or PARAGRAPH SEPARATOR.
//If you do not provide a separator object (pass nil or use the other method), separators are not recorded; you get only the lines, with nothing between them.
- (NSArray *)allLinesWithSeparator:(NSObject *)separatorObj;
- (NSArray *)allLines;

@end
