//
//  ASTraitCollection.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASAvailability.h"
#import "ASHashing.h"
#import "ASTraitCollection.h"
#import "ASObjectDescriptionHelpers.h"
#import "ASLayoutElement.h"

#pragma mark - ASPrimitiveTraitCollection

void ASTraitCollectionPropagateDown(id<ASLayoutElement> element, ASPrimitiveTraitCollection traitCollection) {
  if (element) {
    element.primitiveTraitCollection = traitCollection;
  }
  
  for (id<ASLayoutElement> subelement in element.sublayoutElements) {
    ASTraitCollectionPropagateDown(subelement, traitCollection);
  }
}

ASPrimitiveTraitCollection ASPrimitiveTraitCollectionMakeDefault() {
  ASPrimitiveTraitCollection tc = {};
  tc.displayScale = 0.0;
  tc.containerSize = CGSizeZero;
  tc.layoutDirection = NSUserInterfaceLayoutDirectionMacUnspecified;
  tc.userInterfaceStyle = NSUserInterfaceStyleMacUnspecified;
  tc.displayGamut = NSDisplayGamutSRGB;

#if TARGET_OS_IOS
  tc.userInterfaceLevel = UIUserInterfaceLevelUnspecified;
#endif

//  tc.accessibilityContrast = UIAccessibilityContrastUnspecified;
//  tc.legibilityWeight = UILegibilityWeightUnspecified;
  
  return tc;
}

//ASPrimitiveTraitCollection ASPrimitiveTraitCollectionFromUITraitCollection(UITraitCollection *traitCollection) {
//  ASPrimitiveTraitCollection environmentTraitCollection = ASPrimitiveTraitCollectionMakeDefault();
//  environmentTraitCollection.horizontalSizeClass = traitCollection.horizontalSizeClass;
//  environmentTraitCollection.verticalSizeClass = traitCollection.verticalSizeClass;
//  environmentTraitCollection.displayScale = traitCollection.displayScale;
//  environmentTraitCollection.userInterfaceIdiom = traitCollection.userInterfaceIdiom;
//  environmentTraitCollection.forceTouchCapability = traitCollection.forceTouchCapability;
//  environmentTraitCollection.displayGamut = traitCollection.displayGamut;
//  environmentTraitCollection.layoutDirection = traitCollection.layoutDirection;
//
//  ASDisplayNodeCAssertPermanent(traitCollection.preferredContentSizeCategory);
//  environmentTraitCollection.preferredContentSizeCategory = traitCollection.preferredContentSizeCategory;
//  environmentTraitCollection.userInterfaceStyle = traitCollection.userInterfaceStyle;
//
//#if TARGET_OS_IOS
//  environmentTraitCollection.userInterfaceLevel = traitCollection.userInterfaceLevel;
//#endif
//
//  environmentTraitCollection.accessibilityContrast = traitCollection.accessibilityContrast;
//  environmentTraitCollection.legibilityWeight = traitCollection.legibilityWeight;
//  return environmentTraitCollection;
//}

//ASDK_EXTERN UITraitCollection * ASPrimitiveTraitCollectionToUITraitCollection(ASPrimitiveTraitCollection traitCollection) {
//  NSMutableArray *collections = [[NSMutableArray alloc] initWithArray:@[
//    [UITraitCollection traitCollectionWithHorizontalSizeClass:traitCollection.horizontalSizeClass],
//    [UITraitCollection traitCollectionWithVerticalSizeClass:traitCollection.verticalSizeClass],
//    [UITraitCollection traitCollectionWithDisplayScale:traitCollection.displayScale],
//    [UITraitCollection traitCollectionWithUserInterfaceIdiom:traitCollection.userInterfaceIdiom],
//    [UITraitCollection traitCollectionWithForceTouchCapability:traitCollection.forceTouchCapability],
//  ]];
//  
//  [collections addObject:[UITraitCollection traitCollectionWithDisplayGamut:traitCollection.displayGamut]];
//  [collections addObject:[UITraitCollection traitCollectionWithLayoutDirection:traitCollection.layoutDirection]];
//  [collections addObject:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:traitCollection.preferredContentSizeCategory]];
//  [collections addObject:[UITraitCollection traitCollectionWithUserInterfaceStyle:traitCollection.userInterfaceStyle]];
//  
//  UITraitCollection *result = [UITraitCollection traitCollectionWithTraitsFromCollections:collections];
//  return result;
//}

