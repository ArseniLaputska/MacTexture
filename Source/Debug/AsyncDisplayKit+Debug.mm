//
//  AsyncDisplayKit+Debug.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "AsyncDisplayKit+Debug.h"
#import "ASAbstractLayoutController.h"
#import "ASLayout.h"
#import "UIImage+ASConvenience.h"
#import "ASDisplayNode+Subclasses.h"
#import "ASGraphicsContext.h"
#import "CoreGraphics+ASConvenience.h"
#import "ASDisplayNodeExtras.h"
#import "ASTextNode.h"
#import "ASRangeController.h"


#pragma mark - ASImageNode (Debugging)

static BOOL __shouldShowImageScalingOverlay = NO;

@implementation ASImageNode (Debugging)

+ (void)setShouldShowImageScalingOverlay:(BOOL)show
{
  __shouldShowImageScalingOverlay = show;
}

+ (BOOL)shouldShowImageScalingOverlay
{
  return __shouldShowImageScalingOverlay;
}

@end

#pragma mark - ASControlNode (DebuggingInternal)

static BOOL __enableHitTestDebug = NO;

@interface ASControlNode (DebuggingInternal)

- (ASImageNode *)debugHighlightOverlay;

@end

@implementation ASControlNode (Debugging)

+ (void)setEnableHitTestDebug:(BOOL)enable
{
  __enableHitTestDebug = enable;
}

+ (BOOL)enableHitTestDebug
{
  return __enableHitTestDebug;
}

static inline CGRect NSEdgeInsetsInsetRect(CGRect rect, NSEdgeInsets insets) {
    rect.origin.x += insets.left;
    rect.origin.y += insets.top;
    rect.size.width -= (insets.left + insets.right);
    rect.size.height -= (insets.top + insets.bottom);
    return rect;
}

