//
//  NSImage+Resizable.h
//  AsyncDisplayKit
//
//  Created by Arseni Laputska on 9.01.25.
//  Copyright © 2025 Pinterest. All rights reserved.
//


#import <AppKit/AppKit.h>

@interface NSImage (Resizable)

- (NSImage *)resizableImageWithCapInsets:(NSEdgeInsets)capInsets
                           resizingMode:(NSImageResizingMode)resizingMode;

@end
