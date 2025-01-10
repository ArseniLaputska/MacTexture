//
//  ASResponderChainEnumerator.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AppKit/NSResponder.h>
#import "ASBaseDefines.h"

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASResponderChainEnumerator : NSEnumerator

- (instancetype)initWithResponder:(NSResponder *)responder;

@end

@interface NSResponder (ASResponderChainEnumerator)

- (ASResponderChainEnumerator *)asdk_responderChainEnumerator;

@end


NS_ASSUME_NONNULL_END
