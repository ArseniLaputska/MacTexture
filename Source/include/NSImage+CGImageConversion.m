//
//  NSImage.m
//  AsyncDisplayKit
//
//  Created by Arseni Laputska on 9.01.25.
//  Copyright © 2025 Pinterest. All rights reserved.
//


#import "NSImage+CGImageConversion.h"

@implementation NSImage (CGImageConversion)

- (CGImageRef)cgImage {
    CGImageRef cgImage = NULL;
    NSBitmapImageRep *bitmapRep = nil;
    
    // Перебираем все представления изображения
    for (NSImageRep *rep in [self representations]) {
        if ([rep isKindOfClass:[NSBitmapImageRep class]]) {
            bitmapRep = (NSBitmapImageRep *)rep;
            cgImage = [bitmapRep CGImage];
            if (cgImage) {
                return cgImage; // Возвращаем сразу, если получилось
            }
        }
    }
    
    // Если не удалось найти NSBitmapImageRep с CGImage, создаем новое представление
    NSSize size = [self size];
    if (size.width <= 0 || size.height <= 0) {
        return NULL;
    }
    
    // Создаем новое bitmap представление
    bitmapRep = [[NSBitmapImageRep alloc]
                initWithBitmapDataPlanes:NULL
                pixelsWide:size.width
                pixelsHigh:size.height
                bitsPerSample:8
                samplesPerPixel:4
                hasAlpha:YES
                isPlanar:NO
                colorSpaceName:NSCalibratedRGBColorSpace
                bytesPerRow:0
                bitsPerPixel:0];
    
    if (!bitmapRep) {
        return NULL;
    }
    
    // Создаем графический контекст с этим представлением
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapRep];
    if (!context) {
        return NULL;
    }
    
    // Сохраняем текущий графический контекст
    [NSGraphicsContext saveGraphicsState];
    
    // Устанавливаем новый контекст как текущий
    [NSGraphicsContext setCurrentContext:context];
    
    // Отрисовываем NSImage в контексте
    [self drawInRect:NSMakeRect(0, 0, size.width, size.height)
            fromRect:NSZeroRect
           operation:NSCompositingOperationCopy
            fraction:1.0
      respectFlipped:YES
               hints:nil];
    
    // Восстанавливаем предыдущий графический контекст
    [NSGraphicsContext restoreGraphicsState];
    
    // Получаем CGImage из bitmapRep
    cgImage = [bitmapRep CGImage];
    
    return cgImage;
}

@end
