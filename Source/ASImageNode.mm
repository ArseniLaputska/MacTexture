//
//  ASImageNode.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASImageNode.h"

#import <tgmath.h>

#import "_ASDisplayLayer.h"
#import "ASDisplayNode+FrameworkPrivate.h"
#import "ASDisplayNode+Subclasses.h"
#import "ASDisplayNodeExtras.h"
#import "ASGraphicsContext.h"
#import "ASLayout.h"
#import "ASTextNode.h"
#import "ASImageNode+AnimatedImagePrivate.h"
#import "ASImageNode+CGExtras.h"
#import "AsyncDisplayKit+Debug.h"
#import "ASInternalHelpers.h"
#import "ASEqualityHelpers.h"
#import "ASHashing.h"
#import "ASWeakMap.h"
#import "CoreGraphics+ASConvenience.h"
#import "NSImage+Resizable.h"

// TODO: It would be nice to remove this dependency; it's the only subclass using more than +FrameworkSubclasses.h
#import "ASDisplayNodeInternal.h"

typedef void (^ASImageNodeDrawParametersBlock)(ASWeakMapEntry *entry);

@interface ASImageNodeDrawParameters : NSObject {
@package
  NSImage *_image;
  BOOL _opaque;
  CGRect _bounds;
  CGFloat _contentsScale;
  NSColor *_backgroundColor;
  NSColor *_tintColor;
  NSViewContentMode _contentMode;
  BOOL _cropEnabled;
  BOOL _forceUpscaling;
  CGSize _forcedSize;
  CGRect _cropRect;
  CGRect _cropDisplayBounds;
  asimagenode_modification_block_t _imageModificationBlock;
  ASDisplayNodeContextModifier _willDisplayNodeContentWithRenderingContext;
  ASDisplayNodeContextModifier _didDisplayNodeContentWithRenderingContext;
  ASImageNodeDrawParametersBlock _didDrawBlock;
  ASPrimitiveTraitCollection _traitCollection;
}

@end

@implementation ASImageNodeDrawParameters

@end

/**
 * Contains all data that is needed to generate the content bitmap.
 */
@interface ASImageNodeContentsKey : NSObject

@property (nonatomic) NSImage *image;
@property CGSize backingSize;
@property CGRect imageDrawRect;
@property BOOL isOpaque;
@property (nonatomic, copy) NSColor *backgroundColor;
@property (nonatomic, copy) NSColor *tintColor;
@property (nonatomic) ASDisplayNodeContextModifier willDisplayNodeContentWithRenderingContext;
@property (nonatomic) ASDisplayNodeContextModifier didDisplayNodeContentWithRenderingContext;
@property (nonatomic) asimagenode_modification_block_t imageModificationBlock;
@property NSUserInterfaceStyleMac userInterfaceStyle;
@end

@implementation ASImageNodeContentsKey

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }

  // Optimization opportunity: The `isKindOfClass` call here could be avoided by not using the NSObject `isEqual:`
  // convention and instead using a custom comparison function that assumes all items are heterogeneous.
  // However, profiling shows that our entire `isKindOfClass` expression is only ~1/40th of the total
  // overheard of our caching, so it's likely not high-impact.
  if ([object isKindOfClass:[ASImageNodeContentsKey class]]) {
    ASImageNodeContentsKey *other = (ASImageNodeContentsKey *)object;
    BOOL areKeysEqual = [_image isEqual:other.image]
      && CGSizeEqualToSize(_backingSize, other.backingSize)
      && CGRectEqualToRect(_imageDrawRect, other.imageDrawRect)
      && _isOpaque == other.isOpaque
      && [_backgroundColor isEqual:other.backgroundColor]
      && [_tintColor isEqual:other.tintColor]
      && _willDisplayNodeContentWithRenderingContext == other.willDisplayNodeContentWithRenderingContext
      && _didDisplayNodeContentWithRenderingContext == other.didDisplayNodeContentWithRenderingContext
      && _imageModificationBlock == other.imageModificationBlock;
    // iOS 12, tvOS 10 and later (userInterfaceStyle only available in iOS12+)
    areKeysEqual = areKeysEqual && _userInterfaceStyle == other.userInterfaceStyle;
    return areKeysEqual;
  } else {
    return NO;
  }
}

