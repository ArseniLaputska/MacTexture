//
//  ASDisplayNode+Convenience.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASDisplayNode+Convenience.h"

#import "ASDisplayNodeExtras.h"
#import "ASResponderChainEnumerator.h"

@implementation ASDisplayNode (Convenience)

- (__kindof NSViewController *)closestViewController
{
  ASDisplayNodeAssertMainThread();
  
  // Careful not to trigger node loading here.
  if (!self.nodeLoaded) {
    return nil;
  }

  // Get the closest view.
  NSView *view = ASFindClosestViewOfLayer(self.layer);
  // Travel up the responder chain to find a view controller.
  for (NSResponder *responder in [view asdk_responderChainEnumerator]) {
    NSViewController *vc = ASDynamicCast(responder, NSViewController);
    if (vc != nil) {
      return vc;
    }
  }
  return nil;
}

@end
