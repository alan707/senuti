//
//  AIImageAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Dec 02 2003.
//

#import "AIImageAdditions.h"

#import "AIBezierPathAdditions.h"

@interface NSImage (AIImageAdditions_PRIVATE)
- (NSBitmapImageRep *)bitmapRep;
@end

@implementation NSImage (AIImageAdditions)

// Returns an image from the owners bundle with the specified name
+ (NSImage *)imageNamed:(NSString *)name forClass:(Class)inClass
{
    NSBundle	*ownerBundle;
    NSString	*imagePath;
    NSImage		*image;
	
    //Get the bundle
    ownerBundle = [NSBundle bundleForClass:inClass];
	
    //Open the image
    imagePath = [ownerBundle pathForImageResource:name];    
    image = [[NSImage alloc] initWithContentsOfFile:imagePath];
	
    return [image autorelease];
}

//Create and return an opaque bitmap image rep, replacing transparency with [NSColor whiteColor]
- (NSBitmapImageRep *)opaqueBitmapImageRep
{
	NSImage			*tempImage;
	NSEnumerator	*enumerator;
	NSImageRep		*imageRep;
	NSSize			size = [self size];
	
	//Work with a temporary image so we don't modify self
	tempImage = [[[NSImage allocWithZone:[self zone]] initWithSize:size] autorelease];
	
	//Lock before drawing to the temporary image
	[tempImage lockFocus];
	
	//Fill with a white background
	[[NSColor whiteColor] set];
	NSRectFill(NSMakeRect(0, 0, size.width, size.height));
	
	//Draw the image
	[self compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
	
	//We're done drawing
	[tempImage unlockFocus];
	
	//Find an NSBitmapImageRep from the temporary image
	enumerator = [[tempImage representations] objectEnumerator];
	while ((imageRep = [enumerator nextObject])) {
		if ([imageRep isKindOfClass:[NSBitmapImageRep class]])
			break;
	}
	
	//Make one if necessary
	if (!imageRep) {
		imageRep = [NSBitmapImageRep imageRepWithData:[tempImage TIFFRepresentation]];
    }
	
	return (NSBitmapImageRep *)imageRep;
}

- (NSData *)JPEGRepresentation
{	
	return [self JPEGRepresentationWithCompressionFactor:1.0];
}

- (NSData *)JPEGRepresentationWithCompressionFactor:(float)compressionFactor
{
	/* JPEG does not support transparency, but NSImage does. We need to create a non-transparent NSImage
	* before creating our representation or transparent parts will become black.  White is preferable.
	*/
	
	return ([[self opaqueBitmapImageRep] representationUsingType:NSJPEGFileType 
													  properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:compressionFactor] 
																							 forKey:NSImageCompressionFactor]]);	
}

- (NSData *)PNGRepresentation
{
	/* PNG is easy; it supports everything TIFF does, and NSImage's PNG support is great. */

	NSBitmapImageRep	*bitmapRep =  [NSBitmapImageRep imageRepWithData:[self TIFFRepresentation]];
	
	return ([bitmapRep representationUsingType:NSPNGFileType properties:nil]);
}

- (NSData *)BMPRepresentation
{
	/* BMP does not support transparency, but NSImage does. We need to create a non-transparent NSImage
	 * before creating our representation or transparent parts will become black.  White is preferable.
	 */

	return ([[self opaqueBitmapImageRep] representationUsingType:NSBMPFileType properties:nil]);
}

- (NSData *)GIFRepresentation
{
	//This produces ugly output.  Very ugly.

	NSData	*GIFRepresentation = nil;
	
	NSBitmapImageRep *bm = [self bitmapRep]; 
	
	if (bm) {
		NSDictionary *properties =  [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:YES], NSImageDitherTransparency,
			nil];
		
		NSSize size = [self size];
		
		if (size.width > 0 && size.height > 0) {
			
			@try {
				GIFRepresentation = [bm representationUsingType:NSGIFFileType
													 properties:properties];
			}
			@catch(id exc) {
				GIFRepresentation = nil;	// must have failed
			}
		}
	}

	return GIFRepresentation;
}
	
//Draw this image in a rect, tiling if the rect is larger than the image
- (void)tileInRect:(NSRect)rect
{
    NSSize  size = [self size];
    NSRect  destRect = NSMakeRect(rect.origin.x, rect.origin.y, size.width, size.height);
    double  top = rect.origin.y + rect.size.height;
    double  right = rect.origin.x + rect.size.width;
    
    //Tile vertically
    while (destRect.origin.y < top) {
		//Tile horizontally
		while (destRect.origin.x < right) {
			NSRect  sourceRect = NSMakeRect(0, 0, size.width, size.height);
			
			//Crop as necessary
			if ((destRect.origin.x + destRect.size.width) > right) {
				sourceRect.size.width -= (destRect.origin.x + destRect.size.width) - right;
			}
			if ((destRect.origin.y + destRect.size.height) > top) {
				sourceRect.size.height -= (destRect.origin.y + destRect.size.height) - top;
			}
			
			//Draw and shift
			[self compositeToPoint:destRect.origin fromRect:sourceRect operation:NSCompositeSourceOver];
			destRect.origin.x += destRect.size.width;
		}
		destRect.origin.y += destRect.size.height;
    }
}

