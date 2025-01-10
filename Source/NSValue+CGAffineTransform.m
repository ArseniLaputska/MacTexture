//
//  NSValue+CGAffineTransform.m
//  AsyncDisplayKit
//
//  Created by Arseni Laputska on 7.01.25.
//  Copyright © 2025 Pinterest. All rights reserved.
//


#import "NSValue+CGAffineTransform.h"

@implementation NSValue (CGAffineTransformCompat)

+ (NSValue *)as_valueWithCGAffineTransform:(CGAffineTransform)transform
{
    // Сохраняем структуру как bytes:
    return [NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)];
}

- (CGAffineTransform)as_CGAffineTransformValue
{
    CGAffineTransform transform;
    [self getValue:&transform];
    return transform;
}

@end
