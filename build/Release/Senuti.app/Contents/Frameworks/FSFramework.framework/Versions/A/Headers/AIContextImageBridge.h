//
//  AIContextImageBridge.h
//  Adium
//
//  Created by Mac-arena the Bored Zo on Thu Feb 12 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

/*!	@class AIContextImageBridge AIContextImageBridge.h <AIUtilities/AIContextImageBridge.h>
 *	@brief For drawing using Quartz to an \c NSImage, and for creating an \c NSImage from icons obtained from Icon Services.
 *
 *	@par
 *	There is overlap here with \c NSImage and \c NSWorkspace: You can obtain a \c CGContext from the current \c NSGraphicsContext while focus is locked on an \c NSImage, and \c NSWorkspace provides a basic method (<code>-[NSWorkspace iconForFileType:]</code>) that implements the most basic Icon Services functionality.
 *
 *	@par
 *	The advantages of \c NSGraphicsContext over this class's main purpose can be profiled and debated another day. The Icon Services support is the clearest advantage, being much more flexible than NSWorkspace's one method. It is implemented on top of the core functionality of this class: mapping a \c CGContext to an \c NSImage using a common backing store. All of the Icon Services-wrapper methods return an \c OSStatus error value, as obtained from Icon Services itself.
 *
 *	@par
 *	Both \c CGBitmapContext and \c NSBitmapImageRep take a pointer to memory in which the object's pixels are to be stored. A context-image bridge creates the backing, a \c CGBitmapContext, and a \c NSBitmapImageRep, with the two objects both given the same backing and the same pixel format. Thus, drawing into the context changes the image shown by the \c NSBitmapImageRep.
 *
 *	@par
 *	The \c NSBitmapImageRep is created lazily. Creation is held off until you call \c -image, at which point both the image rep and the image are created and kept. The same image will be returned for the rest of the life of the bridge.
 */
@interface AIContextImageBridge : NSObject
{
	unsigned char *buffer; //the backing store for both the context and the image representation.
	CGContextRef context;
	NSImage *image;
@private
//	NSBitmapImageRep *representation;
	NSSize mysize;
	unsigned mybitsPerComponent; //defaults to 8U.
	unsigned mycomponentsPerPixel; //defaults to 4U.
	BOOL myhasAlpha; //defaults to YES.
}

/*!	@brief Create a context-image bridge.
 *
 *	Both the context and the image will be created with the given size in pixels.
 *
 *	@return A shiny new \c AIContextImageBridge instance.
 */
- (id)initWithSize:(NSSize)size;
/*!	@brief Create a context-image bridge with a specific pixel format.
 *
 *	@par
 *	Both the context and the image will be created with the given size in pixels.
 *
 *	@par
 *	By default, a context-image bridge is created using 32-bit RGBA.
 *	This method allows you to use a different bit-depth, or omit alpha.
 *
 *	@return A shiny new \c AIContextImageBridge instance.
 */
- (id)initWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha;
/*!	@brief Create and autorelease a context-image bridge.
 *
 *	Both the context and the image will be created with the given size in pixels.
 *
 *	@return A shiny new autoreleased \c AIContextImageBridge instance.
 */
+ (id)bridgeWithSize:(NSSize)size;
/*!	@brief Create and autorelease a context-image bridge with a specific pixel format.
 *
 *	@par
 *	Both the context and the image will be created with the given size in pixels.
 *
 *	@par
 *	By default, a context-image bridge is created using 32-bit RGBA.
 *	This method allows you to use a different bit-depth, or omit alpha.
 *
 *	@return A shiny new autoreleased \c AIContextImageBridge instance.
 */
+ (id)bridgeWithSize:(NSSize)size bitsPerComponent:(unsigned)bpc componentsPerPixel:(unsigned)cpp hasAlpha:(BOOL)hasAlpha;

#pragma mark Accessors

/*!	@brief Obtains the backing for the image.
 *	The backing contains the pure pixels of the image. The format is RGB, with alpha either premultiplied-last or none.
 *	@return The pointer to the pure pixels.
 */
- (unsigned char *)buffer;
/*!	@brief Obtains the \c CGContext.
 *
 *	You use this to draw to the image using Quartz.
 *
 *	@return The \c CGContext.
 */
