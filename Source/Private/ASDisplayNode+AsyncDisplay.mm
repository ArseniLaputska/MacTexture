//
//  ASDisplayNode+AsyncDisplay.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "_ASCoreAnimationExtras.h"
#import "_ASAsyncTransaction.h"
#import "_ASDisplayLayer.h"
#import "ASDisplayNodeInternal.h"
#import "ASGraphicsContext.h"
#import "ASInternalHelpers.h"
#import "ASSignpost.h"
#import "NSImage+CGImageConversion.h"
#import <CoreGraphics/CoreGraphics.h>

using AS::MutexLocker;

@interface ASDisplayNode () <_ASDisplayLayerDelegate>
@end

@implementation ASDisplayNode (AsyncDisplay)

#if ASDISPLAYNODE_DELAY_DISPLAY
  #define ASDN_DELAY_FOR_DISPLAY() usleep( (long)(0.1 * USEC_PER_SEC) )
#else
  #define ASDN_DELAY_FOR_DISPLAY()
#endif

#define CHECK_CANCELLED_AND_RETURN_NIL(expr)                      if (isCancelledBlock()) { \
                                                                    expr; \
                                                                    return nil; \
                                                                  } \

- (NSObject *)drawParameters
{
  __instanceLock__.lock();
  BOOL implementsDrawParameters = _flags.implementsDrawParameters;
  __instanceLock__.unlock();

  if (implementsDrawParameters) {
    return [self drawParametersForAsyncLayer:self.asyncLayer];
  } else {
    return nil;
  }
}

- (void)_recursivelyRasterizeSelfAndSublayersWithIsCancelledBlock:(asdisplaynode_iscancelled_block_t)isCancelledBlock displayBlocks:(NSMutableArray *)displayBlocks
{
  // Skip subtrees that are hidden or zero alpha.
  if (self.isHidden || self.alpha <= 0.0) {
    return;
  }
  
  __instanceLock__.lock();
  BOOL rasterizingFromAscendent = (_hierarchyState & ASHierarchyStateRasterized);
  __instanceLock__.unlock();

  // if super node is rasterizing descendants, subnodes will not have had layout calls because they don't have layers
  if (rasterizingFromAscendent) {
    [self __layout];
  }

  // Capture these outside the display block so they are retained.
  NSColor *backgroundColor = self.backgroundColor;
  CGRect bounds = self.bounds;
  CGFloat cornerRadius = self.cornerRadius;
  BOOL clipsToBounds = self.clipsToBounds;

  CGRect frame;
  
  // If this is the root container node, use a frame with a zero origin to draw into. If not, calculate the correct frame using the node's position, transform and anchorPoint.
  if (self.rasterizesSubtree) {
    frame = CGRectMake(0.0f, 0.0f, bounds.size.width, bounds.size.height);
  } else {
    CGPoint position = self.position;
    CGPoint anchorPoint = self.anchorPoint;
    
    // Pretty hacky since full 3D transforms aren't actually supported, but attempt to compute the transformed frame of this node so that we can composite it into approximately the right spot.
    CGAffineTransform transform = CATransform3DGetAffineTransform(self.transform);
    CGSize scaledBoundsSize = CGSizeApplyAffineTransform(bounds.size, transform);
    CGPoint origin = CGPointMake(position.x - scaledBoundsSize.width * anchorPoint.x,
                                 position.y - scaledBoundsSize.height * anchorPoint.y);
    frame = CGRectMake(origin.x, origin.y, bounds.size.width, bounds.size.height);
  }

  // Get the display block for this node.
  asyncdisplaykit_async_transaction_operation_block_t displayBlock = [self _displayBlockWithAsynchronous:NO isCancelledBlock:isCancelledBlock rasterizing:YES];

  // We'll display something if there is a display block, clipping, translation and/or a background color.
  BOOL shouldDisplay = displayBlock || backgroundColor || CGPointEqualToPoint(CGPointZero, frame.origin) == NO || clipsToBounds;

  // If we should display, then push a transform, draw the background color, and draw the contents.
  // The transform is popped in a block added after the recursion into subnodes.
  // Если нужно отображать, то сохраняем состояние контекста и рисуем содержимое.
  if (shouldDisplay) {
      dispatch_block_t pushAndDisplayBlock = ^{
          // Сохранение состояния контекста
          CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
          CGContextSaveGState(context);
  
          // Трансляция относительно родителя.
          CGContextTranslateCTM(context, self.frame.origin.x, self.frame.origin.y);
  
          // Поддержка cornerRadius
          if ((self->_hierarchyState & ASHierarchyStateRasterized) && self.clipsToBounds) {
              if (self.cornerRadius) {
                  NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:self.cornerRadius yRadius:self.cornerRadius];
                  [path addClip];
              } else {
                  CGContextClipToRect(context, self.bounds);
              }
          }
  
          // Заполнение фона, если есть.
          CGColorRef backgroundCGColor = self.backgroundColor.CGColor;
          if (self.backgroundColor && CGColorGetAlpha(backgroundCGColor) > 0.0) {
              CGContextSetFillColorWithColor(context, backgroundCGColor);
              CGContextFillRect(context, self.bounds);
          }
  
          // Если есть displayBlock, вызываем его для получения изображения, затем рисуем изображение в текущем контексте.
          if (displayBlock) {
              NSImage *image = (NSImage *)displayBlock();
              CGImageRef cgImage = [image cgImage];
              if (image) {
                BOOL opaque = ASImageAlphaInfoIsOpaque(CGImageGetAlphaInfo(cgImage));
                  NSCompositingOperation compositingOperation = opaque ? NSCompositingOperationCopy : NSCompositingOperationSourceOver;
                  [image drawInRect:self.bounds
                           fromRect:NSZeroRect
                          operation:compositingOperation
                           fraction:1.0];
              }
          }
      };
      [displayBlocks addObject:pushAndDisplayBlock];
  }

  // Recursively capture displayBlocks for all descendants.
  for (ASDisplayNode *subnode in self.subnodes) {
    [subnode _recursivelyRasterizeSelfAndSublayersWithIsCancelledBlock:isCancelledBlock displayBlocks:displayBlocks];
  }

  // If we pushed a transform, pop it by adding a display block that does nothing other than that.
  // Если мы сохранили состояние контекста, восстанавливаем его.
  if (shouldDisplay) {
      dispatch_block_t popBlock = ^{
          CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
          CGContextRestoreGState(context);
      };
      [displayBlocks addObject:popBlock];
  }
}

