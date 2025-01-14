//
//  UIResponder+AsyncDisplayKit.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSResponder (AsyncDisplayKit)

/**
 * The nearest view controller above this responder, if one exists.
 *
 * This property must be accessed on the main thread.
 */
@property (nonatomic, nullable, readonly) __kindof NSViewController *asdk_associatedViewController;

@end

NS_ASSUME_NONNULL_END