- (NSImage *)imageByScalingToSize:(NSSize)size
{
	return ([self imageByScalingToSize:size fraction:1.0 flipImage:NO proportionally:YES allowAnimation:YES]);
}

- (NSImage *)imageByFadingToFraction:(float)delta
{
	return [self imageByScalingToSize:[self size] fraction:delta flipImage:NO proportionally:NO allowAnimation:YES];
}

- (NSImage *)imageByScalingToSize:(NSSize)size fraction:(float)delta
{
	return [self imageByScalingToSize:size fraction:delta flipImage:NO proportionally:YES allowAnimation:YES];
}

- (NSImage *)imageByScalingForMenuItem
{
	return [self imageByScalingToSize:NSMakeSize(16,16)
							 fraction:1.0
							flipImage:NO
					   proportionally:YES
					   allowAnimation:NO];	
}

- (NSImage *)imageByScalingToSize:(NSSize)size fraction:(float)delta flipImage:(BOOL)flipImage proportionally:(BOOL)proportionally allowAnimation:(BOOL)allowAnimation
{
	NSSize  originalSize = [self size];
	
	//Proceed only if size or delta are changing
	if ((NSEqualSizes(originalSize, size)) && (delta == 1.0) && !flipImage) {
		return [[self copy] autorelease];
		
	} else {
		NSImage *newImage;
		NSRect	newRect;
		
		//Scale proportionally (rather than stretching to fit) if requested and needed
		if (proportionally && (originalSize.width != originalSize.height)) {
			if (originalSize.width > originalSize.height) {
				//Give width priority: Make the height change by the same proportion as the width will change
				size.height = originalSize.height * (size.width / originalSize.width);
			} else {
				//Give height priority: Make the width change by the same proportion as the height will change
				size.width = originalSize.width * (size.height / originalSize.height);
			}
		}
		
		newRect = NSMakeRect(0,0,size.width,size.height);
		newImage = [[NSImage alloc] initWithSize:size];

		if (flipImage) [newImage setFlipped:YES];		

		NSImageRep	*bestRep;
		if (allowAnimation &&
			(bestRep = [self bestRepresentationForDevice:nil]) &&
			[bestRep isKindOfClass:[NSBitmapImageRep class]] && 
			(delta == 1.0) &&
			([[(NSBitmapImageRep *)bestRep valueForProperty:NSImageFrameCount] intValue] > 1) ) {
			//We've got an animating file, and the current alpha is fine.  Just copy the representation.
			[newImage addRepresentation:[[bestRep copy] autorelease]];
			
		} else {
			[newImage lockFocus];
			//Highest quality interpolation
			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
			[self drawInRect:newRect
					fromRect:NSMakeRect(0,0,originalSize.width,originalSize.height)
				   operation:NSCompositeCopy
					fraction:delta];
			
			[newImage unlockFocus];
		}

		return [newImage autorelease];
	}
}