- (asyncdisplaykit_async_transaction_operation_block_t)_displayBlockWithAsynchronous:(BOOL)asynchronous
                                                                    isCancelledBlock:(asdisplaynode_iscancelled_block_t)isCancelledBlock
                                                                         rasterizing:(BOOL)rasterizing
{
  ASDisplayNodeAssertMainThread();
  
  asyncdisplaykit_async_transaction_operation_block_t displayBlock = nil;
  ASDisplayNodeFlags flags;
  
  __instanceLock__.lock();
  
  flags = _flags;
  
  // В macOS всегда создаем графический контекст, если не rasterizing.
  BOOL shouldCreateGraphicsContext = (flags.implementsImageDisplay == NO && rasterizing == NO);
  BOOL shouldBeginRasterizing = (rasterizing == NO && flags.rasterizesSubtree);
  BOOL usesImageDisplay = flags.implementsImageDisplay;
  BOOL usesDrawRect = flags.implementsDrawRect;
  
  if (usesImageDisplay == NO && usesDrawRect == NO && shouldBeginRasterizing == NO) {
      // Ранний выход до запроса более дорогих свойств, таких как bounds и opaque.
      __instanceLock__.unlock();
      return nil;
  }
  
  BOOL opaque = self.opaque;
  CGRect bounds = self.bounds;
  NSColor *backgroundColor = self.backgroundColor;
  CGColorRef borderColor = self.borderColor;
  CGFloat borderWidth = self.borderWidth;
  CGFloat contentsScaleForDisplay = _contentsScaleForDisplay;
  
  __instanceLock__.unlock();
  
  // Захват drawParameters от делегата на основном потоке, если этот узел отображает себя сам, а не рекурсивно растеризуется.
  id drawParameters = (shouldBeginRasterizing == NO ? [self drawParameters] : nil);
  
  // Только методы -display должны вызываться, если мы не можем установить размер графического буфера.
  if (CGRectIsEmpty(bounds) && (shouldBeginRasterizing || shouldCreateGraphicsContext)) {
      return nil;
  }
  
  ASDisplayNodeAssert(contentsScaleForDisplay != 0.0, @"Invalid contents scale");
  ASDisplayNodeAssert(rasterizing || !(_hierarchyState & ASHierarchyStateRasterized),
                      @"Rasterized descendants should never display unless being drawn into the rasterized container.");
  
  if (shouldBeginRasterizing) {
      // Собираем displayBlocks для всех потомков.
      NSMutableArray *displayBlocks = [[NSMutableArray alloc] init];
      [self _recursivelyRasterizeSelfAndSublayersWithIsCancelledBlock:isCancelledBlock displayBlocks:displayBlocks];
      CHECK_CANCELLED_AND_RETURN_NIL();
      
      // Если используется прозрачный или полупрозрачный цвет фона, включаем альфа-канал при растеризации.
      opaque = opaque && CGColorGetAlpha(backgroundColor.CGColor) == 1.0f;
      
      displayBlock = ^id{
          CHECK_CANCELLED_AND_RETURN_NIL();
          
          NSImage *image = ASGraphicsCreateImage(self.primitiveTraitCollection, bounds.size, opaque, contentsScaleForDisplay, nil, isCancelledBlock, ^{
              for (dispatch_block_t block in displayBlocks) {
                  if (isCancelledBlock()) return;
                  block();
              }
          });
          
          ASDN_DELAY_FOR_DISPLAY();
          return image;
      };
  } else {
      displayBlock = ^id{
          CHECK_CANCELLED_AND_RETURN_NIL();
          
          __block NSImage *image = nil;
          void (^workWithContext)() = ^{
              CGContextRef currentContext = [[NSGraphicsContext currentContext] CGContext];
              
              if (shouldCreateGraphicsContext && !currentContext) {
                  ASDisplayNodeAssert(NO, @"Failed to create a CGContext (size: %@)", NSStringFromSize(bounds.size));
                  return;
              }
              
              // Для методов -display мы не имеем контекста, и, следовательно, не будем вызывать блоки _willDisplayNodeContentWithRenderingContext или _didDisplayNodeContentWithRenderingContext.
              [self __willDisplayNodeContentWithRenderingContext:currentContext drawParameters:drawParameters];
              
              if (usesImageDisplay) { // Если используем метод отображения, получаем изображение напрямую.
                  image = [self.class displayWithParameters:drawParameters isCancelled:isCancelledBlock];
              } else if (usesDrawRect) { // Если используем метод drawRect, выполняем отрисовку в текущем контексте.
                  [self.class drawRect:bounds withParameters:drawParameters isCancelled:isCancelledBlock isRasterizing:rasterizing];
              }
              
              [self __didDisplayNodeContentWithRenderingContext:currentContext image:&image drawParameters:drawParameters backgroundColor:backgroundColor borderWidth:borderWidth borderColor:borderColor];
              ASDN_DELAY_FOR_DISPLAY();
          };
          
          if (shouldCreateGraphicsContext) {
              return ASGraphicsCreateImage(self.primitiveTraitCollection, bounds.size, opaque, contentsScaleForDisplay, nil, isCancelledBlock, workWithContext);
          } else {
              workWithContext();
              return image;
          }
      };
  }
  
  /**
   Если мы профилируем, обернем блок отображения с использованием signpost start и end.
   Окрасим интервал красным, если отменено, зеленым иначе.
   */
#if AS_SIGNPOST_ENABLE
  __weak typeof(self) weakSelf = self;
  displayBlock = ^{
      ASSignpostStart(LayerDisplay, weakSelf, "%@", ASObjectDescriptionMakeTiny(weakSelf));
      id result = displayBlock();
      ASSignpostEnd(LayerDisplay, weakSelf, "(%d %d), canceled: %d", (int)bounds.size.width, (int)bounds.size.height, (int)isCancelledBlock());
      return result;
  };
#endif
  
  return displayBlock;
}