BOOL ASPrimitiveTraitCollectionIsEqualToASPrimitiveTraitCollection(ASPrimitiveTraitCollection lhs, ASPrimitiveTraitCollection rhs) {
  return !memcmp(&lhs, &rhs, sizeof(ASPrimitiveTraitCollection));
}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
//ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUIUserInterfaceIdiom(UIUserInterfaceIdiom idiom) {
//  switch (idiom) {
//    case UIUserInterfaceIdiomTV:
//      return @"TV";
//    case UIUserInterfaceIdiomPad:
//      return @"Pad";
//    case UIUserInterfaceIdiomPhone:
//      return @"Phone";
//    case UIUserInterfaceIdiomCarPlay:
//      return @"CarPlay";
//    default:
//      return @"Unspecified";
//  }
//}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
//ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUIForceTouchCapability(UIForceTouchCapability capability) {
//  switch (capability) {
//    case UIForceTouchCapabilityAvailable:
//      return @"Available";
//    case UIForceTouchCapabilityUnavailable:
//      return @"Unavailable";
//    default:
//      return @"Unknown";
//  }
//}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
//ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUIUserInterfaceSizeClass(UIUserInterfaceSizeClass sizeClass) {
//  switch (sizeClass) {
//    case UIUserInterfaceSizeClassCompact:
//      return @"Compact";
//    case UIUserInterfaceSizeClassRegular:
//      return @"Regular";
//    default:
//      return @"Unspecified";
//  }
//}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUIDisplayGamut(NSDisplayGamut displayGamut) {
  switch (displayGamut) {
    case NSDisplayGamutSRGB:
      return @"sRGB";
    case NSDisplayGamutP3:
      return @"P3";
    default:
      return @"Unspecified";
  }
}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUITraitEnvironmentLayoutDirection(NSUserInterfaceLayoutDirectionMac layoutDirection) {
  switch (layoutDirection) {
    case NSUserInterfaceLayoutDirectionMacLeftToRight:
      return @"LeftToRight";
    case NSUserInterfaceLayoutDirectionMacRightToLeft:
      return @"RightToLeft";
    default:
      return @"Unspecified";
  }
}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUIUserInterfaceStyle(NSUserInterfaceStyleMac userInterfaceStyle) {
  switch (userInterfaceStyle) {
    case NSUserInterfaceStyleMacLight:
      return @"Light";
    case NSUserInterfaceStyleMacDark:
      return @"Dark";
    default:
      return @"Unspecified";
  }
}

#if TARGET_OS_IOS
// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
API_AVAILABLE(ios(13))
ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUITraitEnvironmentUserInterfaceLevel(UIUserInterfaceLevel userInterfaceLevel) {
  switch (userInterfaceLevel) {
    case UIUserInterfaceLevelBase:
      return @"Base";
    case UIUserInterfaceLevelElevated:
      return @"Elevated";
    default:
      return @"Unspecified";
  }
}
#endif

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
//ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUITraitEnvironmentAccessibilityContrast(UIAccessibilityContrast accessibilityContrast) {
//  switch (accessibilityContrast) {
//    case UIAccessibilityContrastNormal:
//      return @"Normal";
//    case UIAccessibilityContrastHigh:
//      return @"High";
//    default:
//      return @"Unspecified";
//  }
//}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
//API_AVAILABLE(ios(13))
//ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUITraitEnvironmentLegibilityWeight(UILegibilityWeight legibilityWeight) {
//  switch (legibilityWeight) {
//    case UILegibilityWeightRegular:
//      return @"Regular";
//    case UILegibilityWeightBold:
//      return @"Bold";
//    default:
//      return @"Unspecified";
//  }
//}



