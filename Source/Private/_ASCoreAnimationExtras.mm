//
//  _ASCoreAnimationExtras.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "_ASCoreAnimationExtras.h"
#import "ASEqualityHelpers.h"


#pragma mark - Stretchable image support

void ASDisplayNodeSetupLayerContentsWithResizableImage(CALayer *layer, NSImage *image)
{
  ASDisplayNodeSetResizableContents(layer, image);
}

void ASDisplayNodeSetResizableContents(id<ASResizableContents> obj, NSImage *image)
{
  if (image) {
    // Convert NSImage -> CGImage
    CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
    if (cgImage == nil) {
      // Fallback: maybe create NSBitmapImageRep
      NSLog(@"[ASDisplayNode] Warning: Unable to get CGImage from NSImage!");
    }
    obj.contents = (__bridge id)cgImage;

    // contentsScale: In iOS, we had [image scale]. On macOS we might read from NSScreen or store in the image.
    // For the sake of example, let's say 1.0:
    obj.contentsScale = 1.0;
    obj.rasterizationScale = 1.0;

    CGSize imageSize = CGSizeMake(image.size.width, image.size.height);
    
    // Calculate contentsCenter from capInsets
    // This is just like iOS logic, but you supply capInsets manually.
    // We'll do a "stretch" approach:
    const CGFloat halfPixelFudge = 0.49f;
    const CGFloat otherPixelFudge = 0.02f;

    CGRect contentsCenter = CGRectMake(0, 0, 1, 1);
    NSEdgeInsets capInsets = [image capInsets];
    
    if (capInsets.left > 0 || capInsets.right > 0) {
      contentsCenter.origin.x = ((capInsets.left + halfPixelFudge) / imageSize.width);
      contentsCenter.size.width = (imageSize.width - (capInsets.left + capInsets.right + 1.f) + otherPixelFudge) / imageSize.width;
    }
    if (capInsets.top > 0 || capInsets.bottom > 0) {
      contentsCenter.origin.y = ((capInsets.top + halfPixelFudge) / imageSize.height);
      contentsCenter.size.height = (imageSize.height - (capInsets.top + capInsets.bottom + 1.f) + otherPixelFudge) / imageSize.height;
    }

    obj.contentsGravity = kCAGravityResize; // "stretch"
    obj.contentsCenter = contentsCenter;
  } else {
    obj.contents = nil;
  }
}

#pragma mark - ASContentMode

struct _UIContentModeStringLUTEntry {
  UIViewContentMode contentMode;
  NSString *const string;
};

static const _UIContentModeStringLUTEntry *UIContentModeCAGravityLUT(size_t *count)
{
  // Initialize this in a function (instead of at file level) to avoid
  // startup initialization time.
  static const _UIContentModeStringLUTEntry sUIContentModeCAGravityLUT[] = {
    {UIViewContentModeScaleToFill,     kCAGravityResize},
    {UIViewContentModeScaleAspectFit,  kCAGravityResizeAspect},
    {UIViewContentModeScaleAspectFill, kCAGravityResizeAspectFill},
    {UIViewContentModeCenter,          kCAGravityCenter},
    {UIViewContentModeTop,             kCAGravityBottom},
    {UIViewContentModeBottom,          kCAGravityTop},
    {UIViewContentModeLeft,            kCAGravityLeft},
    {UIViewContentModeRight,           kCAGravityRight},
    {UIViewContentModeTopLeft,         kCAGravityBottomLeft},
    {UIViewContentModeTopRight,        kCAGravityBottomRight},
    {UIViewContentModeBottomLeft,      kCAGravityTopLeft},
    {UIViewContentModeBottomRight,     kCAGravityTopRight},
    // Redraw -> maybe nil
  };
  *count = AS_ARRAY_SIZE(sUIContentModeCAGravityLUT);
  return sUIContentModeCAGravityLUT;
}