- (CGContextRef)context;
/*!	@brief Obtains the \c NSImage.
 *
 *	You use this to draw to the image using Quartz.
 *
 *	@return The \c CGContext.
 */
- (NSImage *)image;

/*!	@brief Obtains the size of each component.
 *
 *	The size is measured in bits. It is typically 8.
 *
 *	@return The number of bits per component.
 */
- (unsigned)bitsPerComponent;
/*!	@brief Obtains the number of components per pixel.
 *
 *	<code>AIContextImageBridge</code>s are RGB, so this is either 3 or 4 (depending on the presence of alpha).
 *
 *	@return The number of components per pixel.
 */
- (unsigned)componentsPerPixel;
/*!	@brief Obtains the pixel dimensions of the image.
 *
 *	@return The size of the image, in pixels, as an \c NSSize.
 */
- (NSSize)size;

#pragma mark Icon Services

/*!	defgroup IconServices Icon Services interfaces.
 *	Gives you a nice Cocoa interface for drawing icons in the context.
 *	Comes in full and abstracted flavors.
 */
/*@{*/

/*Easy summary of methods (without types):
 *Wrapping GetIconRef:
 *  getIconWithType:
 *  getIconWithType:creator:
 *Wrapping other GetIconRef functions:
 *  [future expansion]
 *Wrapping PlotIconRefInContext:
 *	plotIcon:inRect:
 *	plotIcon:inRect:alignment:transform:labelNSColor:flags:
 *	plotIcon:inRect:alignment:transform:labelIndex:flags:
 *	plotIcon:inRect:alignment:transform:labelRGBColor:flags:
 *For more information, read the Icon Services documentation.
 *They all return the status code returned from the Carbon calls on which these
 *  methods are based.
 */

/*!	@brief Returns an Icon Services \c IconRef for a system icon.
 *	For example, <code>getIconWithType:kGenericURLIcon</code> returns the \@-on-a-spring icon for a URL in the Dock.
 *	@return An Icon Services \c IconRef. You are responsible for releasing it (using \c ReleaseIconRef) when you are done with it.
 */
- (IconRef)getIconWithType:(OSType)type;
/*!	@brief Returns an Icon Services \c IconRef for the icon for a given type/creator combination.
 *	For example, <code>getIconWithType:'APPL' creator:'hook'</code> returns the icon for iTunes.
 *	@return An Icon Services \c IconRef. You are responsible for releasing it (using \c ReleaseIconRef) when you are done with it.
 */
- (IconRef)getIconWithType:(OSType)type creator:(OSType)creator;