- (NSUInteger)hash
{
#pragma clang diagnostic push
#pragma clang diagnostic warning "-Wpadded"
  struct {
    NSUInteger imageHash;
    CGSize backingSize;
    CGRect imageDrawRect;
    NSInteger isOpaque;
    NSUInteger backgroundColorHash;
    NSUInteger tintColorHash;
    void *willDisplayNodeContentWithRenderingContext;
    void *didDisplayNodeContentWithRenderingContext;
    void *imageModificationBlock;
#pragma clang diagnostic pop
  } data = {
    _image.hash,
    _backingSize,
    _imageDrawRect,
    _isOpaque,
    _backgroundColor.hash,
    _tintColor.hash,
    (void *)_willDisplayNodeContentWithRenderingContext,
    (void *)_didDisplayNodeContentWithRenderingContext,
    (void *)_imageModificationBlock
  };
  return ASHashBytes(&data, sizeof(data));
}

@end

@implementation ASImageNode
{
@private
  NSImage *_image;
  ASWeakMapEntry *_weakCacheEntry;  // Holds a reference that keeps our contents in cache.
  NSColor *_placeholderColor;

  void (^_displayCompletionBlock)(BOOL canceled);

  // Drawing
  ASTextNode *_debugLabelNode;

  // Cropping.
  CGSize _forcedSize; //Defaults to CGSizeZero, indicating no forced size.
  CGRect _cropRect; // Defaults to CGRectMake(0.5, 0.5, 0, 0)
  CGRect _cropDisplayBounds; // Defaults to CGRectNull
}

@synthesize image = _image;
@synthesize imageModificationBlock = _imageModificationBlock;

#pragma mark - Lifecycle

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;

  // TODO can this be removed?
  self.contentsScale = ASScreenScale();
  self.contentMode = NSViewContentModeScaleAspectFill;
  self.opaque = NO;
  self.clipsToBounds = YES;

  // If no backgroundColor is set to the image node and it's a subview of UITableViewCell, UITableView is setting
  // the opaque value of all subviews to YES if highlighting / selection is happening and does not set it back to the
  // initial value. With setting a explicit backgroundColor we can prevent that change.
  self.backgroundColor = [NSColor clearColor];

  _imageNodeFlags.cropEnabled = YES;
  _imageNodeFlags.forceUpscaling = NO;
  _imageNodeFlags.regenerateFromImageAsset = NO;
  _cropRect = CGRectMake(0.5, 0.5, 0, 0);
  _cropDisplayBounds = CGRectNull;
  _placeholderColor = ASDisplayNodeDefaultPlaceholderColor();
  _animatedImageRunLoopMode = ASAnimatedImageDefaultRunLoopMode;

  return self;
}

- (void)dealloc
{
  // Invalidate all components around animated images
  [self invalidateAnimatedImage];
}

#pragma mark - Placeholder

- (NSImage *)placeholderImage
{
  // FIXME: Replace this implementation with reusable CALayers that have .backgroundColor set.
  // This would completely eliminate the memory and performance cost of the backing store.
  CGSize size = self.calculatedSize;
  if ((size.width * size.height) < CGFLOAT_EPSILON) {
    return nil;
  }

  __instanceLock__.lock();
  ASPrimitiveTraitCollection tc = _primitiveTraitCollection;
  __instanceLock__.unlock();
  return ASGraphicsCreateImage(tc, size, NO, 1, nil, nil, ^{
    AS::MutexLocker l(__instanceLock__);
    [_placeholderColor setFill];
    NSRectFill(CGRectMake(0, 0, size.width, size.height));
  });
}

