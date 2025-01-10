//
//  NSImage+ASConvenience.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "UIImage+ASConvenience.h"
#import "ASGraphicsContext.h"

#pragma mark - ASDKFastImageNamed

@implementation NSImage (ASDKFastImageNamed)

NSImage *cachedImageNamed(NSString *imageName, ASTraitCollection *traitCollection) NS_RETURNS_RETAINED
{
  static NSCache *imageCache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Because NSCache responds to memory warnings, we do not need an explicit limit.
    // all of these objects contain compressed image data and are relatively small
    // compared to the backing stores of text and image views.
    imageCache = [[NSCache alloc] init];
  });

  NSImage *image = nil;
  if ([imageName length] > 0) {
    NSString *imageKey = imageName;
    if (traitCollection) {
      char imageKeyBuffer[256];
//      snprintf(imageKeyBuffer, sizeof(imageKeyBuffer), "%s|%ld|%ld|%ld", imageName.UTF8String, (long)traitCollection.horizontalSizeClass, (long)traitCollection.verticalSizeClass, (long)traitCollection.userInterfaceStyle);
      imageKey = [NSString stringWithUTF8String:imageKeyBuffer];
    }

    image = [imageCache objectForKey:imageKey];
    if (!image) {
      image =  [NSImage imageNamed:imageName];
      if (image) {
        [imageCache setObject:image forKey:imageKey];
      }
    }
  }
  return image;
}

+ (NSImage *)as_imageNamed:(NSString *)imageName NS_RETURNS_RETAINED
{
  return cachedImageNamed(imageName, nil);
}

+ (NSImage *)as_imageNamed:(NSString *)imageName compatibleWithTraitCollection:(ASTraitCollection *)traitCollection NS_RETURNS_RETAINED
{
  return cachedImageNamed(imageName, traitCollection);
}

@end

#pragma mark - ASDKResizableRoundedRects

@implementation NSImage (ASDKResizableRoundedRects)

+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor NS_RETURNS_RETAINED
{
  return [self as_resizableRoundedImageWithCornerRadius:cornerRadius
                                            cornerColor:cornerColor
                                              fillColor:fillColor
                                            borderColor:nil
                                            borderWidth:1.0
                                         roundedCorners:kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner
                                                  scale:0.0];
}

+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor
                                      traitCollection:(ASPrimitiveTraitCollection) traitCollection NS_RETURNS_RETAINED
{
  return [self as_resizableRoundedImageWithCornerRadius:cornerRadius
                                            cornerColor:cornerColor
                                              fillColor:fillColor
                                            borderColor:nil
                                            borderWidth:1.0
                                         roundedCorners:kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner
                                                  scale:0.0
                                        traitCollection:traitCollection];
}

+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor
                                          borderColor:(NSColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth
                                      traitCollection:(ASPrimitiveTraitCollection) traitCollection NS_RETURNS_RETAINED {
  return [self as_resizableRoundedImageWithCornerRadius:cornerRadius
                                            cornerColor:cornerColor
                                              fillColor:fillColor
                                            borderColor:borderColor
                                            borderWidth:borderWidth
                                         roundedCorners:kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner
                                                  scale:0.0
                                        traitCollection:traitCollection];
}


+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor
                                          borderColor:(NSColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth NS_RETURNS_RETAINED
{
  return [self as_resizableRoundedImageWithCornerRadius:cornerRadius
                                            cornerColor:cornerColor
                                              fillColor:fillColor
                                            borderColor:borderColor
                                            borderWidth:borderWidth
                                         roundedCorners:kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner
                                                  scale:0.0];
}

+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor
                                          borderColor:(NSColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth
                                       roundedCorners:(CACornerMask)roundedCorners
                                                scale:(CGFloat)scale NS_RETURNS_RETAINED {

  return [self as_resizableRoundedImageWithCornerRadius:cornerRadius
                                            cornerColor:cornerColor
                                              fillColor:fillColor
                                            borderColor:borderColor
                                            borderWidth:borderWidth
                                         roundedCorners:roundedCorners
                                                  scale:scale
                                        traitCollection:ASPrimitiveTraitCollectionMakeDefault()];
}


+ (NSImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(NSColor *)cornerColor
                                            fillColor:(NSColor *)fillColor
                                          borderColor:(NSColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth
                                       roundedCorners:(CACornerMask)roundedCorners
                                                scale:(CGFloat)scale
                                      traitCollection:(ASPrimitiveTraitCollection) traitCollection NS_RETURNS_RETAINED
{
  static NSCache *__pathCache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    __pathCache = [[NSCache alloc] init];
    // UIBezierPath objects are fairly small and these are equally sized. 20 should be plenty for many different parameters.
    __pathCache.countLimit = 20;
  });
  
  // Treat clear background color as no background color
  if ([cornerColor isEqual:[NSColor clearColor]]) {
    cornerColor = nil;
  }
  
  CGFloat dimension = (cornerRadius * 2) + 1;
  CGRect bounds = CGRectMake(0, 0, dimension, dimension);
  
  typedef struct {
    CACornerMask corners;
    CGFloat radius;
  } PathKey;
  PathKey key = { roundedCorners, cornerRadius };
  NSValue *pathKeyObject = [[NSValue alloc] initWithBytes:&key objCType:@encode(PathKey)];

  CGSize cornerRadii = CGSizeMake(cornerRadius, cornerRadius);
  NSBezierPath *path = [__pathCache objectForKey:pathKeyObject];
  if (path == nil) {
    path = [NSBezierPath bezierPathWithOvalInRect:bounds];
    [__pathCache setObject:path forKey:pathKeyObject];
  }
  
  // We should probably check if the background color has any alpha component but that
  // might be expensive due to needing to check mulitple color spaces.
  NSImage *result = ASGraphicsCreateImage(traitCollection, bounds.size, cornerColor != nil, scale, nil, nil, ^{
    BOOL contextIsClean = YES;
    if (cornerColor) {
      contextIsClean = NO;
      [cornerColor setFill];
      // Copy "blend" mode is extra fast because it disregards any value currently in the buffer and overrides directly.
//      UIRectFillUsingBlendMode(bounds, kCGBlendModeCopy);
    }

    BOOL canUseCopy = contextIsClean || (CGColorGetAlpha(fillColor.CGColor) == 1);
    [fillColor setFill];
//    [path fillWithBlendMode:(canUseCopy ? kCGBlendModeCopy : kCGBlendModeNormal) alpha:1];

    if (borderColor) {
      [borderColor setStroke];

      // Inset border fully inside filled path (not halfway on each side of path)
      CGRect strokeRect = CGRectInset(bounds, borderWidth / 2.0, borderWidth / 2.0);

      // It is rarer to have a stroke path, and our cache key only handles rounded rects for the exact-stretchable
      // size calculated by cornerRadius, so we won't bother caching this path.  Profiling validates this decision.
//      NSBezierPath *strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect
//                                                       byRoundingCorners:roundedCorners
//                                                             cornerRadii:cornerRadii];
//      [strokePath setLineWidth:borderWidth];
      BOOL canUseCopy = (CGColorGetAlpha(borderColor.CGColor) == 1);
//      [strokePath strokeWithBlendMode:(canUseCopy ? kCGBlendModeCopy : kCGBlendModeNormal) alpha:1];
    }
  });
  
  NSEdgeInsets capInsets = NSEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius);
//  result = [result resizableImageWithCapInsets:capInsets resizingMode:NSImageResizingModeStretch];
  
  return result;
}

@end
