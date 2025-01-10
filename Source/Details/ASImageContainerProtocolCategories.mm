//
//  ASImageContainerProtocolCategories.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASImageContainerProtocolCategories.h"

@implementation NSImage (ASImageContainerProtocol)

- (NSImage *)asdk_image
{
    return self;
}

- (NSData *)asdk_animatedImageData
{
    return nil;
}

@end

@implementation NSData (ASImageContainerProtocol)

- (NSImage *)asdk_image
{
    return nil;
}

- (NSData *)asdk_animatedImageData
{
    return self;
}

@end