#pragma mark - Layout and Sizing

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
  const auto image = ASLockedSelf(_image);

  if (image == nil) {
    return [super calculateSizeThatFits:constrainedSize];
  }

  return image.size;
}

#pragma mark - Setter / Getter

- (void)setImage:(NSImage *)image
{
  AS::MutexLocker l(__instanceLock__);
  [self _locked_setImage:image];
}

- (void)_locked_setImage:(NSImage *)image
{
  DISABLED_ASAssertLocked(__instanceLock__);
  if (ASObjectIsEqual(_image, image)) {
    return;
  }

  _image = image;

  if (image != nil) {
    // We explicitly call setNeedsDisplay in this case, although we know setNeedsDisplay will be called with lock held.
    // Therefore we have to be careful in methods that are involved with setNeedsDisplay to not run into a deadlock
    [self setNeedsDisplay];

    // For debugging purposes we don't care about locking for now
    if ([ASImageNode shouldShowImageScalingOverlay] && _debugLabelNode == nil) {
      // do not use ASPerformBlockOnMainThread here, if it performs the block synchronously it will continue
      // holding the lock while calling addSubnode.
      dispatch_async(dispatch_get_main_queue(), ^{
        self->_debugLabelNode = [[ASTextNode alloc] init];
        self->_debugLabelNode.layerBacked = YES;
        [self addSubnode:self->_debugLabelNode];
      });
    }
  } else {
    self.contents = nil;
  }
}

- (NSImage *)image
{
  return ASLockedSelf(_image);
}

- (NSColor *)placeholderColor
{
  return ASLockedSelf(_placeholderColor);
}

- (void)setPlaceholderColor:(NSColor *)placeholderColor
{
  ASLockScopeSelf();
  if (ASCompareAssignCopy(_placeholderColor, placeholderColor)) {
    _flags.placeholderEnabled = (placeholderColor != nil);
  }
}

#pragma mark - Drawing

- (NSObject *)drawParametersForAsyncLayer:(_ASDisplayLayer *)layer
{
  ASImageNodeDrawParameters *drawParameters = [[ASImageNodeDrawParameters alloc] init];
  
  {
    ASLockScopeSelf();
    NSImage *drawImage = _image;
    if (_imageNodeFlags.regenerateFromImageAsset && drawImage != nil) {
      _imageNodeFlags.regenerateFromImageAsset = NO;
//      ASTraitCollection *tc = [UITraitCollection traitCollectionWithUserInterfaceStyle:_primitiveTraitCollection.userInterfaceStyle];
//      NSImage *generatedImage = [drawImage.image imageWithTraitCollection:tc];
//      if ( generatedImage != nil ) {
//        drawImage = generatedImage;
//      }
    }

    drawParameters->_image = drawImage;
    drawParameters->_contentsScale = _contentsScaleForDisplay;
    drawParameters->_cropEnabled = _imageNodeFlags.cropEnabled;
    drawParameters->_forceUpscaling = _imageNodeFlags.forceUpscaling;
    drawParameters->_forcedSize = _forcedSize;
    drawParameters->_cropRect = _cropRect;
    drawParameters->_cropDisplayBounds = _cropDisplayBounds;
    drawParameters->_imageModificationBlock = _imageModificationBlock;
    drawParameters->_willDisplayNodeContentWithRenderingContext = _willDisplayNodeContentWithRenderingContext;
    drawParameters->_didDisplayNodeContentWithRenderingContext = _didDisplayNodeContentWithRenderingContext;
    drawParameters->_traitCollection = _primitiveTraitCollection;

    // Hack for now to retain the weak entry that was created while this drawing happened
    drawParameters->_didDrawBlock = ^(ASWeakMapEntry *entry){
      ASLockScopeSelf();
      self->_weakCacheEntry = entry;
    };
  }
  
  // We need to unlock before we access the other accessor.
  // Especially tintColor because it needs to walk up the view hierarchy
  drawParameters->_bounds = [self threadSafeBounds];
  drawParameters->_opaque = self.opaque;
  drawParameters->_backgroundColor = self.backgroundColor;
  drawParameters->_contentMode = self.contentMode;
  drawParameters->_tintColor = self.tintColor;

  return drawParameters;
}