/*!	@brief Plots an icon from an Icon Services \c IconRef into the context.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds;
/*!	@brief Plots an icon from an Icon Services \c IconRef into the context with a specific alignment, transformation, label, and flags.
 *	@param icon The icon to plot.
 *	@param bounds The rectangle to plot the icon into.
 *	@param align An alignment type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param transform A transform type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param color An \c NSColor to use for the label.
 *	@param flags Plot flags for Icon Services. See <code>\<HIServices/Icons.h\></code>. Usually you will pass \c kPlotIconRefNormalFlags here.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
/*!	@brief Plots an icon from an Icon Services \c IconRef into the context with a specific alignment, transformation, label, and flags.
 *	@param icon The icon to plot.
 *	@param bounds The rectangle to plot the icon into.
 *	@param align An alignment type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param transform A transform type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param label A label index, 0 to 7.
 *	@param flags Plot flags for Icon Services. See <code>\<HIServices/Icons.h\></code>. Usually you will pass \c kPlotIconRefNormalFlags here.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
/*!	@brief Plots an icon from an Icon Services \c IconRef into the context with a specific alignment, transformation, label, and flags.
 *	@param icon The icon to plot.
 *	@param bounds The rectangle to plot the icon into.
 *	@param align An alignment type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param transform A transform type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param color A pointer to a QuickDraw \c RGBColor structure. RGBColors have three unsigned 16-bit components (no alpha), which range from 0 to 65535.
 *	@param flags Plot flags for Icon Services. See <code>\<HIServices/Icons.h\></code>. Usually you will pass \c kPlotIconRefNormalFlags here.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIcon:(IconRef)icon inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const struct RGBColor *)color flags:(PlotIconRefFlags)flags;

//Conveniences.
//These substitute plotIconWithType: and plotIconWithType:creator: for
//  plotIcon: above.
/*!	@brief Plots a system icon, specified by type code, into the context.
 *	@param type The file type of the icon to plot.
 *	@param bounds The rectangle to plot the icon into.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds;
/*!	@brief Plots a system icon, specified by type code, into the context, with a specific alignment, transformation, label, and flags.
 *	@param type The file type of the icon to plot.
 *	@param bounds The rectangle to plot the icon into.
 *	@param align An alignment type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param transform A transform type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param color An \c NSColor to use for the label.
 *	@param flags Plot flags for Icon Services. See <code>\<HIServices/Icons.h\></code>. Usually you will pass \c kPlotIconRefNormalFlags here.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
/*!	@brief Plots a system icon, specified by type code, into the context, with a specific alignment, transformation, label, and flags.
 *	@param type The file type of the icon to plot.
 *	@param bounds The rectangle to plot the icon into.
 *	@param align An alignment type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param transform A transform type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param label A label index, 0 to 7.
 *	@param flags Plot flags for Icon Services. See <code>\<HIServices/Icons.h\></code>. Usually you will pass \c kPlotIconRefNormalFlags here.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
/*!	@brief Plots a system icon, specified by type code, into the context, with a specific alignment, transformation, label, and flags.
 *	@param type The file type of the icon to plot.
 *	@param bounds The rectangle to plot the icon into.
 *	@param align An alignment type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param transform A transform type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param color A pointer to a QuickDraw \c RGBColor structure. RGBColors have three unsigned 16-bit components (no alpha), which range from 0 to 65535.
 *	@param flags Plot flags for Icon Services. See <code>\<HIServices/Icons.h\></code>. Usually you will pass \c kPlotIconRefNormalFlags here.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIconWithType:(OSType)type inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const struct RGBColor *)color flags:(PlotIconRefFlags)flags;

/*!	@brief Plots an icon, specified by type and creator codes, into the context.
 *	@param type The file type of the icon to plot.
 *	@param creator The creator type of the icon to plot.
 *	@param bounds The rectangle to plot the icon into.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds;
/*!	@brief Plots an icon, specified by type and creator codes, into the context, with a specific alignment, transformation, label, and flags.
 *	@param type The file type of the icon to plot.
 *	@param creator The creator type of the icon to plot.
 *	@param bounds The rectangle to plot the icon into.
 *	@param align An alignment type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param transform A transform type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param color An \c NSColor to use for the label.
 *	@param flags Plot flags for Icon Services. See <code>\<HIServices/Icons.h\></code>. Usually you will pass \c kPlotIconRefNormalFlags here.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelNSColor:(NSColor *)color flags:(PlotIconRefFlags)flags;
/*!	@brief Plots an icon, specified by type and creator codes, into the context, with a specific alignment, transformation, label, and flags.
 *	@param type The file type of the icon to plot.
 *	@param creator The creator type of the icon to plot.
 *	@param bounds The rectangle to plot the icon into.
 *	@param align An alignment type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param transform A transform type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param label A label index, 0 to 7.
 *	@param flags Plot flags for Icon Services. See <code>\<HIServices/Icons.h\></code>. Usually you will pass \c kPlotIconRefNormalFlags here.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelIndex:(SInt16)label flags:(PlotIconRefFlags)flags;
/*!	@brief Plots an icon, specified by type and creator codes, into the context, with a specific alignment, transformation, label, and flags.
 *	@param type The file type of the icon to plot.
 *	@param creator The creator type of the icon to plot.
 *	@param bounds The rectangle to plot the icon into.
 *	@param align An alignment type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param transform A transform type from Icon Services. See <code>\<HIServices/Icons.h\></code>.
 *	@param color A pointer to a QuickDraw \c RGBColor structure. RGBColors have three unsigned 16-bit components (no alpha), which range from 0 to 65535.
 *	@param flags Plot flags for Icon Services. See <code>\<HIServices/Icons.h\></code>. Usually you will pass \c kPlotIconRefNormalFlags here.
 *	@return The result code from Icon Services.
 */
- (OSStatus)plotIconWithType:(OSType)type creator:(OSType)creator inRect:(NSRect)bounds alignment:(IconAlignmentType)align transform:(IconTransformType)transform labelRGBColor:(const struct RGBColor *)color flags:(PlotIconRefFlags)flags;

/*}@*/

@end
