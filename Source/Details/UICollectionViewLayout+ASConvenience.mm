//
//  UICollectionViewLayout+ASConvenience.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "UICollectionViewLayout+ASConvenience.h"

#import <AppKit/NSCollectionViewFlowLayout.h>

#import "ASCollectionViewFlowLayoutInspector.h"

@implementation NSCollectionViewLayout (ASLayoutInspectorProviding)

- (id<ASCollectionViewLayoutInspecting>)asdk_layoutInspector
{
  NSCollectionViewFlowLayout *flow = ASDynamicCast(self, NSCollectionViewFlowLayout);
  if (flow != nil) {
    return [[ASCollectionViewFlowLayoutInspector alloc] initWithFlowLayout:flow];
  } else {
    return [[ASCollectionViewLayoutInspector alloc] init];
  }
}

@end
