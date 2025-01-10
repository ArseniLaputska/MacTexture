//
//  NSImage.h
//  AsyncDisplayKit
//
//  Created by Arseni Laputska on 9.01.25.
//  Copyright © 2025 Pinterest. All rights reserved.
//


#import <AppKit/AppKit.h>

@interface NSImage (CGImageConversion)

/// Преобразует NSImage в CGImageRef.
/// @return CGImageRef или nil, если преобразование не удалось.
/// @discussion Возвращенный CGImageRef не управляется памятью (не требует освобождения).
- (nullable CGImageRef)cgImage;

@end