static inline bool NSEdgeInsetsEqualToEdgeInsets(NSEdgeInsets insets1, NSEdgeInsets insets2)
{
  return (insets1.top == insets2.top &&
          insets1.left == insets2.left &&
          insets1.bottom == insets2.bottom &&
          insets1.right == insets2.right);
}

+ (NSImage *)displayWithParameters:(id<NSObject>)parameter isCancelled:(NS_NOESCAPE asdisplaynode_iscancelled_block_t)isCancelled
{
  ASImageNodeDrawParameters *drawParameter = (ASImageNodeDrawParameters *)parameter;

  NSImage *image = drawParameter->_image;
  if (image == nil) {
    return nil;
  }

  CGRect drawParameterBounds       = drawParameter->_bounds;
  BOOL forceUpscaling              = drawParameter->_forceUpscaling;
  CGSize forcedSize                = drawParameter->_forcedSize;
  BOOL cropEnabled                 = drawParameter->_cropEnabled;
  BOOL isOpaque                    = drawParameter->_opaque;
  NSColor *backgroundColor         = drawParameter->_backgroundColor;
  NSColor *tintColor               = drawParameter->_tintColor;
  NSViewContentMode contentMode    = drawParameter->_contentMode;
  CGFloat contentsScale            = drawParameter->_contentsScale;
  CGRect cropDisplayBounds         = drawParameter->_cropDisplayBounds;
  CGRect cropRect                  = drawParameter->_cropRect;
  asimagenode_modification_block_t imageModificationBlock                 = drawParameter->_imageModificationBlock;
  ASDisplayNodeContextModifier willDisplayNodeContentWithRenderingContext = drawParameter->_willDisplayNodeContentWithRenderingContext;
  ASDisplayNodeContextModifier didDisplayNodeContentWithRenderingContext  = drawParameter->_didDisplayNodeContentWithRenderingContext;

  BOOL hasValidCropBounds = cropEnabled && !CGRectIsEmpty(cropDisplayBounds);
  CGRect bounds = (hasValidCropBounds ? cropDisplayBounds : drawParameterBounds);


  ASDisplayNodeAssert(contentsScale > 0, @"invalid contentsScale at display time");

  // if the image is resizable, bail early since the image has likely already been configured
  BOOL stretchable = !NSEdgeInsetsEqualToEdgeInsets(image.capInsets, NSEdgeInsetsZero);
  if (stretchable) {
    if (imageModificationBlock != NULL) {
      image = imageModificationBlock(image, drawParameter->_traitCollection);
    }
    return image;
  }

  CGSize imageSize = image.size;
  CGSize imageSizeInPixels = CGSizeMake(imageSize.width * drawParameter->_contentsScale, imageSize.height * drawParameter->_contentsScale);
  CGSize boundsSizeInPixels = CGSizeMake(std::floor(bounds.size.width * contentsScale), std::floor(bounds.size.height * contentsScale));

  BOOL contentModeSupported = contentMode == NSViewContentModeScaleAspectFill ||
                              contentMode == NSViewContentModeScaleAspectFit ||
                              contentMode == NSViewContentModeCenter;

  CGSize backingSize   = CGSizeZero;
  CGRect imageDrawRect = CGRectZero;

  if (boundsSizeInPixels.width * contentsScale < 1.0f || boundsSizeInPixels.height * contentsScale < 1.0f ||
      imageSizeInPixels.width < 1.0f                  || imageSizeInPixels.height < 1.0f) {
    return nil;
  }


  // If we're not supposed to do any cropping, just decode image at original size
  if (!cropEnabled || !contentModeSupported) {
    backingSize = imageSizeInPixels;
    imageDrawRect = (CGRect){.size = backingSize};
  } else {
    if (CGSizeEqualToSize(CGSizeZero, forcedSize) == NO) {
      //scale forced size
      forcedSize.width *= contentsScale;
      forcedSize.height *= contentsScale;
    }
//    ASCroppedImageBackingSizeAndDrawRectInBounds(imageSizeInPixels,
//                                                 boundsSizeInPixels,
//                                                 contentMode,
//                                                 cropRect,
//                                                 forceUpscaling,
//                                                 forcedSize,
//                                                 &backingSize,
//                                                 &imageDrawRect);
  }

  if (backingSize.width <= 0.0f        || backingSize.height <= 0.0f ||
      imageDrawRect.size.width <= 0.0f || imageDrawRect.size.height <= 0.0f) {
    return nil;
  }

  ASImageNodeContentsKey *contentsKey = [[ASImageNodeContentsKey alloc] init];
  contentsKey.image = image;
  contentsKey.backingSize = backingSize;
  contentsKey.imageDrawRect = imageDrawRect;
  contentsKey.isOpaque = isOpaque;
  contentsKey.backgroundColor = backgroundColor;
  contentsKey.tintColor = tintColor;
  contentsKey.willDisplayNodeContentWithRenderingContext = willDisplayNodeContentWithRenderingContext;
  contentsKey.didDisplayNodeContentWithRenderingContext = didDisplayNodeContentWithRenderingContext;
  contentsKey.imageModificationBlock = imageModificationBlock;
  contentsKey.userInterfaceStyle = drawParameter->_traitCollection.userInterfaceStyle;

  if (isCancelled()) {
    return nil;
  }

  ASWeakMapEntry<NSImage *> *entry = [self.class contentsForkey:contentsKey
                                                 drawParameters:parameter
                                                    isCancelled:isCancelled];
  // If nil, we were cancelled.
  if (entry == nil) {
    return nil;
  }

  if (drawParameter->_didDrawBlock) {
    drawParameter->_didDrawBlock(entry);
  }

  return entry.value;
}

