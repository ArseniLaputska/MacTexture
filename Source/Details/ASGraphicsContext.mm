//
//  ASGraphicsContext.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASGraphicsContext.h"
#import "ASAssert.h"
#import "ASConfigurationInternal.h"
#import "ASInternalHelpers.h"
#import "ASAvailability.h"

#import <AppKit/AppKit.h>
#import <objc/runtime.h>

// Define macro for performing work with NSAppearance
#define ASPerformBlockWithAppearance(work, appearance) \
    [[NSAppearance currentAppearance] performAsCurrentDrawingAppearance:^{ \
        work(); \
    }]

// Ничего не делает. В macOS всегда используем автоматический диапазон.
NS_INLINE void ASConfigureExtendedRange(NSGraphicsContext *format)
{
    // nop. В macOS всегда используем автоматический диапазон.
}

// Прототипы функций для совместимости
typedef BOOL (^asdisplaynode_iscancelled_block_t)(void);

// Функция для преобразования ASPrimitiveTraitCollection в NSAppearance или подобное
NSAppearance *ASPrimitiveTraitCollectionToNSAppearance(ASPrimitiveTraitCollection traitCollection) {
    // Реализуйте преобразование, если необходимо
    return [NSAppearance currentAppearance];
}

// Функция для создания дефолтного ASPrimitiveTraitCollection
//ASPrimitiveTraitCollection ASPrimitiveTraitCollectionMakeDefault() {
//    ASPrimitiveTraitCollection traitCollection;
//    // Инициализируйте по умолчанию
//    return traitCollection;
//}

// Предположим, что ASActivateExperimentalFeature и ASExperimentalDrawingGlobal определены где-то
BOOL ASActivateExperimentalFeature(int feature) {
    // Реализуйте проверку активации экспериментальной функции
    return NO;
}
#define ASExperimentalDrawingGlobal 0

NSImage *ASGraphicsCreateImageWithOptions(CGSize size, BOOL opaque, CGFloat scale, NSImage *sourceImage,
                                          asdisplaynode_iscancelled_block_t NS_NOESCAPE isCancelled,
                                          void (^NS_NOESCAPE work)())
{
    return ASGraphicsCreateImage(ASPrimitiveTraitCollectionMakeDefault(), size, opaque, scale, sourceImage, isCancelled, work);
}

NSImage *ASGraphicsCreateImage(ASPrimitiveTraitCollection traitCollection, CGSize size, BOOL opaque, CGFloat scale, NSImage * sourceImage, asdisplaynode_iscancelled_block_t NS_NOESCAPE isCancelled, void (NS_NOESCAPE ^work)()) {
    if (size.width <= 0 || size.height <= 0) {
        return nil;
    }
    
    if (ASActivateExperimentalFeature(ASExperimentalDrawingGlobal)) {
        // В macOS нет аналога UIGraphicsImageRendererFormat, поэтому используем NSImage и NSGraphicsContext
        NSImage *image = [[NSImage alloc] initWithSize:size];
        [image lockFocus];
        
        NSGraphicsContext *nsContext = [NSGraphicsContext currentContext];
        CGContextRef context = [nsContext CGContext];
        
        if (context && work) {
            ASPerformBlockWithAppearance(work, ASPrimitiveTraitCollectionToNSAppearance(traitCollection));
        }
        
        [image unlockFocus];
        
        if (isCancelled && isCancelled()) {
            return nil;
        }
        
        // Обработка режима шаблона
        if (sourceImage && [sourceImage isTemplate]) {
//            [sourceImage.tintColor set];
            [sourceImage drawInRect:NSMakeRect(0, 0, size.width, size.height)
                           fromRect:NSZeroRect
                          operation:NSCompositingOperationSourceOver
                           fraction:1.0];
        }
        
        return image;
    }

    // "Плохая" ОС или флаг эксперимента. Используем NSImage и NSGraphicsContext напрямую.
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    
    NSGraphicsContext *nsContext = [NSGraphicsContext currentContext];
    CGContextRef context = [nsContext CGContext];
    
    if (context && work) {
        ASPerformBlockWithAppearance(work, ASPrimitiveTraitCollectionToNSAppearance(traitCollection));
    }
    
    [image unlockFocus];
    
    if (isCancelled && isCancelled()) {
        return nil;
    }
    
    return image;
}

NSImage *ASGraphicsCreateImageWithTraitCollectionAndOptions(ASPrimitiveTraitCollection traitCollection, CGSize size, BOOL opaque, CGFloat scale, NSImage * sourceImage, void (NS_NOESCAPE ^work)()) {
    return ASGraphicsCreateImage(traitCollection, size, opaque, scale, sourceImage, nil, work);
}