NSString *NSStringFromASPrimitiveTraitCollection(ASPrimitiveTraitCollection traits) {
  NSMutableArray<NSDictionary *> *props = [NSMutableArray array];
//  [props addObject:@{ @"verticalSizeClass": AS_NSStringFromUIUserInterfaceSizeClass(traits.verticalSizeClass) }];
//  [props addObject:@{ @"horizontalSizeClass": AS_NSStringFromUIUserInterfaceSizeClass(traits.horizontalSizeClass) }];
  [props addObject:@{ @"displayScale": [NSString stringWithFormat: @"%.0lf", (double)traits.displayScale] }];
//  [props addObject:@{ @"userInterfaceIdiom": AS_NSStringFromUIUserInterfaceIdiom(traits.userInterfaceIdiom) }];
//  [props addObject:@{ @"forceTouchCapability": AS_NSStringFromUIForceTouchCapability(traits.forceTouchCapability) }];
  [props addObject:@{ @"userInterfaceStyle": AS_NSStringFromUIUserInterfaceStyle(traits.userInterfaceStyle) }];
  [props addObject:@{ @"layoutDirection": AS_NSStringFromUITraitEnvironmentLayoutDirection(traits.layoutDirection) }];
//  if (traits.preferredContentSizeCategory != nil) {
//    [props addObject:@{ @"preferredContentSizeCategory": traits.preferredContentSizeCategory }];
//  }
  [props addObject:@{ @"displayGamut": AS_NSStringFromUIDisplayGamut(traits.displayGamut) }];

#if TARGET_OS_IOS
  [props addObject:@{ @"userInterfaceLevel": AS_NSStringFromUITraitEnvironmentUserInterfaceLevel(traits.userInterfaceLevel) }];
#endif

//  [props addObject:@{ @"accessibilityContrast": AS_NSStringFromUITraitEnvironmentAccessibilityContrast(traits.accessibilityContrast) }];
//  [props addObject:@{ @"legibilityWeight": AS_NSStringFromUITraitEnvironmentLegibilityWeight(traits.legibilityWeight) }];
  [props addObject:@{ @"containerSize": NSStringFromSize(traits.containerSize) }];
  return ASObjectDescriptionMakeWithoutObject(props);
}

#pragma mark - ASTraitCollection

@implementation ASTraitCollection {
  ASPrimitiveTraitCollection _prim;
}

+ (ASTraitCollection *)traitCollectionWithASPrimitiveTraitCollection:(ASPrimitiveTraitCollection)traits NS_RETURNS_RETAINED {
  ASTraitCollection *tc = [[ASTraitCollection alloc] init];
//  ASDisplayNodeCAssertPermanent(traits.preferredContentSizeCategory);
  tc->_prim = traits;
  return tc;
}

- (ASPrimitiveTraitCollection)primitiveTraitCollection {
  return _prim;
}
//- (UIUserInterfaceSizeClass)horizontalSizeClass
//{
//  return _prim.horizontalSizeClass;
//}
//-(UIUserInterfaceSizeClass)verticalSizeClass
//{
//  return _prim.verticalSizeClass;
//}
- (CGFloat)displayScale
{
  return _prim.displayScale;
}
- (NSDisplayGamut)displayGamut
{
  return _prim.displayGamut;
}
//- (UIForceTouchCapability)forceTouchCapability
//{
//  return _prim.forceTouchCapability;
//}
- (NSUserInterfaceLayoutDirectionMac)layoutDirection
{
  return _prim.layoutDirection;
}
- (CGSize)containerSize
{
  return _prim.containerSize;
}

- (NSUserInterfaceStyleMac)userInterfaceStyle
{
  return _prim.userInterfaceStyle;
}

//- (UIContentSizeCategory)preferredContentSizeCategory
//{
//  return _prim.preferredContentSizeCategory;
//}

#if TARGET_OS_IOS
- (UIUserInterfaceLevel)userInterfaceLevel
{
  return _prim.userInterfaceLevel;
}
#endif

//- (UIAccessibilityContrast)accessibilityContrast
//{
//  return _prim.accessibilityContrast;
//}

//- (UILegibilityWeight)legibilityWeight
//{
//  return _prim.legibilityWeight;
//}

- (NSUInteger)hash {
  return ASHashBytes(&_prim, sizeof(ASPrimitiveTraitCollection));
}

- (BOOL)isEqual:(id)object {
  if (!object || ![object isKindOfClass:ASTraitCollection.class]) {
    return NO;
  }
  return [self isEqualToTraitCollection:object];
}

- (BOOL)isEqualToTraitCollection:(ASTraitCollection *)traitCollection
{
  if (traitCollection == nil) {
    return NO;
  }

  if (self == traitCollection) {
    return YES;
  }
  return ASPrimitiveTraitCollectionIsEqualToASPrimitiveTraitCollection(_prim, traitCollection->_prim);
}

@end