static ASWeakMap<ASImageNodeContentsKey *, NSImage *> *cache = nil;

+ (ASWeakMapEntry *)contentsForkey:(ASImageNodeContentsKey *)key drawParameters:(id)drawParameters isCancelled:(asdisplaynode_iscancelled_block_t)isCancelled
{
  static dispatch_once_t onceToken;
  static AS::Mutex *cacheLock = nil;
  dispatch_once(&onceToken, ^{
    cacheLock = new AS::Mutex();
  });

  {
    AS::MutexLocker l(*cacheLock);
    if (!cache) {
      cache = [[ASWeakMap alloc] init];
    }
    ASWeakMapEntry *entry = [cache entryForKey:key];
    if (entry != nil) {
      return entry;
    }
  }

  // cache miss
  NSImage *contents = [self createContentsForkey:key drawParameters:drawParameters isCancelled:isCancelled];
  if (contents == nil) { // If nil, we were cancelled
    return nil;
  }

  {
    AS::MutexLocker l(*cacheLock);
    return [cache setObject:contents forKey:key];
  }
}

+ (NSImage *)createContentsForkey:(ASImageNodeContentsKey *)key drawParameters:(id)parameter isCancelled:(asdisplaynode_iscancelled_block_t)isCancelled
{
  // Проверка на отмену операции
      if (isCancelled()) {
          return nil;
      }
      
      ASImageNodeDrawParameters *drawParameters = (ASImageNodeDrawParameters *)parameter;
      
      // Используем contentsScale 1.0 и обрабатываем масштабирование в boundsSizeInPixels
      NSImage *result = ASGraphicsCreateImage(drawParameters->_traitCollection,
                                             key.backingSize,
                                             key.isOpaque,
                                             1.0,
                                             key.image,
                                             isCancelled,
                                             ^{
          BOOL contextIsClean = YES;
          
          // Получение текущего графического контекста в AppKit
          NSGraphicsContext *nsContext = [NSGraphicsContext currentContext];
          CGContextRef context = [nsContext CGContext];
          
          // Вызов модификатора до отображения содержимого
          if (context && key.willDisplayNodeContentWithRenderingContext) {
              key.willDisplayNodeContentWithRenderingContext(context, drawParameters);
              contextIsClean = NO;
          }
          
          // Если изображение непрозрачное, заполняем контекст фоновым цветом
          if (key.isOpaque && key.backgroundColor) {
              [key.backgroundColor setFill];
              NSRectFill(NSMakeRect(0, 0, key.backingSize.width, key.backingSize.height));
              contextIsClean = NO;
          }
          
          // Избегание проблем с потокобезопасностью при одновременном рисовании одного и того же изображения
          NSImage *image = key.image;
          CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nsContext hints:nil];
          BOOL canUseCopy = (contextIsClean || ASImageAlphaInfoIsOpaque(CGImageGetAlphaInfo(cgImage)));
          CGBlendMode blendMode = canUseCopy ? kCGBlendModeCopy : kCGBlendModeNormal;
          
          // Проверка, является ли изображение шаблоном
          BOOL isTemplateImage = [image isTemplate];
          if (isTemplateImage && key.tintColor) {
              [key.tintColor setFill];
          }
          
          // Синхронизация доступа к изображению
          @synchronized(image) {
              [image drawInRect:key.imageDrawRect
                       fromRect:NSZeroRect
                      operation:(NSCompositingOperation)blendMode
                       fraction:1.0];
          }
          
          // Вызов модификатора после отображения содержимого
          if (context && key.didDisplayNodeContentWithRenderingContext) {
              key.didDisplayNodeContentWithRenderingContext(context, drawParameters);
          }
      });
      
      // Если оригинальное изображение растягиваемое, сохраняем эту возможность
      NSImage *originalImage = key.image;
      if (!NSEdgeInsetsEqualToEdgeInsets(originalImage.capInsets, NSEdgeInsetsZero)) {
          result = [result resizableImageWithCapInsets:originalImage.capInsets
                                         resizingMode:originalImage.resizingMode];
      }
      
      // Применение дополнительного модификатора изображения, если он установлен
      if (key.imageModificationBlock) {
          result = key.imageModificationBlock(result, drawParameters->_traitCollection);
      }
      
      return result;
}