/*+ (NSImage *)imageFromGWorld:(GWorldPtr)gworld
{
    NSParameterAssert(gworld != NULL);
	
    PixMapHandle pixMapHandle = GetGWorldPixMap( gworld );
    if (LockPixels(pixMapHandle)) {
        Rect 	portRect;
        
		GetPortBounds( gworld, &portRect );
		
        int 	pixels_wide = (portRect.right - portRect.left);
        int 	pixels_high = (portRect.bottom - portRect.top);
        int 	bps = 8;
        int 	spp = 4;
        BOOL 	has_alpha = YES;
		
        NSBitmapImageRep *bitmap_rep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																				pixelsWide:pixels_wide
																				pixelsHigh:pixels_high
																			 bitsPerSample:bps
																		   samplesPerPixel:spp
																				  hasAlpha:has_alpha
																				  isPlanar:NO
																			colorSpaceName:NSDeviceRGBColorSpace
																			   bytesPerRow:0
																			  bitsPerPixel:0] autorelease];
        CGColorSpaceRef 	dst_colorspaceref = CGColorSpaceCreateDeviceRGB();
        CGImageAlphaInfo 	dst_alphainfo = has_alpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone;
        CGContextRef 		dst_contextref = CGBitmapContextCreate([bitmap_rep bitmapData],
																   pixels_wide,
																   pixels_high,
																   bps,
																   [bitmap_rep bytesPerRow],
																   dst_colorspaceref,
																   dst_alphainfo);
        void *pixBaseAddr = GetPixBaseAddr(pixMapHandle);
        long pixmapRowBytes = GetPixRowBytes(pixMapHandle);
		
        CGDataProviderRef dataproviderref = CGDataProviderCreateWithData(NULL, pixBaseAddr, pixmapRowBytes * pixels_high, NULL);
		
        int src_bps = 8;
        int src_spp = 4;
        BOOL src_has_alpha = YES;
		
        CGColorSpaceRef src_colorspaceref = CGColorSpaceCreateDeviceRGB();
		
        CGImageAlphaInfo src_alphainfo = src_has_alpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNone;
		
        CGImageRef src_imageref = CGImageCreate(pixels_wide,
												pixels_high,
												src_bps,
												src_bps * src_spp,
												pixmapRowBytes,
												src_colorspaceref,
												src_alphainfo,
												dataproviderref,
												NULL,
												NO, // shouldInterpolate
												kCGRenderingIntentDefault);
		
        CGRect rect = CGRectMake(0, 0, pixels_wide, pixels_high);
		
        CGContextDrawImage(dst_contextref, rect, src_imageref);
		
        CGImageRelease(src_imageref);
        CGColorSpaceRelease(src_colorspaceref);
        CGDataProviderRelease(dataproviderref);
        CGContextRelease(dst_contextref);
        CGColorSpaceRelease(dst_colorspaceref);
		
        UnlockPixels(pixMapHandle);
		
        NSImage *image = [[[NSImage alloc] initWithSize:NSMakeSize(pixels_wide, pixels_high)] autorelease];
        [image addRepresentation:bitmap_rep];
        return image;
    }
    return nil;
}*/

//Fun drawing toys
//Draw an image, altering and returning the available destination rect
- (NSRect)drawInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position fraction:(float)fraction
{
	//We use our own size for drawing purposes no matter the passed size to avoid distorting the image via stretching
	NSSize	ownSize = [self size];

	//If we're passed a 0,0 size, use the image's size for the area taken up by the image 
	//(which may exceed the actual image dimensions)
	if (size.width == 0 || size.height == 0) size = ownSize;
	
	NSRect	drawRect = [self rectForDrawingInRect:rect atSize:size position:position];
	
	//If we are drawing in a rect wider than we are, center horizontally
	if (drawRect.size.width > ownSize.width) {
		drawRect.origin.x += (drawRect.size.width - ownSize.width) / 2;
		drawRect.size.width -= (drawRect.size.width - ownSize.width);
	}

	//If we are drawing in a rect higher than we are, center vertically
	if (drawRect.size.height > ownSize.height) {
		drawRect.origin.y += (drawRect.size.height - ownSize.height) / 2;
		drawRect.size.height -= (drawRect.size.height - ownSize.height);
	}

	//Draw
	[self drawInRect:drawRect
			fromRect:NSMakeRect(0, 0, ownSize.width, ownSize.height)
		   operation:NSCompositeSourceOver
			fraction:fraction];
	
	//Shift the origin if needed, and decrease the available destination rect width, by the passed size
	//(which may exceed the actual image dimensions)
	if (position == IMAGE_POSITION_LEFT) rect.origin.x += size.width;
	rect.size.width -= size.width;

	return rect;
}

- (NSRect)rectForDrawingInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position
{
	NSRect	drawRect;
	
	//If we're passed a 0,0 size, use the image's size
	if (size.width == 0 || size.height == 0) size = [self size];
	
	//Adjust
	switch (position) {
		case IMAGE_POSITION_LEFT:
			drawRect = NSMakeRect(rect.origin.x,
								  rect.origin.y + (int)((rect.size.height - size.height) / 2.0),
								  size.width,
								  size.height);
		break;
		case IMAGE_POSITION_RIGHT:
			drawRect = NSMakeRect(rect.origin.x + rect.size.width - size.width,
								  rect.origin.y + (int)((rect.size.height - size.height) / 2.0),
								  size.width,
								  size.height);
		break;
		case IMAGE_POSITION_LOWER_LEFT:
			drawRect = NSMakeRect(rect.origin.x,
								  rect.origin.y + (rect.size.height - size.height),
								  size.width,
								  size.height);
		break;
		case IMAGE_POSITION_LOWER_RIGHT:
			drawRect = NSMakeRect(rect.origin.x + (rect.size.width - size.width),
								  rect.origin.y + (rect.size.height - size.height),
								  size.width,
								  size.height);
		break;
	}
	
	return drawRect;
}

//General purpose draw image rounded in a NSRect.
- (NSRect)drawRoundedInRect:(NSRect)rect radius:(float)radius
{
	return [self drawRoundedInRect:rect atSize:NSMakeSize(0,0) position:0 fraction:1.0 radius:radius];
}

