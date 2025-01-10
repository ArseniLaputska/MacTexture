//
//  UIResponder+AsyncDisplayKit.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "UIResponder+AsyncDisplayKit.h"

#import "ASAssert.h"
#import "ASResponderChainEnumerator.h"

@implementation NSResponder (AsyncDisplayKit)

- (__kindof NSViewController *)asdk_associatedViewController
{
  ASDisplayNodeAssertMainThread();
  
  for (NSResponder *responder in [self asdk_responderChainEnumerator]) {
    NSViewController *vc = ASDynamicCast(responder, NSViewController);
    if (vc) {
      return vc;
    }
  }
  return nil;
}

@end

