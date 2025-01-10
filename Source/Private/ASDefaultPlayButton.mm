//
//  ASDefaultPlayButton.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASDefaultPlayButton.h"
#import "_ASDisplayLayer.h"

@implementation ASDefaultPlayButton

- (instancetype)init
{
  if (!(self = [super init])) {
    return nil;
  }
  
  self.opaque = NO;
  
  return self;
}

+ (void)drawRect:(CGRect)bounds withParameters:(id)parameters isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock isRasterizing:(BOOL)isRasterizing
{
  CGFloat originX = bounds.size.width / 4.0;
      CGRect buttonBounds = CGRectMake(originX, bounds.size.height / 4.0, bounds.size.width / 2.0, bounds.size.height / 2.0);
      CGFloat widthHeight = buttonBounds.size.width;

      // Когда видео не квадратное, используем меньшую сторону для определения размера круга
      if (bounds.size.width < bounds.size.height) {
          widthHeight = bounds.size.width / 2.0;
          originX = (bounds.size.width - widthHeight) / 2.0;
          buttonBounds = CGRectMake(originX, (bounds.size.height - widthHeight) / 2.0, widthHeight, widthHeight);
      }
      if (bounds.size.width > bounds.size.height) {
          widthHeight = bounds.size.height / 2.0;
          originX = (bounds.size.width - widthHeight) / 2.0;
          buttonBounds = CGRectMake(originX, (bounds.size.height - widthHeight) / 2.0, widthHeight, widthHeight);
      }

      CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
      if (!context) {
          // Нет контекста для отрисовки
          return;
      }

      // Рисование круга
      NSBezierPath *ovalPath = [NSBezierPath bezierPathWithOvalInRect:buttonBounds];
      [[NSColor colorWithWhite:0.0 alpha:0.5] setFill];
      [ovalPath fill];

      // Рисование треугольника
      CGContextSaveGState(context);

      NSBezierPath *trianglePath = [NSBezierPath bezierPath];
      [trianglePath moveToPoint:NSMakePoint(originX + widthHeight / 3.0, bounds.size.height / 4.0 + (bounds.size.height / 2.0) / 4.0)];
      [trianglePath lineToPoint:NSMakePoint(originX + widthHeight / 3.0, bounds.size.height - bounds.size.height / 4.0 - (bounds.size.height / 2.0) / 4.0)];
      [trianglePath lineToPoint:NSMakePoint(bounds.size.width - originX - widthHeight / 4.0, bounds.size.height / 2.0)];
      [trianglePath closePath];

      [[NSColor colorWithWhite:0.9 alpha:0.9] setFill];
      [trianglePath fill];

      CGContextRestoreGState(context);
}

@end