- (void)__willDisplayNodeContentWithRenderingContext:(CGContextRef)context drawParameters:(id _Nullable)drawParameters
{
  if (context) {
      __instanceLock__.lock();
          ASCornerRoundingType cornerRoundingType = _cornerRoundingType;
          CGFloat cornerRadius = _cornerRadius;
          ASDisplayNodeContextModifier willDisplayNodeContentWithRenderingContext = _willDisplayNodeContentWithRenderingContext;
          CACornerMask maskedCorners = _maskedCorners;
      __instanceLock__.unlock();
  
      if (cornerRoundingType == ASCornerRoundingTypePrecomposited && cornerRadius > 0.0) {
          // В macOS не используется UIGraphicsGetCurrentContext(), поэтому ассерция заменена
          ASDisplayNodeAssert(context != NULL, @"context should not be NULL %@", self);
          
          // Создаем NSBezierPath с закругленными углами
          NSRect boundingBox = CGContextGetClipBoundingBox(context);
          NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:boundingBox xRadius:cornerRadius yRadius:cornerRadius];
          [path setWindingRule:NSWindingRuleEvenOdd];
          [path addClip];
      }
      
      if (willDisplayNodeContentWithRenderingContext) {
          willDisplayNodeContentWithRenderingContext(context, drawParameters);
      }
  }

}
- (void)__didDisplayNodeContentWithRenderingContext:(CGContextRef)context image:(NSImage **)image drawParameters:(id _Nullable)drawParameters backgroundColor:(NSColor *)backgroundColor borderWidth:(CGFloat)borderWidth borderColor:(CGColorRef)borderColor
{
  if (context == NULL && *image == nil) {
          return;
      }

      __instanceLock__.lock();
          ASCornerRoundingType cornerRoundingType = _cornerRoundingType;
          CGFloat cornerRadius = _cornerRadius;
          CGFloat contentsScale = _contentsScaleForDisplay;
          ASDisplayNodeContextModifier didDisplayNodeContentWithRenderingContext = _didDisplayNodeContentWithRenderingContext;
          CACornerMask maskedCorners = _maskedCorners;
      __instanceLock__.unlock();

      if (context != NULL) {
          if (didDisplayNodeContentWithRenderingContext) {
              didDisplayNodeContentWithRenderingContext(context, drawParameters);
          }
      }

      if (cornerRoundingType == ASCornerRoundingTypePrecomposited && cornerRadius > 0.0f) {
          CGRect bounds = CGRectZero;
          BOOL createdContext = NO;
          NSImage *newImage = nil;

          if (context == NULL) {
              bounds = self.threadSafeBounds;
              bounds.size.width *= contentsScale;
              bounds.size.height *= contentsScale;

              // Получение компонента альфа из backgroundColor
              CGFloat white = 0.0f, alpha = 0.0f;
              [backgroundColor getWhite:&white alpha:&alpha];

              // Создание нового NSImage
              newImage = [[NSImage alloc] initWithSize:bounds.size];
              [newImage lockFocusFlipped:NO];
              // Отрисовка существующего изображения в новый
              if (*image) {
                  [*image drawInRect:NSMakeRect(0, 0, bounds.size.width, bounds.size.height)
                            fromRect:NSZeroRect
                           operation:NSCompositingOperationSourceOver
                            fraction:1.0f];
              }
              createdContext = YES;
          } else {
              bounds = CGContextGetClipBoundingBox(context);
          }

          // Проверка наличия текущего графического контекста
          ASDisplayNodeAssert([[NSGraphicsContext currentContext] CGContext] != NULL, @"context is expected to be pushed on NSGraphicsContext stack %@", self);

          CGContextRef currentCGContext = [[NSGraphicsContext currentContext] CGContext];
          if (currentCGContext == NULL) {
              return;
          }

          // Создание пути с правилом заполнения even-odd
          NSBezierPath *path = [NSBezierPath bezierPathWithRect:bounds];
          NSBezierPath *roundedRectPath = [NSBezierPath bezierPathWithRoundedRect:bounds
                                                                          xRadius:(cornerRadius * contentsScale)
                                                                          yRadius:(cornerRadius * contentsScale)];
          [path appendBezierPath:roundedRectPath];
          CGPathRef pathRef = CGPathCreateWithNSBezierPath(path);
          CGContextAddPath(currentCGContext, pathRef);
          CGPathRelease(pathRef);

          // Установка правила заполнения
        CGContextSetBlendMode(currentCGContext, kCGBlendModeCopy);
        // Вместо вызова FillPath используем DrawPath с параметром kCGPathEOFill
        CGContextDrawPath(currentCGContext, kCGPathEOFill);

          // Создание пути для закругленных углов, если требуется
          NSBezierPath *roundedPath = nil;
          if (borderWidth > 0.0f) { // Не создавать roundedPath и не обводить, если borderWidth равен 0.0
              CGFloat strokeThickness = borderWidth * contentsScale;
              CGFloat strokeInset = ((strokeThickness + 1.0f) / 2.0f) - 1.0f;
              CGRect insetBounds = CGRectInset(bounds, strokeInset, strokeInset);
              CGFloat insetCornerRadius = cornerRadius * contentsScale;
              roundedPath = [NSBezierPath bezierPathWithRoundedRect:insetBounds
                                                          xRadius:insetCornerRadius
                                                          yRadius:insetCornerRadius];
              [roundedPath setLineWidth:strokeThickness];
              [[NSColor colorWithCGColor:borderColor] setStroke];
          }

          // Заполнение roundedHole цветом фона с использованием NSCompositingOperationCopy
          [backgroundColor setFill];
          CGContextSetBlendMode(currentCGContext, kCGBlendModeCopy);
          CGContextFillPath(currentCGContext);

          // Обводка рамки, если требуется
          if (roundedPath) {
              [roundedPath stroke];
          }

          if (createdContext && newImage) {
              *image = newImage;
              [newImage unlockFocus];
          }
      }
}

