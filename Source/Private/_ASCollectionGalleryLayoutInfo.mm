//
//  _ASCollectionGalleryLayoutInfo.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "_ASCollectionGalleryLayoutInfo.h"
#import "ASHashing.h"

@implementation _ASCollectionGalleryLayoutInfo

- (instancetype)initWithItemSize:(CGSize)itemSize
              minimumLineSpacing:(CGFloat)minimumLineSpacing
         minimumInteritemSpacing:(CGFloat)minimumInteritemSpacing
                    sectionInset:(NSEdgeInsets)sectionInset
{
  self = [super init];
  if (self) {
    _itemSize = itemSize;
    _minimumLineSpacing = minimumLineSpacing;
    _minimumInteritemSpacing = minimumInteritemSpacing;
    _sectionInset = sectionInset;
  }
  return self;
}

- (BOOL)isEqualToInfo:(_ASCollectionGalleryLayoutInfo *)info
{
  if (info == nil) {
    return NO;
  }

  return CGSizeEqualToSize(_itemSize, info.itemSize)
  && _minimumLineSpacing == info.minimumLineSpacing
  && _minimumInteritemSpacing == info.minimumInteritemSpacing
  && NSEdgeInsetsEqualToEdgeInsets(_sectionInset, info.sectionInset);
}

- (BOOL)isEqual:(id)other
{
  if (self == other) {
    return YES;
  }
  if (! [other isKindOfClass:[_ASCollectionGalleryLayoutInfo class]]) {
    return NO;
  }
  return [self isEqualToInfo:other];
}

- (NSUInteger)hash
{
  struct {
    CGSize itemSize;
    CGFloat minimumLineSpacing;
    CGFloat minimumInteritemSpacing;
    NSEdgeInsets sectionInset;
  } data = {
    _itemSize,
    _minimumLineSpacing,
    _minimumInteritemSpacing,
    _sectionInset,
  };
  return ASHashBytes(&data, sizeof(data));
}

static inline bool NSEdgeInsetsEqualToEdgeInsets(NSEdgeInsets insets1, NSEdgeInsets insets2)
{
  return (insets1.top == insets2.top &&
          insets1.left == insets2.left &&
          insets1.bottom == insets2.bottom &&
          insets1.right == insets2.right);
}

@end
