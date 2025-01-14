//
//  ASTextKitShadower.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTextKitShadower.h"

#if AS_ENABLE_TEXTNODE

#import <tgmath.h>

static inline CGSize _insetSize(CGSize size, NSEdgeInsets insets)
{
  size.width -= (insets.left + insets.right);
  size.height -= (insets.top + insets.bottom);
  return size;
}

static inline NSEdgeInsets _invertInsets(NSEdgeInsets insets)
{
  return {
    .top = -insets.top,
    .left = -insets.left,
    .bottom = -insets.bottom,
    .right = -insets.right
  };
}

@implementation ASTextKitShadower {
  NSEdgeInsets _calculatedShadowPadding;
}

+ (ASTextKitShadower *)shadowerWithShadowOffset:(CGSize)shadowOffset
                                    shadowColor:(NSColor *)shadowColor
                                  shadowOpacity:(CGFloat)shadowOpacity
                                   shadowRadius:(CGFloat)shadowRadius
{
  /**
   * For all cases where no shadow is drawn, we share this singleton shadower to save resources.
   */
  static dispatch_once_t onceToken;
  static ASTextKitShadower *sharedNonShadower;
  dispatch_once(&onceToken, ^{
    sharedNonShadower = [[ASTextKitShadower alloc] initWithShadowOffset:CGSizeZero shadowColor:nil shadowOpacity:0 shadowRadius:0];
  });

  BOOL hasShadow = shadowOpacity > 0 && (shadowRadius > 0 || CGSizeEqualToSize(shadowOffset, CGSizeZero) == NO) && CGColorGetAlpha(shadowColor.CGColor) > 0;
  if (hasShadow == NO) {
    return sharedNonShadower;
  } else {
    return [[ASTextKitShadower alloc] initWithShadowOffset:shadowOffset shadowColor:shadowColor shadowOpacity:shadowOpacity shadowRadius:shadowRadius];
  }
}

- (instancetype)initWithShadowOffset:(CGSize)shadowOffset
                         shadowColor:(NSColor *)shadowColor
                       shadowOpacity:(CGFloat)shadowOpacity
                        shadowRadius:(CGFloat)shadowRadius
{
  if (self = [super init]) {
    _shadowOffset = shadowOffset;
    _shadowColor = shadowColor;
    _shadowOpacity = shadowOpacity;
    _shadowRadius = shadowRadius;
    _calculatedShadowPadding = NSEdgeInsetsMake(-INFINITY, -INFINITY, INFINITY, INFINITY);
  }
  return self;
}

/*
 * This method is duplicated here because it gets called frequently, and we were
 * wasting valuable time constructing a state object to ask it.
 */
- (BOOL)_shouldDrawShadow
{
  return _shadowOpacity != 0.0 && (_shadowRadius != 0 || !CGSizeEqualToSize(_shadowOffset, CGSizeZero)) && CGColorGetAlpha(_shadowColor.CGColor) > 0;
}

- (void)setShadowInContext:(CGContextRef)context
{
  if ([self _shouldDrawShadow]) {
    CGColorRef textShadowColor = CGColorRetain(_shadowColor.CGColor);
    CGSize textShadowOffset = _shadowOffset;
    CGFloat textShadowOpacity = _shadowOpacity;
    CGFloat textShadowRadius = _shadowRadius;

    if (textShadowOpacity != 1.0) {
      CGFloat inherentAlpha = CGColorGetAlpha(textShadowColor);

      CGColorRef oldTextShadowColor = textShadowColor;
      textShadowColor = CGColorCreateCopyWithAlpha(textShadowColor, inherentAlpha * textShadowOpacity);
      CGColorRelease(oldTextShadowColor);
    }

    CGContextSetShadowWithColor(context, textShadowOffset, textShadowRadius, textShadowColor);

    CGColorRelease(textShadowColor);
  }
}


- (NSEdgeInsets)shadowPadding
{
  if (_calculatedShadowPadding.top == -INFINITY) {
    if (![self _shouldDrawShadow]) {
      return NSEdgeInsetsZero;
    }

    NSEdgeInsets shadowPadding = NSEdgeInsetsZero;

    // min values are expected to be negative for most typical shadowOffset and
    // blurRadius settings:
    shadowPadding.top = std::fmin(0.0f, _shadowOffset.height - _shadowRadius);
    shadowPadding.left = std::fmin(0.0f, _shadowOffset.width - _shadowRadius);

    shadowPadding.bottom = std::fmin(0.0f, -_shadowOffset.height - _shadowRadius);
    shadowPadding.right = std::fmin(0.0f, -_shadowOffset.width - _shadowRadius);

    _calculatedShadowPadding = shadowPadding;
  }

  return _calculatedShadowPadding;
}

- (CGSize)insetSizeWithConstrainedSize:(CGSize)constrainedSize
{
  return _insetSize(constrainedSize, _invertInsets([self shadowPadding]));
}

- (CGRect)insetRectWithConstrainedRect:(CGRect)constrainedRect
{
  return NSEdgeInsetsInsetRect(constrainedRect, _invertInsets([self shadowPadding]));
}

- (CGSize)outsetSizeWithInsetSize:(CGSize)insetSize
{
  return _insetSize(insetSize, [self shadowPadding]);
}

- (CGRect)outsetRectWithInsetRect:(CGRect)insetRect
{
  return NSEdgeInsetsInsetRect(insetRect, [self shadowPadding]);
}

- (CGRect)offsetRectWithInternalRect:(CGRect)internalRect
{
  return (CGRect){
    .origin = [self offsetPointWithInternalPoint:internalRect.origin],
    .size = internalRect.size
  };
}

- (CGPoint)offsetPointWithInternalPoint:(CGPoint)internalPoint
{
  NSEdgeInsets shadowPadding = [self shadowPadding];
  return (CGPoint){
    internalPoint.x + shadowPadding.left,
    internalPoint.y + shadowPadding.top
  };
}

- (CGPoint)offsetPointWithExternalPoint:(CGPoint)externalPoint
{
  NSEdgeInsets shadowPadding = [self shadowPadding];
  return (CGPoint){
    externalPoint.x - shadowPadding.left,
    externalPoint.y - shadowPadding.top
  };
}

static inline CGRect NSEdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets) {
    rect.origin.x += insets.left;
    rect.origin.y += insets.top;
    rect.size.width -= (insets.left + insets.right);
    rect.size.height -= (insets.top + insets.bottom);
    return rect;
}

@end

#endif