NS_INLINE CGPathRef CGPathCreateWithNSBezierPath(NSBezierPath *bezierPath) {
    CGMutablePathRef path = CGPathCreateMutable();
    NSInteger numElements = [bezierPath elementCount];
    if (numElements == 0) {
        return path;
    }

    NSPoint points[3];
    for (NSInteger i = 0; i < numElements; i++) {
        switch ([bezierPath elementAtIndex:i associatedPoints:points]) {
            case NSBezierPathElementMoveTo:
                CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                break;
            case NSBezierPathElementLineTo:
                CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                break;
            case NSBezierPathElementCurveTo:
                CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                      points[1].x, points[1].y,
                                      points[2].x, points[2].y);
                break;
            case NSBezierPathElementClosePath:
                CGPathCloseSubpath(path);
                break;
        }
    }

    return path;
}

- (void)displayAsyncLayer:(_ASDisplayLayer *)asyncLayer asynchronously:(BOOL)asynchronously
{
  ASDisplayNodeAssertMainThread();
  
  __instanceLock__.lock();
  
  if (_hierarchyState & ASHierarchyStateRasterized) {
    __instanceLock__.unlock();
    return;
  }
  
  CALayer *layer = _layer;
  BOOL rasterizesSubtree = _flags.rasterizesSubtree;
  
  __instanceLock__.unlock();

  // for async display, capture the current displaySentinel value to bail early when the job is executed if another is
  // enqueued
  // for sync display, do not support cancellation
  
  // FIXME: what about the degenerate case where we are calling setNeedsDisplay faster than the jobs are dequeuing
  // from the displayQueue?  Need to not cancel early fails from displaySentinel changes.
  asdisplaynode_iscancelled_block_t isCancelledBlock = nil;
  if (asynchronously) {
    uint displaySentinelValue = ++_displaySentinel;
    __weak ASDisplayNode *weakSelf = self;
    isCancelledBlock = ^BOOL{
      __strong ASDisplayNode *self = weakSelf;
      return self == nil || (displaySentinelValue != self->_displaySentinel.load());
    };
  } else {
    isCancelledBlock = ^BOOL{
      return NO;
    };
  }

  // Set up displayBlock to call either display or draw on the delegate and return a NSImage contents
  asyncdisplaykit_async_transaction_operation_block_t displayBlock = [self _displayBlockWithAsynchronous:asynchronously isCancelledBlock:isCancelledBlock rasterizing:NO];
  
  if (!displayBlock) {
    return;
  }
  
  ASDisplayNodeAssert(layer, @"Expect _layer to be not nil");

  // This block is called back on the main thread after rendering at the completion of the current async transaction, or immediately if !asynchronously
  asyncdisplaykit_async_transaction_operation_completion_block_t completionBlock = ^(id<NSObject> value, BOOL canceled){
    ASDisplayNodeCAssertMainThread();
    if (!canceled && !isCancelledBlock()) {
      NSImage *image = (NSImage *)value;
      CGImageRef cgImage = [image cgImage];
      BOOL stretchable = (NO == NSEdgeInsetsEqualToEdgeInsets(image.capInsets, NSEdgeInsetsZero));
      if (stretchable) {
        ASDisplayNodeSetResizableContents(layer, image);
      } else {
        layer.contentsScale = self.contentsScale;
        layer.contents = (id)CFBridgingRelease(cgImage);
      }
      [self didDisplayAsyncLayer:self.asyncLayer];
      
      if (rasterizesSubtree) {
        ASDisplayNodePerformBlockOnEverySubnode(self, NO, ^(ASDisplayNode * _Nonnull node) {
          [node didDisplayAsyncLayer:node.asyncLayer];
        });
      }
    }
  };

  // Call willDisplay immediately in either case
  [self willDisplayAsyncLayer:self.asyncLayer asynchronously:asynchronously];
  
  if (rasterizesSubtree) {
    ASDisplayNodePerformBlockOnEverySubnode(self, NO, ^(ASDisplayNode * _Nonnull node) {
      [node willDisplayAsyncLayer:node.asyncLayer asynchronously:asynchronously];
    });
  }

  if (asynchronously) {
    // Async rendering operations are contained by a transaction, which allows them to proceed and concurrently
    // while synchronizing the final application of the results to the layer's contents property (completionBlock).
    
    // First, look to see if we are expected to join a parent's transaction container.
    CALayer *containerLayer = layer.asyncdisplaykit_parentTransactionContainer ? : layer;
    
    // In the case that a transaction does not yet exist (such as for an individual node outside of a container),
    // this call will allocate the transaction and add it to _ASAsyncTransactionGroup.
    // It will automatically commit the transaction at the end of the runloop.
    _ASAsyncTransaction *transaction = containerLayer.asyncdisplaykit_asyncTransaction;
    
    // Adding this displayBlock operation to the transaction will start it IMMEDIATELY.
    // The only function of the transaction commit is to gate the calling of the completionBlock.
    [transaction addOperationWithBlock:displayBlock priority:self.drawingPriority queue:[_ASDisplayLayer displayQueue] completion:completionBlock];
  } else {
    NSImage *contents = (NSImage *)displayBlock();
    completionBlock(contents, NO);
  }
}

