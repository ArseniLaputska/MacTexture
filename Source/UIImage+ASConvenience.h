//
//  NSImage+ASConvenience.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AppKit/AppKit.h>
#import "ASBaseDefines.h"
#import "ASTraitCollection.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Dramatically faster version of +[NSImage imageNamed:]. Although it is believed that imageNamed:
 * has a cache and is fast, it actually performs expensive asset catalog lookups and is often a
 * performance bottleneck (verified on iOS 7 through iOS 10).
 *
 * Use [NSImage as_imageNamed:] anywhere in your app, even if you aren't using other parts of ASDK.
 * Although not the best choice for extremely large assets that are only used once, it is the ideal
 * choice for any assets used in tab bars, nav bars, buttons, table or collection cells, etc.
 */

@interface NSImage (ASDKFastImageNamed)

/**
 *  A version of imageNamed that caches results because loading an image is expensive.
 *  Calling with the same name value will usually return the same object.  A NSImage,
 *  after creation, is immutable and thread-safe so it's fine to share these objects across multiple threads.
 *
 *  @param imageName The name of the image to load
 *  @return The loaded image or nil
 */
+ (nullable NSImage *)as_imageNamed:(NSString *)imageName NS_RETURNS_RETAINED;

/**
 *  A version of imageNamed that caches results because loading an image is expensive.
 *  Calling with the same name value will usually return the same object.  A NSImage,
 *  after creation, is immutable and thread-safe so it's fine to share these objects across multiple threads.
 *
 *  @param imageName The name of the image to load
 *  @param traitCollection The traits associated with the intended environment for the image.
 *  @return The loaded image or nil
 */
+ (nullable NSImage *)as_imageNamed:(NSString *)imageName compatibleWithTraitCollection:(nullable ASTraitCollection *)traitCollection NS_RETURNS_RETAINED;

@end

/**
 * High-performance flat-colored, rounded-corner resizable images
 *
 * For "Baked-in Opaque" corners, set cornerColor equal to the color behind the rounded image object,
 * i.e. the background color.
 * For "Baked-in Alpha" corners, set cornerColor = [NSColor clearColor]
 *
 * See http://asyncdisplaykit.org/docs/corner-rounding.html for an explanation.
 */

@interface NSImage (ASDKResizableRoundedRects)

/**
 * This generates a flat-color, rounded-corner resizeable image
 *
 * @param cornerRadius The radius of the rounded-corner
 * @param cornerColor  The fill color of the corners (For Alpha corners use clearColor)
 * @param fillColor    The fill color of the rounded-corner image
 */
+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(nullable NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT ASDISPLAYNODE_DEPRECATED_MSG("Use as_resizableRoundedImageWithCornerRadius:cornerColor:fillColor:traitCollection: instead");

/**
 * This generates a flat-color, rounded-corner resizeable image
 *
 * @param cornerRadius The radius of the rounded-corner
 * @param cornerColor  The fill color of the corners (For Alpha corners use clearColor)
 * @param fillColor    The fill color of the rounded-corner image
 * @param traitCollection The trait collection.
 */
+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(nullable NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor
                                      traitCollection:(ASPrimitiveTraitCollection) traitCollection NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT;

/**
 * This generates a flat-color, rounded-corner resizeable image with a border
 *
 * @param cornerRadius The radius of the rounded-corner
 * @param cornerColor  The fill color of the corners (For Alpha corners use clearColor)
 * @param fillColor    The fill color of the rounded-corner image
 * @param borderColor  The border color. Set to nil for no border.
 * @param borderWidth  The border width. Dummy value if borderColor = nil.
 */
+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor
                                          borderColor:(nullable NSColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT ASDISPLAYNODE_DEPRECATED_MSG("Use as_resizableRoundedImageWithCornerRadius:cornerColor:fillColor:borderColor:borderWidth:traitCollection: instead");

/**
 * This generates a flat-color, rounded-corner resizeable image with a border
 *
 * @param cornerRadius The radius of the rounded-corner
 * @param cornerColor  The fill color of the corners (For Alpha corners use clearColor)
 * @param fillColor    The fill color of the rounded-corner image
 * @param borderColor  The border color. Set to nil for no border.
 * @param borderWidth  The border width. Dummy value if borderColor = nil.
 * @param traitCollection           The trait collection.
 */
+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor
                                          borderColor:(nullable NSColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth traitCollection:(ASPrimitiveTraitCollection) traitCollection NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT;

/**
 * This generates a flat-color, rounded-corner resizeable image with a border
 *
 * @param cornerRadius    The radius of the rounded-corner
 * @param cornerColor     The fill color of the corners (For Alpha corners use clearColor)
 * @param fillColor       The fill color of the rounded-corner image
 * @param borderColor     The border color. Set to nil for no border.
 * @param borderWidth     The border width. Dummy value if borderColor = nil.
 * @param roundedCorners  Select individual or multiple corners to round. Set to UIRectCornerAllCorners to round all 4 corners.
 * @param scale           The number of pixels per point. Provide 0.0 to use the screen scale.
 */
+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(nullable NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor
                                          borderColor:(nullable NSColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth
                                       roundedCorners:(CACornerMask)roundedCorners
                                                scale:(CGFloat)scale NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT ASDISPLAYNODE_DEPRECATED_MSG("Use as_resizableRoundedImageWithCornerRadius:cornerColor:fillColor:borderColor:borderWidth:roundedCorners:traitCollection: instead");
;

/**
 * This generates a flat-color, rounded-corner resizeable image with a border
 *
 * @param cornerRadius    The radius of the rounded-corner
 * @param cornerColor     The fill color of the corners (For Alpha corners use clearColor)
 * @param fillColor       The fill color of the rounded-corner image
 * @param borderColor     The border color. Set to nil for no border.
 * @param borderWidth     The border width. Dummy value if borderColor = nil.
 * @param roundedCorners  Select individual or multiple corners to round. Set to UIRectCornerAllCorners to round all 4 corners.
 * @param scale           The number of pixels per point. Provide 0.0 to use the screen scale.
 * @param traitCollection           The trait collection.
 */
+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(nullable NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor
                                          borderColor:(nullable NSColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth
                                       roundedCorners:(CACornerMask)roundedCorners
                                                scale:(CGFloat)scale
                                      traitCollection:(ASPrimitiveTraitCollection) traitCollection
NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT;

@end

NS_ASSUME_NONNULL_END
