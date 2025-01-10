//
//  NSValue+CGAffineTransform.h
//  AsyncDisplayKit
//
//  Created by Arseni Laputska on 7.01.25.
//  Copyright © 2025 Pinterest. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h> // для CGAffineTransform

@interface NSValue (CGAffineTransformCompat)

/**
 * Аналог метода valueWithCGAffineTransform: из iOS (UIKit).
 */
+ (NSValue *)as_valueWithCGAffineTransform:(CGAffineTransform)transform;

/**
 * Аналог метода CGAffineTransformValue (iOS), возвращает CGAffineTransform.
 */
- (CGAffineTransform)as_CGAffineTransformValue;

@end