// layout method required ONLY when hitTestDebug is enabled
- (void)layout
{
  [super layout];

  if ([ASControlNode enableHitTestDebug]) {
    
    // 1) Рассчитать начальную область касания, учитывая hitTestSlop
    NSRect intersectRect = NSEdgeInsetsInsetRect(NSRectFromCGRect(self.bounds), [self hitTestSlop]);
    
    // 2) Инициализируем флаги ограничений
    NSRectEdge clippedEdges              = NSRectEdgeMinX;
    NSRectEdge clipsToBoundsClippedEdges = NSRectEdgeMinX;
    
    CALayer *layer               = self.layer;
    CALayer *intersectLayer      = layer;
    CALayer *intersectSuperlayer = layer.superlayer;

    // 3) Поднимаемся по иерархии, пока не встретим UIScrollView аналог
    // (В macOS это может быть NSScrollView, проверяйте если нужно).
    // Предположим, что superlayer.delegate —> NSView (NSTextView / NSScrollView / т.д.)

    while (intersectSuperlayer) // свой кастомный метод проверки
    {
      NSRect parentHitRect = NSRectFromCGRect(intersectSuperlayer.bounds);
      BOOL parentClipsToBounds = NO;

      // Если superlayer ассоциирован с ASDisplayNode
      ASDisplayNode *parentNode = ASLayerToDisplayNode(intersectSuperlayer);
      if (parentNode) {
        NSEdgeInsets parentSlop = [parentNode hitTestSlop];
        if (!NSEdgeInsetsEqual(parentSlop, NSEdgeInsetsZero)) {
          parentClipsToBounds = parentNode.clipsToBounds;
          if (!parentClipsToBounds) {
            parentHitRect = NSEdgeInsetsInsetRect(parentHitRect, parentSlop);
          }
        }
      }

      // 4) Преобразуем координаты childRect -> координаты superlayer
      NSRect childRectInParent = NSRectFromCGRect(
          [intersectSuperlayer convertRect:NSRectToCGRect(intersectRect)
                                  fromLayer:intersectLayer]
      );

      // 5) Пересечение с parentHitRect
      NSRect newIntersectRect = NSIntersectionRect(parentHitRect, childRectInParent);

      // если размеры пересеклись
      if (!NSEqualSizes(parentHitRect.size, childRectInParent.size)) {
        clippedEdges = [self setEdgesOfIntersectionForChildRect:childRectInParent
                                                     parentRect:parentHitRect
                                                       rectEdge:clippedEdges];
        if (parentClipsToBounds) {
          clipsToBoundsClippedEdges = [self setEdgesOfIntersectionForChildRect:childRectInParent
                                                                    parentRect:parentHitRect
                                                                      rectEdge:clipsToBoundsClippedEdges];
        }
      }

      intersectRect     = newIntersectRect;
      intersectLayer    = intersectSuperlayer;
      intersectSuperlayer = intersectLayer.superlayer;
    }

    // 6) Конвертируем обратно в локальные координаты
    CGRect finalRect = [intersectLayer convertRect:NSRectToCGRect(intersectRect)
                                           toLayer:layer];

    // 7) Задаем цвет фона
    NSColor *fillColor = [[NSColor greenColor] colorWithAlphaComponent:0.4];

    ASImageNode *debugOverlay = [self debugHighlightOverlay];

    if (clippedEdges == NSRectEdgeMinX) {
      debugOverlay.backgroundColor = fillColor;
    } else {
      // 8) Рисуем изображение с цветным бордюром
      const CGFloat borderWidth = 2.0;
      NSColor *borderColor      = [[NSColor orangeColor] colorWithAlphaComponent:0.8];
      NSColor *clipsBorderColor = [NSColor colorWithCalibratedRed:30/255.0
                                                            green:90/255.0
                                                             blue:50/255.0
                                                            alpha:0.7];
      CGRect imgRect            = CGRectMake(0, 0, 2.0 * borderWidth + 1.0, 2.0 * borderWidth + 1.0);

      NSImage *debugHighlightImage = ASGraphicsCreateImage(self.primitiveTraitCollection,
                                                           imgRect.size,
                                                           NO,
                                                           1,
                                                           nil,
                                                           nil, ^{
        [fillColor setFill];
        NSRectFill(NSRectFromCGRect(imgRect));

        [self drawEdgeIfClippedWithEdges:clippedEdges
                                   color:clipsBorderColor
                             borderWidth:borderWidth
                                  imgRect:imgRect];

        [self drawEdgeIfClippedWithEdges:clipsToBoundsClippedEdges
                                   color:borderColor
                             borderWidth:borderWidth
                                  imgRect:imgRect];
      });

      NSEdgeInsets edgeInsets = { borderWidth, borderWidth, borderWidth, borderWidth };
      debugOverlay.image = debugHighlightImage;
//      [debugHighlightImage resizableImageWithCapInsets:edgeInsets
//                                                              resizingMode:NSImageResizingModeStretch];
      debugOverlay.backgroundColor = nil;
    }

    debugOverlay.frame = finalRect;
  }
}

- (NSRectEdge)setEdgesOfIntersectionForChildRect:(NSRect)childRect
                                          parentRect:(NSRect)parentRect
                                            rectEdge:(NSRectEdge)rectEdge
{
//  // Определяем, какие края childRect выходят за parentRect
//  if (NSMinY(childRect) < NSMinY(parentRect)) {
//    rectEdge |= NSRectEdgeMinY; // аналог UIRectEdgeTop
//  }
//  if (NSMinX(childRect) < NSMinX(parentRect)) {
//    rectEdge |= NSRectEdgeMinX; // аналог UIRectEdgeLeft
//  }
//  if (NSMaxY(childRect) > NSMaxY(parentRect)) {
//    rectEdge |= NSRectEdgeMaxY; // аналог UIRectEdgeBottom
//  }
//  if (NSMaxX(childRect) > NSMaxX(parentRect)) {
//    rectEdge |= NSRectEdgeMaxX; // аналог UIRectEdgeRight
//  }

  return rectEdge;
}