static inline bool NSEdgeInsetsEqualToEdgeInsets(NSEdgeInsets insets1, NSEdgeInsets insets2)
{
  return (insets1.top == insets2.top &&
          insets1.left == insets2.left &&
          insets1.bottom == insets2.bottom &&
          insets1.right == insets2.right);
}

- (void)cancelDisplayAsyncLayer:(_ASDisplayLayer *)asyncLayer
{
  _displaySentinel.fetch_add(1);
}

- (ASDisplayNodeContextModifier)willDisplayNodeContentWithRenderingContext
{
  MutexLocker l(__instanceLock__);
  return _willDisplayNodeContentWithRenderingContext;
}

- (ASDisplayNodeContextModifier)didDisplayNodeContentWithRenderingContext
{
  MutexLocker l(__instanceLock__);
  return _didDisplayNodeContentWithRenderingContext;
}

- (void)setWillDisplayNodeContentWithRenderingContext:(ASDisplayNodeContextModifier)contextModifier
{
  MutexLocker l(__instanceLock__);
  _willDisplayNodeContentWithRenderingContext = contextModifier;
}

- (void)setDidDisplayNodeContentWithRenderingContext:(ASDisplayNodeContextModifier)contextModifier
{
  MutexLocker l(__instanceLock__);
  _didDisplayNodeContentWithRenderingContext = contextModifier;
}

@end
