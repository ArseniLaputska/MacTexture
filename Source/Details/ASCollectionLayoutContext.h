//
//  ASCollectionLayoutContext.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AppKit/AppKit.h>
#import "ASBaseDefines.h"
#import "ASScrollDirection.h"

@class ASElementMap;

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASCollectionLayoutContext : NSObject

@property (nonatomic, readonly) CGSize viewportSize;
@property (nonatomic, readonly) CGPoint initialContentOffset;
@property (nonatomic, readonly) ASScrollDirection scrollableDirections;
@property (nonatomic, weak, readonly) ASElementMap *elements;
@property (nullable, nonatomic, readonly) id additionalInfo;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