- (void)drawEdgeIfClippedWithEdges:(NSRectEdge)rectEdge
                             color:(NSColor *)color
                       borderWidth:(CGFloat)borderWidth
                            imgRect:(CGRect)imgRect
{
  [color setFill];

  // Преобразуем CGRect -> NSRect
  NSRect nsImgRect = NSRectFromCGRect(imgRect);

  // Заполняем края, где есть ограничения
  if (rectEdge & NSRectEdgeMinY) {
    NSRectFill(NSMakeRect(0.0, 0.0, nsImgRect.size.width, borderWidth));
  }
  if (rectEdge & NSRectEdgeMinX) {
    NSRectFill(NSMakeRect(0.0, 0.0, borderWidth, nsImgRect.size.height));
  }
  if (rectEdge & NSRectEdgeMaxY) {
    NSRectFill(NSMakeRect(0.0, nsImgRect.size.height - borderWidth,
                          nsImgRect.size.width, borderWidth));
  }
  if (rectEdge & NSRectEdgeMaxX) {
    NSRectFill(NSMakeRect(nsImgRect.size.width - borderWidth, 0.0,
                          borderWidth, nsImgRect.size.height));
  }
}

@end

#pragma mark - ASRangeController (Debugging)

@interface _ASRangeDebugOverlayView : NSView

+ (instancetype)sharedInstance NS_RETURNS_RETAINED;

- (void)addRangeController:(ASRangeController *)rangeController;

- (void)updateRangeController:(ASRangeController *)controller
     withScrollableDirections:(ASScrollDirection)scrollableDirections
              scrollDirection:(ASScrollDirection)direction
                    rangeMode:(ASLayoutRangeMode)mode
      displayTuningParameters:(ASRangeTuningParameters)displayTuningParameters
      preloadTuningParameters:(ASRangeTuningParameters)preloadTuningParameters
               interfaceState:(ASInterfaceState)interfaceState;

@end

@interface _ASRangeDebugBarView : NSView

@property (nonatomic, weak) ASRangeController *rangeController;
@property (nonatomic) BOOL destroyOnLayout;
@property (nonatomic) NSString *debugString;

- (instancetype)initWithRangeController:(ASRangeController *)rangeController;

- (void)updateWithVisibleRatio:(CGFloat)visibleRatio
                  displayRatio:(CGFloat)displayRatio
           leadingDisplayRatio:(CGFloat)leadingDisplayRatio
                  preloadRatio:(CGFloat)preloadRatio
           leadingpreloadRatio:(CGFloat)leadingpreloadRatio
                     direction:(ASScrollDirection)direction;

@end

static BOOL __shouldShowRangeDebugOverlay = NO;

@implementation ASDisplayNode (RangeDebugging)

+ (void)setShouldShowRangeDebugOverlay:(BOOL)show
{
  __shouldShowRangeDebugOverlay = show;
}

+ (BOOL)shouldShowRangeDebugOverlay
{
  return __shouldShowRangeDebugOverlay;
}

@end

@implementation ASRangeController (DebugInternal)

+ (void)layoutDebugOverlayIfNeeded
{
  [[_ASRangeDebugOverlayView sharedInstance] needsLayout];
}

- (void)addRangeControllerToRangeDebugOverlay
{
  [[_ASRangeDebugOverlayView sharedInstance] addRangeController:self];
}

- (void)updateRangeController:(ASRangeController *)controller
     withScrollableDirections:(ASScrollDirection)scrollableDirections
              scrollDirection:(ASScrollDirection)direction
                    rangeMode:(ASLayoutRangeMode)mode
      displayTuningParameters:(ASRangeTuningParameters)displayTuningParameters
      preloadTuningParameters:(ASRangeTuningParameters)preloadTuningParameters
               interfaceState:(ASInterfaceState)interfaceState
{
  [[_ASRangeDebugOverlayView sharedInstance] updateRangeController:controller
                                          withScrollableDirections:scrollableDirections
                                                   scrollDirection:direction
                                                         rangeMode:mode
                                           displayTuningParameters:displayTuningParameters
                                           preloadTuningParameters:preloadTuningParameters
                                                    interfaceState:interfaceState];
}

@end


#pragma mark _ASRangeDebugOverlayView

@interface _ASRangeDebugOverlayView () <NSGestureRecognizerDelegate>
@end

@implementation _ASRangeDebugOverlayView
{
  NSMutableArray *_rangeControllerViews;
  NSInteger      _newControllerCount;
  NSInteger      _removeControllerCount;
  BOOL           _animating;
}