- (void)displayDidFinish
{
  [super displayDidFinish];

  __instanceLock__.lock();
    NSImage *image = _image;
    void (^displayCompletionBlock)(BOOL canceled) = _displayCompletionBlock;
    BOOL shouldPerformDisplayCompletionBlock = (image && displayCompletionBlock);

    // Clear the ivar now. The block is retained and will be executed shortly.
    if (shouldPerformDisplayCompletionBlock) {
      _displayCompletionBlock = nil;
    }

    BOOL hasDebugLabel = (_debugLabelNode != nil);
  __instanceLock__.unlock();

  // Update the debug label if necessary
  if (hasDebugLabel) {
    // For debugging purposes we don't care about locking for now
    CGSize imageSize = image.size;
    CGSize imageSizeInPixels = CGSizeMake(imageSize.width * 1, imageSize.height * 1);
    CGSize boundsSizeInPixels = CGSizeMake(std::floor(self.bounds.size.width * self.contentsScale), std::floor(self.bounds.size.height * self.contentsScale));
    CGFloat pixelCountRatio            = (imageSizeInPixels.width * imageSizeInPixels.height) / (boundsSizeInPixels.width * boundsSizeInPixels.height);
    if (pixelCountRatio != 1.0) {
      NSString *scaleString            = [NSString stringWithFormat:@"%.2fx", pixelCountRatio];
      _debugLabelNode.attributedText   = [[NSAttributedString alloc] initWithString:scaleString attributes:[self debugLabelAttributes]];
      _debugLabelNode.hidden           = NO;
    } else {
      _debugLabelNode.hidden           = YES;
      _debugLabelNode.attributedText   = nil;
    }
  }

  // If we've got a block to perform after displaying, do it.
  if (shouldPerformDisplayCompletionBlock) {
    displayCompletionBlock(NO);
  }
}

