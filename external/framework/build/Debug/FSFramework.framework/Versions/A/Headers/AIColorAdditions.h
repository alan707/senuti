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

@interface NSDictionary (AIColorAdditions_RGBTxtFiles)

//see /usr/share/emacs/(some version)/etc/rgb.txt for an example of such a file.
//the pathname does not need to end in 'rgb.txt', but it must be a file in UTF-8 encoding.
//the keys are colour names (all converted to lowercase); the values are RGB NSColors.
+ (id)dictionaryWithContentsOfRGBTxtFile:(NSString *)path;

@end

@interface NSColor (AIColorAdditions_RGBTxtFiles)

+ (NSDictionary *)colorNamesDictionary;

@end

@interface NSColor (AIColorAdditions_Comparison)

- (BOOL)equalToRGBColor:(NSColor *)inColor;

@end

@interface NSColor (AIColorAdditions_DarknessAndContrast)

- (BOOL)colorIsDark;
- (BOOL)colorIsMedium;
- (NSColor *)darkenBy:(float)amount;
- (NSColor *)darkenAndAdjustSaturationBy:(float)amount;
- (NSColor *)colorWithInvertedLuminance;
- (NSColor *)contrastingColor;

@end

void getHueLuminanceSaturationFromRGB(float *hue, float *luminance, float *saturation, float r, float g, float b);
void getRGBFromHueLuminanceSaturation(float *r, float *g, float *b, float hue, float luminance, float saturation);

@interface NSColor (AIColorAdditions_HLS)

- (void)getHue:(float *)hue luminance:(float *)luminance saturation:(float *)saturation;
+ (NSColor *)colorWithCalibratedHue:(float)hue luminance:(float)luminance saturation:(float)saturation alpha:(float)alpha;
- (NSColor *)adjustHue:(float)dHue saturation:(float)dSat brightness:(float)dBrit;

@end

@interface NSColor (AIColorAdditions_RepresentingColors)

- (NSString *)hexString;

- (NSString *)stringRepresentation;

- (NSString *)CSSRepresentation;

@end

int hexToInt(char hex);
char intToHex(int digit);

@interface NSString (AIColorAdditions_RepresentingColors)

- (NSColor *)representedColor;
- (NSColor *)representedColorWithAlpha:(float)alpha;

@end

@interface NSColor (AIColorAdditions_RandomColor)

//these use arc4random() for their random numbers. there is no need to seed anything.
//+randomColor returns alpha=1.0, whereas +randomColorWithAlpha will use a random alpha value.
+ (NSColor *)randomColor;
+ (NSColor *)randomColorWithAlpha;

@end

@interface NSColor (AIColorAdditions_HTMLSVGCSSColors)

/*this accepts HTML/SVG/CSS colour names (e.g. 'blue', 'yellow') and
 *	hex colour specifications (e.g. '#00f', '#ffff00').
 *it is the same as [colorWithHTMLString:str defaultColor:nil].
 */
+ (id)colorWithHTMLString:(NSString *)str;
/*if the string is not a recognised colour name, or it's an invalid colour
 *	constant (meaning less than three digits - shorter-than-expected long
 *	colours such as #ff000 are handled gracefully in the same fashion as
 *	WebKit, by zero-extending the input), defaultColor is returned.
 *it is safe for defaultColor to be nil.
 */
+ (id)colorWithHTMLString:(NSString *)str defaultColor:(NSColor *)defaultColor;

@end