+ (NSWindow *)keyWindow
{
  // hack to work around app extensions not having UIApplication...not sure of a better way to do this?
  NSApplication *application = [NSClassFromString(@"NSApplication") sharedInstance];
//  NSMutableArray<UIWindowScene *> *windowScenes = [NSMutableArray array];
//  for (UIScene *scene in [application connectedScenes]) {
//    if ([scene isKindOfClass:[UIWindowScene class]]) {
//      [windowScenes addObject:(UIWindowScene *)scene];
//    }
//  }
  
  return application.windows.firstObject;
}

+ (_ASRangeDebugOverlayView *)sharedInstance NS_RETURNS_RETAINED
{
  static _ASRangeDebugOverlayView *__rangeDebugOverlay = nil;
  
//  if (!__rangeDebugOverlay && ASDisplayNode.shouldShowRangeDebugOverlay) {
//    __rangeDebugOverlay = [[self alloc] initWithFrame:CGRectZero];
//    [[self keyWindow] addSubview:__rangeDebugOverlay];
//  }
  
  return __rangeDebugOverlay;
}

#define OVERLAY_INSET 10
#define OVERLAY_SCALE 3
- (instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  
  if (self) {
    _rangeControllerViews = [[NSMutableArray alloc] init];
    self.layer.backgroundColor = [[NSColor blackColor] colorWithAlphaComponent:0.4].CGColor;
    self.layer.zPosition = 1000;
    self.clipsToBounds = YES;
    
    CGSize windowSize = [[[self class] keyWindow] frame].size;
    self.frame  = CGRectMake(windowSize.width - (windowSize.width / OVERLAY_SCALE) - OVERLAY_INSET, windowSize.height - OVERLAY_INSET,
                                                 windowSize.width / OVERLAY_SCALE, 0.0);
    
    NSPanGestureRecognizer *panGR = [[NSPanGestureRecognizer alloc] initWithTarget:self action:@selector(rangeDebugOverlayWasPanned:)];
    [self addGestureRecognizer:panGR];
  }
  
  return self;
}

#define BAR_THICKNESS 24

- (void)layoutSubviews
{
  [super layoutSubtreeIfNeeded];
//  [NSView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
    [self layoutToFitAllBarsExcept:0];
//  } completion:^(BOOL finished) {
//    
//  }];
}

- (void)layoutToFitAllBarsExcept:(NSInteger)barsToClip
{
  CGSize boundsSize = self.bounds.size;
  CGFloat totalHeight = 0.0;
  
  CGRect barRect = CGRectMake(0, boundsSize.height - BAR_THICKNESS, self.bounds.size.width, BAR_THICKNESS);
  NSMutableArray *displayedBars = [NSMutableArray array];
  
  for (_ASRangeDebugBarView *barView in [_rangeControllerViews copy]) {
    barView.frame = barRect;
    
    ASInterfaceState interfaceState = [barView.rangeController.dataSource interfaceStateForRangeController:barView.rangeController];
    
    if (!(interfaceState & (ASInterfaceStateVisible))) {
      if (barView.destroyOnLayout && barView.alphaValue == 0.0) {
        [_rangeControllerViews removeObjectIdenticalTo:barView];
        [barView removeFromSuperview];
      } else {
        barView.alphaValue = 0.0;
      }
    } else {
      assert(!barView.destroyOnLayout); // In this case we should not have a visible interfaceState
      barView.alphaValue = 1.0;
      totalHeight += BAR_THICKNESS;
      barRect.origin.y -= BAR_THICKNESS;
      [displayedBars addObject:barView];
    }
  }
  
  if (totalHeight > 0) {
    totalHeight -= (BAR_THICKNESS * barsToClip);
  }
  
  if (barsToClip == 0) {
    CGRect overlayFrame = self.frame;
    CGFloat heightChange = (overlayFrame.size.height - totalHeight);
    
    overlayFrame.origin.y += heightChange;
    overlayFrame.size.height = totalHeight;
    self.frame = overlayFrame;
    
    for (_ASRangeDebugBarView *barView in displayedBars) {
      [self offsetYOrigin:-heightChange forView:barView];
    }
  }
}

- (void)setOrigin:(CGPoint)origin forView:(NSView *)view
{
  CGRect newFrame = view.frame;
  newFrame.origin = origin;
  view.frame      = newFrame;
}