- (void)setNeedsDisplayWithCompletion:(void (^ _Nullable)(BOOL canceled))displayCompletionBlock
{
  if (self.displaySuspended) {
    if (displayCompletionBlock)
      displayCompletionBlock(YES);
    return;
  }

  // Stash the block and call-site queue. We'll invoke it in -displayDidFinish.
  {
    AS::MutexLocker l(__instanceLock__);
    if (_displayCompletionBlock != displayCompletionBlock) {
      _displayCompletionBlock = displayCompletionBlock;
    }
  }

  [self setNeedsDisplay];
}

- (void)_setNeedsDisplayOnTemplatedImages
{
  BOOL isTemplateImage = NO;
  {
    AS::MutexLocker l(__instanceLock__);
    isTemplateImage = _image.isTemplate;
  }

  if (isTemplateImage) {
    [self setNeedsDisplay];
  }
}

- (void)tintColorDidChange
{
  [super tintColorDidChange];

  [self _setNeedsDisplayOnTemplatedImages];
}

#pragma mark Interface State

- (void)didEnterHierarchy
{
  [super didEnterHierarchy];

  [self _setNeedsDisplayOnTemplatedImages];
}

- (void)clearContents
{
  [super clearContents];

  AS::MutexLocker l(__instanceLock__);
  _weakCacheEntry = nil;  // release contents from the cache.
}

#pragma mark - Cropping

- (BOOL)isCropEnabled
{
  AS::MutexLocker l(__instanceLock__);
  return _imageNodeFlags.cropEnabled;
}

- (void)setCropEnabled:(BOOL)cropEnabled
{
  [self setCropEnabled:cropEnabled recropImmediately:NO inBounds:self.bounds];
}

- (void)setCropEnabled:(BOOL)cropEnabled recropImmediately:(BOOL)recropImmediately inBounds:(CGRect)cropBounds
{
  __instanceLock__.lock();
  if (_imageNodeFlags.cropEnabled == cropEnabled) {
    __instanceLock__.unlock();
    return;
  }

  _imageNodeFlags.cropEnabled = cropEnabled;
  _cropDisplayBounds = cropBounds;

  NSImage *image = _image;
  __instanceLock__.unlock();

  // If we have an image to display, display it, respecting our recrop flag.
  if (image != nil) {
    ASPerformBlockOnMainThread(^{
      if (recropImmediately)
        [self displayImmediately];
      else
        [self setNeedsDisplay];
    });
  }
}

- (CGRect)cropRect
{
  AS::MutexLocker l(__instanceLock__);
  return _cropRect;
}

- (void)setCropRect:(CGRect)cropRect
{
  {
    AS::MutexLocker l(__instanceLock__);
    if (CGRectEqualToRect(_cropRect, cropRect)) {
      return;
    }

    _cropRect = cropRect;
  }

  // TODO: this logic needs to be updated to respect cropRect.
  CGSize boundsSize = self.bounds.size;
  CGSize imageSize = self.image.size;

  BOOL isCroppingImage = ((boundsSize.width < imageSize.width) || (boundsSize.height < imageSize.height));

  // Re-display if we need to.
  ASPerformBlockOnMainThread(^{
    if (self.nodeLoaded && self.contentMode == NSViewContentModeScaleAspectFill && isCroppingImage)
      [self setNeedsDisplay];
  });
}

- (BOOL)forceUpscaling
{
  AS::MutexLocker l(__instanceLock__);
  return _imageNodeFlags.forceUpscaling;
}

