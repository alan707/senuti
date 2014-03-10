//
//  AIImageAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Dec 02 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

typedef enum {
    AIButtonActive = 0,
    AIButtonPressed,
    AIButtonUnknown,
    AIButtonDisabled,
    AIButtonHovered
} AICloseButtonState;

typedef enum {
	IMAGE_POSITION_LEFT = 0,
	IMAGE_POSITION_RIGHT,
	IMAGE_POSITION_LOWER_LEFT,
	IMAGE_POSITION_LOWER_RIGHT
} IMAGE_POSITION;

typedef enum {
	AIUnknownFileType = -9999,
	AITIFFFileType = NSTIFFFileType,
    AIBMPFileType = NSBMPFileType,
    AIGIFFileType = NSGIFFileType,
    AIJPEGFileType = NSJPEGFileType,
    AIPNGFileType = NSPNGFileType,
    AIJPEG2000FileType = NSJPEG2000FileType
} AIBitmapImageFileType;

@interface NSImage (AIImageAdditions)

+ (NSImage *)imageNamed:(NSString *)name forClass:(Class)inClass;

+ (AIBitmapImageFileType)fileTypeOfData:(NSData *)inData;
+ (NSString *)extensionForBitmapImageFileType:(AIBitmapImageFileType)inFileType;

- (NSData *)JPEGRepresentation;
- (NSData *)JPEGRepresentationWithCompressionFactor:(float)compressionFactor;
- (NSData *)PNGRepresentation;
- (NSData *)GIFRepresentation;
- (NSData *)BMPRepresentation;
- (void)tileInRect:(NSRect)rect;
- (NSImage *)imageByScalingToSize:(NSSize)size;
- (NSImage *)imageByFadingToFraction:(float)delta;
- (NSImage *)imageByScalingToSize:(NSSize)size fraction:(float)delta;
- (NSImage *)imageByScalingForMenuItem;
- (NSImage *)imageByScalingToSize:(NSSize)size fraction:(float)delta flipImage:(BOOL)flipImage proportionally:(BOOL)proportionally allowAnimation:(BOOL)allowAnimation;
//+ (NSImage *)imageFromGWorld:(GWorldPtr)gWorldPtr;
- (NSRect)drawRoundedInRect:(NSRect)rect radius:(float)radius;
- (NSRect)drawRoundedInRect:(NSRect)rect fraction:(float)fraction radius:(float)radius;
- (NSRect)drawRoundedInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position fraction:(float)fraction radius:(float)radius;
- (NSRect)drawInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position fraction:(float)fraction;
- (NSRect)rectForDrawingInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position;

- (NSBitmapImageRep *)bitmapRep;

@end

//Defined in AppKit.framework
@interface NSImageCell(NSPrivateAnimationSupport)
- (BOOL)_animates;
- (void)_setAnimates:(BOOL)fp8;
- (void)_startAnimation;
- (void)_stopAnimation;
- (void)_animationTimerCallback:fp8;
@end