- (void)offsetYOrigin:(CGFloat)offset forView:(NSView *)view
{
  CGRect newFrame = view.frame;
  newFrame.origin = CGPointMake(newFrame.origin.x, newFrame.origin.y + offset);
  view.frame      = newFrame;
}

- (void)addRangeController:(ASRangeController *)rangeController
{
  for (_ASRangeDebugBarView *rangeView in _rangeControllerViews) {
    if (rangeView.rangeController == rangeController) {
      return;
    }
  }
  _ASRangeDebugBarView *rangeView = [[_ASRangeDebugBarView alloc] initWithRangeController:rangeController];
  [_rangeControllerViews addObject:rangeView];
  [self addSubview:rangeView];
  
  if (!_animating) {
    [self layoutToFitAllBarsExcept:1];
  }
  
//  [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
    self->_animating = YES;
    [self layoutToFitAllBarsExcept:0];
//  } completion:^(BOOL finished) {
//    self->_animating = NO;
//  }];
}

- (void)updateRangeController:(ASRangeController *)controller
     withScrollableDirections:(ASScrollDirection)scrollableDirections
              scrollDirection:(ASScrollDirection)scrollDirection
                    rangeMode:(ASLayoutRangeMode)rangeMode
      displayTuningParameters:(ASRangeTuningParameters)displayTuningParameters
      preloadTuningParameters:(ASRangeTuningParameters)preloadTuningParameters
               interfaceState:(ASInterfaceState)interfaceState
{
  _ASRangeDebugBarView *viewToUpdate = [self barViewForRangeController:controller];
  
  CGRect boundsRect = self.bounds;
  CGRect visibleRect   = CGRectExpandToRangeWithScrollableDirections(boundsRect, ASRangeTuningParametersZero, scrollableDirections, scrollDirection);
  CGRect displayRect   = CGRectExpandToRangeWithScrollableDirections(boundsRect, displayTuningParameters,     scrollableDirections, scrollDirection);
  CGRect preloadRect   = CGRectExpandToRangeWithScrollableDirections(boundsRect, preloadTuningParameters,   scrollableDirections, scrollDirection);
  
  // figure out which is biggest and assume that is full bounds
  BOOL displayRangeLargerThanPreload  = NO;
  CGFloat visibleRatio                = 0;
  CGFloat displayRatio                = 0;
  CGFloat preloadRatio                = 0;
  CGFloat leadingDisplayTuningRatio   = 0;
  CGFloat leadingPreloadTuningRatio   = 0;

  if (displayTuningParameters.leadingBufferScreenfuls + displayTuningParameters.trailingBufferScreenfuls != 0) {
    leadingDisplayTuningRatio = displayTuningParameters.leadingBufferScreenfuls / (displayTuningParameters.leadingBufferScreenfuls + displayTuningParameters.trailingBufferScreenfuls);
  }
  if (preloadTuningParameters.leadingBufferScreenfuls + preloadTuningParameters.trailingBufferScreenfuls != 0) {
    leadingPreloadTuningRatio = preloadTuningParameters.leadingBufferScreenfuls / (preloadTuningParameters.leadingBufferScreenfuls + preloadTuningParameters.trailingBufferScreenfuls);
  }
  
  if (ASScrollDirectionContainsVerticalDirection(scrollDirection)) {
    
    if (displayRect.size.height >= preloadRect.size.height) {
      displayRangeLargerThanPreload = YES;
    } else {
      displayRangeLargerThanPreload = NO;
    }
    
    if (displayRangeLargerThanPreload) {
      visibleRatio    = visibleRect.size.height / displayRect.size.height;
      displayRatio    = 1.0;
      preloadRatio    = preloadRect.size.height / displayRect.size.height;
    } else {
      visibleRatio    = visibleRect.size.height / preloadRect.size.height;
      displayRatio    = displayRect.size.height / preloadRect.size.height;
      preloadRatio    = 1.0;
    }

  } else {
    
    if (displayRect.size.width >= preloadRect.size.width) {
      displayRangeLargerThanPreload = YES;
    } else {
      displayRangeLargerThanPreload = NO;
    }
    
    if (displayRangeLargerThanPreload) {
      visibleRatio    = visibleRect.size.width / displayRect.size.width;
      displayRatio    = 1.0;
      preloadRatio    = preloadRect.size.width / displayRect.size.width;
    } else {
      visibleRatio    = visibleRect.size.width / preloadRect.size.width;
      displayRatio    = displayRect.size.width / preloadRect.size.width;
      preloadRatio    = 1.0;
    }
  }

  [viewToUpdate updateWithVisibleRatio:visibleRatio
                          displayRatio:displayRatio
                   leadingDisplayRatio:leadingDisplayTuningRatio
                          preloadRatio:preloadRatio
                   leadingpreloadRatio:leadingPreloadTuningRatio
                             direction:scrollDirection];

  [self needsLayout];
}