- (void)setForceUpscaling:(BOOL)forceUpscaling
{
  AS::MutexLocker l(__instanceLock__);
  _imageNodeFlags.forceUpscaling = forceUpscaling;
}

- (CGSize)forcedSize
{
  AS::MutexLocker l(__instanceLock__);
  return _forcedSize;
}

- (void)setForcedSize:(CGSize)forcedSize
{
  AS::MutexLocker l(__instanceLock__);
  _forcedSize = forcedSize;
}

- (asimagenode_modification_block_t)imageModificationBlock
{
  AS::MutexLocker l(__instanceLock__);
  return _imageModificationBlock;
}

- (void)setImageModificationBlock:(asimagenode_modification_block_t)imageModificationBlock
{
  AS::MutexLocker l(__instanceLock__);
  _imageModificationBlock = imageModificationBlock;
}

#pragma mark - Debug

- (void)layout
{
  [super layout];

  if (_debugLabelNode) {
    CGSize boundsSize        = self.bounds.size;
    CGSize debugLabelSize    = [_debugLabelNode layoutThatFits:ASSizeRangeMake(CGSizeZero, boundsSize)].size;
    CGPoint debugLabelOrigin = CGPointMake(boundsSize.width - debugLabelSize.width,
                                           boundsSize.height - debugLabelSize.height);
    _debugLabelNode.frame    = (CGRect) {debugLabelOrigin, debugLabelSize};
  }
}

- (NSDictionary *)debugLabelAttributes
{
  return @{
    NSFontAttributeName: [NSFont systemFontOfSize:15.0],
    NSForegroundColorAttributeName: [NSColor redColor]
  };
}

- (void)asyncTraitCollectionDidChangeWithPreviousTraitCollection:(ASPrimitiveTraitCollection)previousTraitCollection {
  [super asyncTraitCollectionDidChangeWithPreviousTraitCollection:previousTraitCollection];

  {
    AS::MutexLocker l(__instanceLock__);
      // update image if userInterfaceStyle was changed (dark mode)
      if (_image != nil
          && _primitiveTraitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle) {
        _imageNodeFlags.regenerateFromImageAsset = YES;
      }
  }
}


@end

#pragma mark - Extras

asimagenode_modification_block_t ASImageNodeRoundBorderModificationBlock(CGFloat borderWidth, NSColor *borderColor)
{
  return ^(NSImage *originalImage, ASPrimitiveTraitCollection traitCollection) {
    return ASGraphicsCreateImage(traitCollection, originalImage.size, NO, 1, originalImage, nil, ^{
      NSBezierPath *roundOutline = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0, 0, originalImage.size.width, originalImage.size.height)];

      // Make the image round
      [roundOutline setClip];

      // Draw the original image
      [originalImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];

      // Draw a border on top.
      if (borderWidth > 0.0) {
        [borderColor setStroke];
        [roundOutline setLineWidth:borderWidth];
        [roundOutline stroke];
      }
    });
  };
}

asimagenode_modification_block_t ASImageNodeTintColorModificationBlock(NSColor *color)
{
  return ^(NSImage *originalImage, ASPrimitiveTraitCollection traitCollection) {
    NSImage *modifiedImage = ASGraphicsCreateImage(traitCollection, originalImage.size, NO, 1, originalImage, nil, ^{
      // Set color and render template
      [color setFill];
      BOOL isTemplateImage = [originalImage isTemplate];
      NSImage *templateImage = isTemplateImage ? originalImage : [originalImage copy];
      [templateImage setTemplate:isTemplateImage]; // Ensure the image is treated as a template

      [templateImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];
    });

    // if the original image was stretchy, keep it stretchy
    if (!NSEdgeInsetsEqualToEdgeInsets(originalImage.capInsets, NSEdgeInsetsZero)) {
      modifiedImage = [modifiedImage resizableImageWithCapInsets:originalImage.capInsets resizingMode:originalImage.resizingMode];
    }

    return modifiedImage;
  };
}