//Perhaps if you desired to draw it rounded in the tooltip.
- (NSRect)drawRoundedInRect:(NSRect)rect fraction:(float)fraction radius:(float)radius
{
	return [self drawRoundedInRect:rect atSize:NSMakeSize(0,0) position:0 fraction:fraction radius:radius];
}

//Draw an image, round the corner. Meant to replace the method above.
- (NSRect)drawRoundedInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position fraction:(float)fraction radius:(float)radius
{
	NSRect	drawRect;
	
	//We use our own size for drawing purposes no matter the passed size to avoid distorting the image via stretching
	NSSize	ownSize = [self size];
	
	//If we're passed a 0,0 size, use the image's size for the area taken up by the image 
	//(which may exceed the actual image dimensions)
	if (size.width == 0 || size.height == 0) size = ownSize;
	
	drawRect = [self rectForDrawingInRect:rect atSize:size position:position];
	
	//If we are drawing in a rect wider than we are, center horizontally
	if (drawRect.size.width > ownSize.width) {
		drawRect.origin.x += (drawRect.size.width - ownSize.width) / 2;
		drawRect.size.width -= (drawRect.size.width - ownSize.width);
	}
	
	//If we are drawing in a rect higher than we are, center vertically
	if (drawRect.size.height > ownSize.height) {
		drawRect.origin.y += (drawRect.size.height - ownSize.height) / 2;
		drawRect.size.height -= (drawRect.size.height - ownSize.height);
	}
	
	//Create Rounding.
	[NSGraphicsContext saveGraphicsState];
	NSBezierPath	*clipPath = [NSBezierPath bezierPathWithRoundedRect:drawRect radius:radius];
	[clipPath addClip];
	
	//Draw
	[self drawInRect:drawRect
			fromRect:NSMakeRect(0, 0, ownSize.width, ownSize.height)
		   operation:NSCompositeSourceOver
			fraction:fraction];
	
	[clipPath removeAllPoints];
	[NSGraphicsContext restoreGraphicsState];
	//Shift the origin if needed, and decrease the available destination rect width, by the passed size
	//(which may exceed the actual image dimensions)
	if (position == IMAGE_POSITION_LEFT) rect.origin.x += size.width;
	rect.size.width -= size.width;
	
	return rect;
}

- (NSBitmapImageRep *)getBitmap
{
	[self lockFocus];
	
	NSSize size = [self size];
	NSRect rect = NSMakeRect(0.0, 0.0, size.width, size.height);
	NSBitmapImageRep	*bm = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:rect] autorelease];

	[self unlockFocus];
	
	return bm;
}

//
// NOTE: Black & White images fail miserably
// So we must get their data and blast that into a deeper cache
// Yucky, so we wrap this all up inside this object...
//
- (NSBitmapImageRep *)bitmapRep
{
	NSArray *reps = [self representations];
	int i = [reps count];
	while (i--) {
		NSBitmapImageRep *rep = (NSBitmapImageRep *)[reps objectAtIndex:i];
		if ([rep isKindOfClass:[NSBitmapImageRep class]] &&
			([rep bitsPerPixel] > 2))
			return rep;
	}
	return [self getBitmap];
}

+ (AIBitmapImageFileType)fileTypeOfData:(NSData *)inData
{
	const char *data = [inData bytes];
	unsigned len = [inData length];
	AIBitmapImageFileType fileType = AIUnknownFileType;

	if (len >= 4) {
		if (!strncmp((char *)data, "GIF8", 4))
			fileType = AIGIFFileType;
		else if (!strncmp((char *)data, "\xff\xd8\xff", 3)) /* 4th may be e0 through ef */
			fileType = AIJPEGFileType;
		else if (!strncmp((char *)data, "\x89PNG", 4))
			fileType = AIPNGFileType;
		else if (!strncmp((char *)data, "MM", 2) ||
				 !strncmp((char *)data, "II", 2))
			fileType = AITIFFFileType;
		else if (!strncmp((char *)data, "BM", 2))
			fileType = AIBMPFileType;
	}
	
	return fileType;
}

+ (NSString *)extensionForBitmapImageFileType:(AIBitmapImageFileType)inFileType
{
	NSString *extension = nil;
	switch (inFileType) {
		case AIUnknownFileType:
			break;
		case AITIFFFileType:
			extension = @"tif";
			break;
		case AIBMPFileType:
			extension = @"bmp";
			break;
		case AIGIFFileType:
			extension = @"gif";
			break;
		case AIJPEGFileType:
			extension = @"jpg";
			break;
		case AIPNGFileType:
			extension = @"png";
			break;
		case AIJPEG2000FileType:
			extension = @"jp2";
			break;
	}
	
	return extension;
}

@end