- (_ASRangeDebugBarView *)barViewForRangeController:(ASRangeController *)controller
{
  _ASRangeDebugBarView *rangeControllerBarView = nil;
  
  for (_ASRangeDebugBarView *rangeView in [[_rangeControllerViews reverseObjectEnumerator] allObjects]) {
    // remove barView if its rangeController has been deleted
    if (!rangeView.rangeController) {
      rangeView.destroyOnLayout = YES;
      [self needsLayout];
    }
    ASInterfaceState interfaceState = [rangeView.rangeController.dataSource interfaceStateForRangeController:rangeView.rangeController];
    if (!(interfaceState & (ASInterfaceStateVisible | ASInterfaceStateDisplay))) {
      [self needsLayout];
    }
    
    if ([rangeView.rangeController isEqual:controller]) {
      rangeControllerBarView = rangeView;
    }
  }
  
  return rangeControllerBarView;
}

#define MIN_VISIBLE_INSET 40
- (void)rangeDebugOverlayWasPanned:(NSPanGestureRecognizer *)recognizer
{
  CGPoint translation    = [recognizer translationInView:recognizer.view];
//  CGFloat newCenterX     = recognizer.view.centerXAnchor + translation.x;
//  CGFloat newCenterY     = recognizer.view.center.y + translation.y;
  CGSize boundsSize      = recognizer.view.bounds.size;
  CGSize superBoundsSize = recognizer.view.superview.bounds.size;
  CGFloat minAllowableX  = -boundsSize.width / 2.0 + MIN_VISIBLE_INSET;
  CGFloat maxAllowableX  = superBoundsSize.width + boundsSize.width / 2.0 - MIN_VISIBLE_INSET;
//  
//  if (newCenterX > maxAllowableX) {
//    newCenterX = maxAllowableX;
//  } else if (newCenterX < minAllowableX) {
//    newCenterX = minAllowableX;
//  }
  
  CGFloat minAllowableY = -boundsSize.height / 2.0 + MIN_VISIBLE_INSET;
  CGFloat maxAllowableY = superBoundsSize.height + boundsSize.height / 2.0 - MIN_VISIBLE_INSET;
    
//  if (newCenterY > maxAllowableY) {
//    newCenterY = maxAllowableY;
//  } else if (newCenterY < minAllowableY) {
//    newCenterY = minAllowableY;
//  }
  
//  recognizer.view.center = CGPointMake(newCenterX, newCenterY);
  [recognizer setTranslation:CGPointMake(0, 0) inView:recognizer.view];
}

@end

#pragma mark _ASRangeDebugBarView

@implementation _ASRangeDebugBarView
{
  ASTextNode        *_debugText;
  ASTextNode        *_leftDebugText;
  ASTextNode        *_rightDebugText;
  ASImageNode       *_visibleRect;
  ASImageNode       *_displayRect;
  ASImageNode       *_preloadRect;
  CGFloat           _visibleRatio;
  CGFloat           _displayRatio;
  CGFloat           _preloadRatio;
  CGFloat           _leadingDisplayRatio;
  CGFloat           _leadingpreloadRatio;
  ASScrollDirection _scrollDirection;
  BOOL              _firstLayoutOfRects;
}

- (instancetype)initWithRangeController:(ASRangeController *)rangeController
{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _firstLayoutOfRects = YES;
    _rangeController    = rangeController;
    _debugText          = [self createDebugTextNode];
    _leftDebugText      = [self createDebugTextNode];
    _rightDebugText     = [self createDebugTextNode];
    _preloadRect        = [self createRangeNodeWithColor:[NSColor orangeColor]];
    _displayRect        = [self createRangeNodeWithColor:[NSColor yellowColor]];
    _visibleRect        = [self createRangeNodeWithColor:[NSColor greenColor]];
  }
  
  return self;
}

