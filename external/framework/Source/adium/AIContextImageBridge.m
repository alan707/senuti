//
//  AIContextImageBridge.m
//  Adium
//
//  Created by Mac-arena the Bored Zo on Thu Feb 12 2004.
//

#import "AIContextImageBridge.h"

@interface AIContextImageBridge(PRIVATE)
@end

enum {
	defaultBitsPerComponent = 8,
	defaultComponentsPerPixel = 4,
};
const BOOL defaultHasAlpha = YES;

@implementation AIContextImageBridge

- (id)initWithSize:(NSSize)size
{
	return [self initWithSize:size bitsPerComponent:defaultBitsPerComponent componentsPerPixel:defaultComponentsPerPixel hasAlpha:defaultHasAlpha];
}

- (id)initWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha
{
	unsigned bytesPerRow = (sizeof(unsigned char) * ((bpc / 8) * cpp)) * (unsigned)size.width;

	//we use calloc because it fills the buffer with 0 - that includes the
	//  alpha, so when calloc is done, the buffer is filled with transparent.
	buffer = calloc(bytesPerRow * (unsigned)size.height, sizeof(unsigned char));
	if (buffer == NULL) return nil;

	CGColorSpaceRef deviceRGB = CGColorSpaceCreateDeviceRGB();
	if (deviceRGB == NULL) {
		free(buffer);
		return nil;
	}

	context = CGBitmapContextCreate(buffer, size.width, size.height, bpc, bytesPerRow, deviceRGB, hasAlpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone);
	CFRelease(deviceRGB);
	if (context == NULL) {
		free(buffer);
		return nil;
	}

	image = nil;
	mysize = size;
	mybitsPerComponent = bpc;
	mycomponentsPerPixel = cpp;
	myhasAlpha = hasAlpha;

	return self;
}

+ (id)bridgeWithSize:(NSSize)size
{
	return [[[self alloc] initWithSize:size] autorelease];
}

+ (id)bridgeWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha
{
	return [[[self alloc] initWithSize:size
					  bitsPerComponent:defaultBitsPerComponent
					componentsPerPixel:defaultComponentsPerPixel
							  hasAlpha:defaultHasAlpha] autorelease];
}

- (void)dealloc
{
	if (buffer) free(buffer);
	if (context) CGContextRelease(context);
	[image release];

	[super dealloc];
}

#pragma mark Accessors

- (unsigned char *)buffer;
{
	return buffer;
}

- (CGContextRef)context;
{
	return context;
}

- (NSImage *)image;
{
	if (image == nil) {
		unsigned bitsPerPixel = mybitsPerComponent  * mycomponentsPerPixel;
		unsigned bytesPerRow  = (bitsPerPixel / 8U) * mysize.width;
		NSBitmapImageRep *representation = [[[NSBitmapImageRep alloc]
							initWithBitmapDataPlanes:&buffer
							pixelsWide:mysize.width
							pixelsHigh:mysize.height
							bitsPerSample:mybitsPerComponent
							samplesPerPixel:mycomponentsPerPixel
							hasAlpha:myhasAlpha
							isPlanar:NO
							colorSpaceName:NSDeviceRGBColorSpace
							bytesPerRow:bytesPerRow
							bitsPerPixel:bitsPerPixel] autorelease];
		image = [[NSImage alloc] initWithSize:mysize];
		[image addRepresentation:representation];
	}
	return image;
}

- (unsigned)bitsPerComponent
{
	return mybitsPerComponent;
}

- (unsigned)componentsPerPixel
{
	return mycomponentsPerPixel;
}

- (NSSize)size
{
	return mysize;
}

#pragma mark Icon Services interfaces
//Icon Services interfaces.
//gives you a nice Cocoa interface for drawing icons in the context.
//comes in full and abstracted flavours.

- (IconRef)getIconWithType:(OSType)type
{
	return [self getIconWithType:type creator:0];
}

- (IconRef)getIconWithType:(OSType)type creator:(OSType)creator
{
	IconRef icon;
	OSStatus err;

	err = GetIconRef(kOnSystemDisk, creator, type, &icon);
	return (err == noErr) ? icon : NULL;
}

- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds
{
	OSStatus err = [self plotIcon:icon inRect:bounds alignment:kAlignNone transform:kTransformNone labelRGBColor:NULL flags:kPlotIconRefNormalFlags];

	return err;
}

- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags
{
	RGBColor  rgb;
	RGBColor *rgbptr;
	if (color != nil) {
		float red, green, blue;
		[color getRed:&red green:&green blue:&blue alpha:NULL];
		rgb.red   = 65535 * red;
		rgb.green = 65535 * green;
		rgb.blue  = 65535 * blue;
		rgbptr = &rgb;
	} else {
		rgbptr = NULL;
	}

	return [self plotIcon:icon inRect:bounds alignment:align transform:transform labelRGBColor:rgbptr flags:flags];
}

- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags
{
	RGBColor rgb;
	OSStatus err;

	err = GetLabel(label, &rgb, /*labelString*/ NULL);
	if (err == noErr) {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelRGBColor:&rgb flags:flags];
	}

	return err;
}

- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const struct RGBColor *)color flags:(PlotIconRefFlags)flags
{
	if (icon == NULL) return NO;

	CGRect cgbounds = CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);

	OSStatus err = PlotIconRefInContext(context, &cgbounds, align, transform, color, flags, icon);

	return err;
}

#pragma mark Icon Services conveniences

//conveniences.
//these substitute plotIconWithType: and plotIconWithType:creator: for
//  plotIcon: above.

#pragma mark ...without creator

- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds
{
	IconRef icon = [self getIconWithType:type];

	if (icon == NULL) {
		return noSuchIconErr;
	} else {
		OSStatus err = [self plotIcon:icon inRect:bounds];
		ReleaseIconRef(icon);
		return err;
	}
}

- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags
{
	[color retain];

	IconRef icon = [self getIconWithType:type];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelNSColor:color flags:flags];
		ReleaseIconRef(icon);
	}

	[color release];

	return err;
}

- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags
{
	IconRef icon = [self getIconWithType:type];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelIndex:label flags:flags];
		ReleaseIconRef(icon);
	}

	return err;
}

- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const struct RGBColor *)color flags:(PlotIconRefFlags)flags
{
	IconRef icon = [self getIconWithType:type];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelRGBColor:color flags:flags];
		ReleaseIconRef(icon);
	}

	return err;
}

#pragma mark ...with creator

- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds
{
	IconRef icon = [self getIconWithType:type creator:creator];

	if (icon == NULL) {
		return noSuchIconErr;
	} else {
		OSStatus err = [self plotIcon:icon inRect:bounds];
		ReleaseIconRef(icon);
		return err;
	}
}

- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags
{
	[color retain];

	IconRef icon = [self getIconWithType:type creator:creator];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelNSColor:color flags:flags];
		ReleaseIconRef(icon);
	}

	[color release];

	return err;
}

- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags
{
	IconRef icon = [self getIconWithType:type creator:creator];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelIndex:label flags:flags];
		ReleaseIconRef(icon);
	}

	return err;
}

- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const struct RGBColor *)color flags:(PlotIconRefFlags)flags
{
	IconRef icon = [self getIconWithType:type creator:creator];
	OSStatus err;

	if (icon == NULL) {
		err = noSuchIconErr;
	} else {
		err = [self plotIcon:icon inRect:bounds alignment:align transform:transform labelRGBColor:color flags:flags];
		ReleaseIconRef(icon);
	}

	return err;
}

@end
