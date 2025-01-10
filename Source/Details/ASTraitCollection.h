//
//  ASTraitCollection.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//


#import <AppKit/AppKit.h>

#import "ASBaseDefines.h"

@class ASTraitCollection;
@protocol ASLayoutElement;
@protocol ASTraitEnvironment;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ASPrimitiveTraitCollection (macOS variant)

typedef NS_ENUM(NSInteger, NSUserInterfaceStyleMac) {
  NSUserInterfaceStyleMacUnspecified = 0,
  NSUserInterfaceStyleMacLight,
  NSUserInterfaceStyleMacDark
};

typedef NS_ENUM(NSInteger, NSUserInterfaceLayoutDirectionMac) {
  NSUserInterfaceLayoutDirectionMacUnspecified = 0,
  NSUserInterfaceLayoutDirectionMacLeftToRight,
  NSUserInterfaceLayoutDirectionMacRightToLeft
};

#pragma mark - ASPrimitiveTraitCollection

/**
 * @abstract This is an internal struct-representation of ASTraitCollection.
 *
 * @discussion This struct is for internal use only. Framework users should always use ASTraitCollection.
 *
 * If you use ASPrimitiveTraitCollection, please do make sure to initialize it with ASPrimitiveTraitCollectionMakeDefault()
 * or ASPrimitiveTraitCollectionFromUITraitCollection(UITraitCollection*).
 */
#pragma clang diagnostic push
#pragma clang diagnostic warning "-Wpadded"
typedef struct {
  CGFloat displayScale;   // backingScaleFactor, e.g. 1.0, 2.0, 3.0
  NSUserInterfaceLayoutDirectionMac layoutDirection; // LTR / RTL
  NSUserInterfaceStyleMac userInterfaceStyle; // Light / Dark
  NSDisplayGamut displayGamut;
  
  CGSize containerSize; // Можно оставить
} ASPrimitiveTraitCollection;
#pragma clang diagnostic pop

/**
 * Creates ASPrimitiveTraitCollection with default values.
 */
ASDK_EXTERN ASPrimitiveTraitCollection ASPrimitiveTraitCollectionMakeDefault(void);

/**
 * Creates a ASPrimitiveTraitCollection from a given UITraitCollection.
 */
//ASDK_EXTERN ASPrimitiveTraitCollection ASPrimitiveTraitCollectionFromUITraitCollection(UITraitCollection *traitCollection);

/**
 * Creates a UITraitCollection from a given ASPrimitiveTraitCollection.
 */
//ASDK_EXTERN UITraitCollection * ASPrimitiveTraitCollectionToUITraitCollection(ASPrimitiveTraitCollection traitCollection);


/**
 * Compares two ASPrimitiveTraitCollection to determine if they are the same.
 */
ASDK_EXTERN BOOL ASPrimitiveTraitCollectionIsEqualToASPrimitiveTraitCollection(ASPrimitiveTraitCollection lhs, ASPrimitiveTraitCollection rhs);

/**
 * Returns a string representation of a ASPrimitiveTraitCollection.
 */
ASDK_EXTERN NSString *NSStringFromASPrimitiveTraitCollection(ASPrimitiveTraitCollection traits);

/**
 * This function will walk the layout element hierarchy and updates the layout element trait collection for every
 * layout element within the hierarchy.
 */
ASDK_EXTERN void ASTraitCollectionPropagateDown(id<ASLayoutElement> element, ASPrimitiveTraitCollection traitCollection);

/**
 * Abstraction on top of UITraitCollection for propagation within AsyncDisplayKit-Layout
 */
@protocol ASTraitEnvironment <NSObject>

/**
 * @abstract Returns a struct-representation of the environment's ASEnvironmentDisplayTraits.
 *
 * @discussion This only exists as an internal convenience method. Users should access the trait collections through
 * the NSObject based asyncTraitCollection API
 */
- (ASPrimitiveTraitCollection)primitiveTraitCollection;

/**
 * @abstract Sets a trait collection on this environment state.
 *
 * @discussion This only exists as an internal convenience method. Users should not override trait collection using it.
 * Use [ASDKViewController overrideDisplayTraitsWithTraitCollection] block instead.
 */
- (void)setPrimitiveTraitCollection:(ASPrimitiveTraitCollection)traitCollection;

/**
 * @abstract Returns the thread-safe UITraitCollection equivalent.
 */
- (ASTraitCollection *)asyncTraitCollection;

@end

#define ASLayoutElementCollectionTableSetTraitCollection(lock) \
- (void)setPrimitiveTraitCollection:(ASPrimitiveTraitCollection)traitCollection\
{\
  AS::MutexLocker l(lock);\
\
  ASPrimitiveTraitCollection oldTraits = self.primitiveTraitCollection;\
  [super setPrimitiveTraitCollection:traitCollection];\
\
  /* Extra Trait Collection Handling */\
\
  /* If the node is not loaded  yet don't do anything as otherwise the access of the view will trigger a load */\
  if (! self.isNodeLoaded) { return; }\
\
  ASPrimitiveTraitCollection currentTraits = self.primitiveTraitCollection;\
  if (ASPrimitiveTraitCollectionIsEqualToASPrimitiveTraitCollection(currentTraits, oldTraits) == NO) {\
    [self.dataController environmentDidChange];\
  }\
}\

#pragma mark - ASTraitCollection

AS_SUBCLASSING_RESTRICTED
@interface ASTraitCollection : NSObject

@property (nonatomic, readonly) CGFloat displayScale;
@property (nonatomic, readonly) NSUserInterfaceLayoutDirectionMac layoutDirection;
@property (nonatomic, readonly) NSUserInterfaceStyleMac userInterfaceStyle;
@property (nonatomic, readonly) CGSize containerSize;

- (instancetype)initWithTraits:(ASPrimitiveTraitCollection)traits;

- (BOOL)isEqualToTraitCollection:(ASTraitCollection *)traitCollection;

@end

/**
 * These are internal helper methods. Should never be called by the framework users.
 */
@interface ASTraitCollection (PrimitiveTraits)

+ (ASTraitCollection *)traitCollectionWithASPrimitiveTraitCollection:(ASPrimitiveTraitCollection)traits NS_RETURNS_RETAINED;

- (ASPrimitiveTraitCollection)primitiveTraitCollection;

@end

NS_ASSUME_NONNULL_END