#define HORIZONTAL_INSET 10
- (void)layoutSubviews
{
  [super layoutSubtreeIfNeeded];
  
  CGSize boundsSize     = self.bounds.size;
  CGFloat subCellHeight = 9.0;
  [self setBarDebugLabelsWithSize:subCellHeight];
  [self setBarSubviewOrder];

  CGRect rect       = CGRectIntegral(CGRectMake(0, 0, boundsSize.width, floorf(boundsSize.height / 2.0)));
  rect.size         = [_debugText layoutThatFits:ASSizeRangeMake(CGSizeZero, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))].size;
  rect.origin.x     = (boundsSize.width - rect.size.width) / 2.0;
  _debugText.frame  = rect;
  rect.origin.y    += rect.size.height;
  
  rect.origin.x          = 0;
  rect.size              = CGSizeMake(HORIZONTAL_INSET, boundsSize.height / 2.0);
  _leftDebugText.frame   = rect;

  rect.origin.x          = boundsSize.width - HORIZONTAL_INSET;
  _rightDebugText.frame  = rect;

  CGFloat visibleDimension   = (boundsSize.width - 2 * HORIZONTAL_INSET) * _visibleRatio;
  CGFloat displayDimension   = (boundsSize.width - 2 * HORIZONTAL_INSET) * _displayRatio;
  CGFloat preloadDimension   = (boundsSize.width - 2 * HORIZONTAL_INSET) * _preloadRatio;
  CGFloat visiblePoint       = 0;
  CGFloat displayPoint       = 0;
  CGFloat preloadPoint       = 0;
  
  BOOL displayLargerThanPreload = (_displayRatio == 1.0) ? YES : NO;
  
  if (ASScrollDirectionContainsLeft(_scrollDirection) || ASScrollDirectionContainsUp(_scrollDirection)) {
    
    if (displayLargerThanPreload) {
      visiblePoint        = (displayDimension - visibleDimension) * _leadingDisplayRatio;
      preloadPoint        = visiblePoint - (preloadDimension - visibleDimension) * _leadingpreloadRatio;
    } else {
      visiblePoint        = (preloadDimension - visibleDimension) * _leadingpreloadRatio;
      displayPoint        = visiblePoint - (displayDimension - visibleDimension) * _leadingDisplayRatio;
    }
  } else if (ASScrollDirectionContainsRight(_scrollDirection) || ASScrollDirectionContainsDown(_scrollDirection)) {
    
    if (displayLargerThanPreload) {
      visiblePoint        = (displayDimension - visibleDimension) * (1 - _leadingDisplayRatio);
      preloadPoint        = visiblePoint - (preloadDimension - visibleDimension) * (1 - _leadingpreloadRatio);
    } else {
      visiblePoint        = (preloadDimension - visibleDimension) * (1 - _leadingpreloadRatio);
      displayPoint        = visiblePoint - (displayDimension - visibleDimension) * (1 - _leadingDisplayRatio);
    }
  }
  
  BOOL animate = !_firstLayoutOfRects;
//  [UIView animateWithDuration:animate ? 0.3 : 0.0 delay:0.0 options:UIViewAnimationOptionLayoutSubviews animations:^{
    self->_visibleRect.frame    = CGRectMake(HORIZONTAL_INSET + visiblePoint,    rect.origin.y, visibleDimension,    subCellHeight);
    self->_displayRect.frame    = CGRectMake(HORIZONTAL_INSET + displayPoint,    rect.origin.y, displayDimension,    subCellHeight);
    self->_preloadRect.frame    = CGRectMake(HORIZONTAL_INSET + preloadPoint,  rect.origin.y, preloadDimension,  subCellHeight);
//  } completion:^(BOOL finished) {}];
  
  if (!animate) {
    _visibleRect.alpha = _displayRect.alpha = _preloadRect.alpha = 0;
//    [UIView animateWithDuration:0.3 animations:^{
      self->_visibleRect.alpha = self->_displayRect.alpha = self->_preloadRect.alpha = 1;
//    }];
  }
  
  _firstLayoutOfRects = NO;
}

