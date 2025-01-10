//
//  NSImage+Resizable.m
//  AsyncDisplayKit
//
//  Created by Arseni Laputska on 9.01.25.
//  Copyright © 2025 Pinterest. All rights reserved.
//


#import "NSImage+Resizable.h"

@implementation NSImage (Resizable)

- (NSImage *)resizableImageWithCapInsets:(NSEdgeInsets)capInsets
                           resizingMode:(NSImageResizingMode)resizingMode
{
    // Создаем новое изображение с тем же размером
    NSImage *resizableImage = [[NSImage alloc] initWithSize:self.size];
    
    [resizableImage lockFocus];
    
    // Размер оригинального изображения
    CGSize originalSize = self.size;
    
    // Определяем отступы
    CGFloat top = capInsets.top;
    CGFloat left = capInsets.left;
    CGFloat bottom = capInsets.bottom;
    CGFloat right = capInsets.right;
    
    // Проверяем корректность отступов
    if (top + bottom > originalSize.height || left + right > originalSize.width) {
        NSLog(@"Ошибка: Отступы превышают размер изображения.");
        [resizableImage unlockFocus];
        return self;
    }
    
    // Определяем области изображения
    CGRect topLeftRect = NSMakeRect(0, originalSize.height - top, left, top);
    CGRect topRightRect = NSMakeRect(originalSize.width - right, originalSize.height - top, right, top);
    CGRect bottomLeftRect = NSMakeRect(0, 0, left, bottom);
    CGRect bottomRightRect = NSMakeRect(originalSize.width - right, 0, right, bottom);
    
    CGRect topEdgeRect = NSMakeRect(left, originalSize.height - top, originalSize.width - left - right, top);
    CGRect bottomEdgeRect = NSMakeRect(left, bottom, originalSize.width - left - right, bottom);
    CGRect leftEdgeRect = NSMakeRect(0, bottom, left, originalSize.height - top - bottom);
    CGRect rightEdgeRect = NSMakeRect(originalSize.width - right, bottom, right, originalSize.height - top - bottom);
    
    CGRect centerRect = NSMakeRect(left, bottom, originalSize.width - left - right, originalSize.height - top - bottom);
    
    // Размер конечного изображения
    CGSize destinationSize = self.size; // Здесь можно задать другой размер при необходимости
    
    // Определяем, нужно ли растягивать или плитить
    BOOL shouldStretch = (resizingMode == NSImageResizingModeStretch);
    
    // Рисуем углы
    [self drawInRect:topLeftRect fromRect:topLeftRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [self drawInRect:topRightRect fromRect:topRightRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [self drawInRect:bottomLeftRect fromRect:bottomLeftRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [self drawInRect:bottomRightRect fromRect:bottomRightRect operation:NSCompositingOperationSourceOver fraction:1.0];
    
    // Рисуем края
    if (shouldStretch) {
        // Растягиваем края
        [self drawInRect:topEdgeRect fromRect:topEdgeRect operation:NSCompositingOperationSourceOver fraction:1.0];
        [self drawInRect:bottomEdgeRect fromRect:bottomEdgeRect operation:NSCompositingOperationSourceOver fraction:1.0];
        [self drawInRect:leftEdgeRect fromRect:leftEdgeRect operation:NSCompositingOperationSourceOver fraction:1.0];
        [self drawInRect:rightEdgeRect fromRect:rightEdgeRect operation:NSCompositingOperationSourceOver fraction:1.0];
        
        // Растягиваем центр
        [self drawInRect:centerRect fromRect:centerRect operation:NSCompositingOperationSourceOver fraction:1.0];
    }
    else {
        // Плитим края
        NSImage *edgeImage = [self copy];
        [edgeImage setSize:NSMakeSize(topEdgeRect.size.width, topEdgeRect.size.height)];
        [edgeImage drawInRect:topEdgeRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        
        [edgeImage setSize:NSMakeSize(bottomEdgeRect.size.width, bottomEdgeRect.size.height)];
        [edgeImage drawInRect:bottomEdgeRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        
        [edgeImage setSize:NSMakeSize(leftEdgeRect.size.width, leftEdgeRect.size.height)];
        [edgeImage drawInRect:leftEdgeRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        
        [edgeImage setSize:NSMakeSize(rightEdgeRect.size.width, rightEdgeRect.size.height)];
        [edgeImage drawInRect:rightEdgeRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        
        // Плитим центр
        NSImage *centerImage = [self copy];
        [centerImage setSize:centerRect.size];
        [centerImage drawInRect:centerRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    }
    
    [resizableImage unlockFocus];
    
    return resizableImage;
}

@end