static const _UIContentModeStringLUTEntry *UIContentModeDescriptionLUT(size_t *count)
{
  // Initialize this in a function (instead of at file level) to avoid
  // startup initialization time.
  static const _UIContentModeStringLUTEntry sUIContentModeDescriptionLUT[] = {
    {UIViewContentModeScaleToFill,     @"scaleToFill"},
    {UIViewContentModeScaleAspectFit,  @"aspectFit"},
    {UIViewContentModeScaleAspectFill, @"aspectFill"},
    {UIViewContentModeRedraw,          @"redraw"},
    {UIViewContentModeCenter,          @"center"},
    {UIViewContentModeTop,             @"top"},
    {UIViewContentModeBottom,          @"bottom"},
    {UIViewContentModeLeft,            @"left"},
    {UIViewContentModeRight,           @"right"},
    {UIViewContentModeTopLeft,         @"topLeft"},
    {UIViewContentModeTopRight,        @"topRight"},
    {UIViewContentModeBottomLeft,      @"bottomLeft"},
    {UIViewContentModeBottomRight,     @"bottomRight"},
  };
  *count = AS_ARRAY_SIZE(sUIContentModeDescriptionLUT);
  return sUIContentModeDescriptionLUT;
}

NSString *ASDisplayNodeNSStringFromUIContentMode(UIViewContentMode contentMode)
{
  size_t lutSize;
  const _UIContentModeStringLUTEntry *lut = UIContentModeDescriptionLUT(&lutSize);
  for (size_t i = 0; i < lutSize; ++i) {
    if (lut[i].contentMode == contentMode) {
      return lut[i].string;
    }
  }
  return [NSString stringWithFormat:@"%d", (int)contentMode];
}

UIViewContentMode ASDisplayNodeUIContentModeFromNSString(NSString *string)
{
  size_t lutSize;
  const _UIContentModeStringLUTEntry *lut = UIContentModeDescriptionLUT(&lutSize);
  for (size_t i = 0; i < lutSize; ++i) {
    if (ASObjectIsEqual(lut[i].string, string)) {
      return lut[i].contentMode;
    }
  }
  return UIViewContentModeScaleToFill;
}

NSString *const ASDisplayNodeCAContentsGravityFromUIContentMode(UIViewContentMode contentMode)
{
  size_t lutSize;
  const _UIContentModeStringLUTEntry *lut = UIContentModeCAGravityLUT(&lutSize);
  for (size_t i = 0; i < lutSize; ++i) {
    if (lut[i].contentMode == contentMode) {
      return lut[i].string;
    }
  }
  ASDisplayNodeCAssert(contentMode == UIViewContentModeRedraw, @"Encountered an unknown contentMode %ld. Is this a new version of iOS?", (long)contentMode);
  // Redraw is ok to return nil.
  return nil;
}

#define ContentModeCacheSize 10
UIViewContentMode ASDisplayNodeUIContentModeFromCAContentsGravity(NSString *const contentsGravity)
{
  static int currentCacheIndex = 0;
  static NSMutableArray *cachedStrings = [NSMutableArray arrayWithCapacity:ContentModeCacheSize];
  static UIViewContentMode cachedModes[ContentModeCacheSize] = {};
  
  NSInteger foundCacheIndex = [cachedStrings indexOfObjectIdenticalTo:contentsGravity];
  if (foundCacheIndex != NSNotFound && foundCacheIndex < ContentModeCacheSize) {
    return cachedModes[foundCacheIndex];
  }
  
    size_t lutSize;
    const _UIContentModeStringLUTEntry *lut = UIContentModeCAGravityLUT(&lutSize);
    for (size_t i = 0; i < lutSize; ++i) {
    if (ASObjectIsEqual(lut[i].string, contentsGravity)) {
      UIViewContentMode foundContentMode = lut[i].contentMode;
      
      if (currentCacheIndex < ContentModeCacheSize) {
        // Cache the input value.  This is almost always a different pointer than in our LUT and will frequently
        // be the same value for an overwhelming majority of inputs.
        [cachedStrings addObject:contentsGravity];
        cachedModes[currentCacheIndex] = foundContentMode;
        currentCacheIndex++;
      }
      
      return foundContentMode;
    }
  }

  ASDisplayNodeCAssert(contentsGravity, @"Encountered an unknown contentsGravity \"%@\". Is this a new version of iOS?", contentsGravity);
  ASDisplayNodeCAssert(!contentsGravity, @"You passed nil to ASDisplayNodeUIContentModeFromCAContentsGravity. We're falling back to resize, but this is probably a bug.");
  // If asserts disabled, fall back to this
  return UIViewContentModeScaleToFill;
}

BOOL ASDisplayNodeLayerHasAnimations(CALayer *layer)
{
  return (layer.animationKeys.count != 0);
}