- (void)updateWithVisibleRatio:(CGFloat)visibleRatio
                  displayRatio:(CGFloat)displayRatio
           leadingDisplayRatio:(CGFloat)leadingDisplayRatio
                preloadRatio:(CGFloat)preloadRatio
         leadingpreloadRatio:(CGFloat)leadingpreloadRatio
                     direction:(ASScrollDirection)scrollDirection
{
  _visibleRatio          = visibleRatio;
  _displayRatio          = displayRatio;
  _leadingDisplayRatio   = leadingDisplayRatio;
  _preloadRatio          = preloadRatio;
  _leadingpreloadRatio   = leadingpreloadRatio;
  _scrollDirection       = scrollDirection;
  
  [self needsLayout];
}

- (void)setBarSubviewOrder
{
//  if (_preloadRatio == 1.0) {
//    [self sendSubviewToBack:_preloadRect.view];
//  } else {
//    [self sendSubviewToBack:_displayRect.view];
//  }
//  
//  [self bringSubviewToFront:_visibleRect.view];
}

- (void)setBarDebugLabelsWithSize:(CGFloat)size
{
  if (!_debugString) {
    _debugString = [[_rangeController dataSource] nameForRangeControllerDataSource];
  }
  if (_debugString) {
    _debugText.attributedText = [_ASRangeDebugBarView whiteAttributedStringFromString:_debugString withSize:size];
  }
  
  if (ASScrollDirectionContainsVerticalDirection(_scrollDirection)) {
    _leftDebugText.attributedText = [_ASRangeDebugBarView whiteAttributedStringFromString:@"▲" withSize:size];
    _rightDebugText.attributedText = [_ASRangeDebugBarView whiteAttributedStringFromString:@"▼" withSize:size];
  } else if (ASScrollDirectionContainsHorizontalDirection(_scrollDirection)) {
    _leftDebugText.attributedText = [_ASRangeDebugBarView whiteAttributedStringFromString:@"◀︎" withSize:size];
    _rightDebugText.attributedText = [_ASRangeDebugBarView whiteAttributedStringFromString:@"▶︎" withSize:size];
  }
  
  _leftDebugText.hidden = (_scrollDirection != ASScrollDirectionLeft && _scrollDirection != ASScrollDirectionUp);
  _rightDebugText.hidden = (_scrollDirection != ASScrollDirectionRight && _scrollDirection != ASScrollDirectionDown);
}

- (ASTextNode *)createDebugTextNode
{
  ASTextNode *label = [[ASTextNode alloc] init];
  [self addSubnode:label];
  return label;
}

#define RANGE_BAR_CORNER_RADIUS 3
#define RANGE_BAR_BORDER_WIDTH 1
- (ASImageNode *)createRangeNodeWithColor:(NSColor *)color
{
    ASImageNode *rangeBarImageNode = [[ASImageNode alloc] init];
//    ASPrimitiveTraitCollection primitiveTraitCollection = ASPrimitiveTraitCollectionFromUITraitCollection(self.traitCollection);
//    rangeBarImageNode.image = [NSImage as_resizableRoundedImageWithCornerRadius:RANGE_BAR_CORNER_RADIUS
//                                                                    cornerColor:[NSColor clearColor]
//                                                                      fillColor:[color colorWithAlphaComponent:0.5]
//                                                                    borderColor:[[NSColor blackColor] colorWithAlphaComponent:0.9]
//                                                                    borderWidth:RANGE_BAR_BORDER_WIDTH
//                                                                 roundedCorners:kCALayerMinXMinYCorner
//                                                                          scale:[[NSScreen mainScreen] backingScaleFactor]
//                                                                traitCollection:primitiveTraitCollection];
    [self addSubnode:rangeBarImageNode];
  
    return rangeBarImageNode;
}

+ (NSAttributedString *)whiteAttributedStringFromString:(NSString *)string withSize:(CGFloat)size NS_RETURNS_RETAINED
{
  NSDictionary *attributes = @{NSForegroundColorAttributeName : [NSColor whiteColor],
                               NSFontAttributeName            : [NSFont systemFontOfSize:size]};
  return [[NSAttributedString alloc] initWithString:string attributes:attributes];
}

@end
