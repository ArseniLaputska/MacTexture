//
//  ContenModeTypes.h
//  AsyncDisplayKit
//
//  Created by Arseni Laputska on 6.01.25.
//  Copyright © 2025 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ASDK_EXTERN FOUNDATION_EXTERN

typedef NS_ENUM(NSInteger, NSViewContentMode) {
    NSViewContentModeScaleToFill,
    NSViewContentModeScaleAspectFit,
    NSViewContentModeScaleAspectFill,
    NSViewContentModeCenter,
    NSViewContentModeTop,
    NSViewContentModeBottom,
    NSViewContentModeLeft,
    NSViewContentModeRight,
    NSViewContentModeTopLeft,
    NSViewContentModeTopRight,
    NSViewContentModeBottomLeft,
    NSViewContentModeBottomRight,
    NSViewContentModeRedraw
};
