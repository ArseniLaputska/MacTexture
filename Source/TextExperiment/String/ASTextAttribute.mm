//
//  ASTextAttribute.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTextAttribute.h"
#import <CoreText/CoreText.h>
#import "NSAttributedString+ASText.h"

NSString *const ASTextBackedStringAttributeName = @"ASTextBackedString";
NSString *const ASTextBindingAttributeName = @"ASTextBinding";
NSString *const ASTextShadowAttributeName = @"ASTextShadow";
NSString *const ASTextInnerShadowAttributeName = @"ASTextInnerShadow";
NSString *const ASTextUnderlineAttributeName = @"ASTextUnderline";
NSString *const ASTextStrikethroughAttributeName = @"ASTextStrikethrough";
NSString *const ASTextBorderAttributeName = @"ASTextBorder";
NSString *const ASTextBackgroundBorderAttributeName = @"ASTextBackgroundBorder";
NSString *const ASTextBlockBorderAttributeName = @"ASTextBlockBorder";
NSString *const ASTextAttachmentAttributeName = @"ASTextAttachment";
NSString *const ASTextHighlightAttributeName = @"ASTextHighlight";
NSString *const ASTextGlyphTransformAttributeName = @"ASTextGlyphTransform";

NSString *const ASTextAttachmentToken = @"\uFFFC";
NSString *const ASTextTruncationToken = @"\u2026";


ASTextAttributeType ASTextAttributeGetType(NSString *name){
  if (name.length == 0) return ASTextAttributeTypeNone;
  
  static NSMutableDictionary *dic;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dic = [NSMutableDictionary new];
    NSNumber *All = @(ASTextAttributeTypeUIKit | ASTextAttributeTypeCoreText | ASTextAttributeTypeASText);
    NSNumber *CoreText_ASText = @(ASTextAttributeTypeCoreText | ASTextAttributeTypeASText);
    NSNumber *UIKit_ASText = @(ASTextAttributeTypeUIKit | ASTextAttributeTypeASText);
    NSNumber *UIKit_CoreText = @(ASTextAttributeTypeUIKit | ASTextAttributeTypeCoreText);
    NSNumber *UIKit = @(ASTextAttributeTypeUIKit);
    NSNumber *CoreText = @(ASTextAttributeTypeCoreText);
    NSNumber *ASText = @(ASTextAttributeTypeASText);
    
    dic[NSFontAttributeName] = All;
    dic[NSKernAttributeName] = All;
    dic[NSForegroundColorAttributeName] = UIKit;
    dic[(id)kCTForegroundColorAttributeName] = CoreText;
    dic[(id)kCTForegroundColorFromContextAttributeName] = CoreText;
    dic[NSBackgroundColorAttributeName] = UIKit;
    dic[NSStrokeWidthAttributeName] = All;
    dic[NSStrokeColorAttributeName] = UIKit;
    dic[(id)kCTStrokeColorAttributeName] = CoreText_ASText;
    dic[NSShadowAttributeName] = UIKit_ASText;
    dic[NSStrikethroughStyleAttributeName] = UIKit;
    dic[NSUnderlineStyleAttributeName] = UIKit_CoreText;
    dic[(id)kCTUnderlineColorAttributeName] = CoreText;
    dic[NSLigatureAttributeName] = All;
    dic[(id)kCTSuperscriptAttributeName] = UIKit; //it's a CoreText attrubite, but only supported by UIKit...
    dic[NSVerticalGlyphFormAttributeName] = All;
    dic[(id)kCTGlyphInfoAttributeName] = CoreText_ASText;
#if TARGET_OS_IOS
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    dic[(id)kCTCharacterShapeAttributeName] = CoreText_ASText;
#pragma clang diagnostic pop
#endif
    dic[(id)kCTRunDelegateAttributeName] = CoreText_ASText;
    dic[(id)kCTBaselineClassAttributeName] = CoreText_ASText;
    dic[(id)kCTBaselineInfoAttributeName] = CoreText_ASText;
    dic[(id)kCTBaselineReferenceInfoAttributeName] = CoreText_ASText;
    dic[(id)kCTWritingDirectionAttributeName] = CoreText_ASText;
    dic[NSParagraphStyleAttributeName] = All;
    
    dic[NSStrikethroughColorAttributeName] = UIKit;
    dic[NSUnderlineColorAttributeName] = UIKit;
    dic[NSTextEffectAttributeName] = UIKit;
    dic[NSObliquenessAttributeName] = UIKit;
    dic[NSExpansionAttributeName] = UIKit;
    dic[(id)kCTLanguageAttributeName] = CoreText_ASText;
    dic[NSBaselineOffsetAttributeName] = UIKit;
    dic[NSWritingDirectionAttributeName] = All;
    dic[NSAttachmentAttributeName] = UIKit;
    dic[NSLinkAttributeName] = UIKit;
    dic[(id)kCTRubyAnnotationAttributeName] = CoreText;
    
    dic[ASTextBackedStringAttributeName] = ASText;
    dic[ASTextBindingAttributeName] = ASText;
    dic[ASTextShadowAttributeName] = ASText;
    dic[ASTextInnerShadowAttributeName] = ASText;
    dic[ASTextUnderlineAttributeName] = ASText;
    dic[ASTextStrikethroughAttributeName] = ASText;
    dic[ASTextBorderAttributeName] = ASText;
    dic[ASTextBackgroundBorderAttributeName] = ASText;
    dic[ASTextBlockBorderAttributeName] = ASText;
    dic[ASTextAttachmentAttributeName] = ASText;
    dic[ASTextHighlightAttributeName] = ASText;
    dic[ASTextGlyphTransformAttributeName] = ASText;
  });
  NSNumber *num = dic[name];
  if (num) return num.integerValue;
  return ASTextAttributeTypeNone;
}


@implementation ASTextBackedString

+ (instancetype)stringWithString:(NSString *)string NS_RETURNS_RETAINED {
  ASTextBackedString *one = [self new];
  one.string = string;
  return one;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.string forKey:@"string"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  _string = [aDecoder decodeObjectForKey:@"string"];
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.string = self.string;
  return one;
}

@end


@implementation ASTextBinding

+ (instancetype)bindingWithDeleteConfirm:(BOOL)deleteConfirm NS_RETURNS_RETAINED {
  ASTextBinding *one = [self new];
  one.deleteConfirm = deleteConfirm;
  return one;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:@(self.deleteConfirm) forKey:@"deleteConfirm"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  _deleteConfirm = ((NSNumber *)[aDecoder decodeObjectForKey:@"deleteConfirm"]).boolValue;
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.deleteConfirm = self.deleteConfirm;
  return one;
}

@end


@implementation ASTextShadow

+ (instancetype)shadowWithColor:(NSColor *)color offset:(CGSize)offset radius:(CGFloat)radius NS_RETURNS_RETAINED {
  ASTextShadow *one = [self new];
  one.color = color;
  one.offset = offset;
  one.radius = radius;
  return one;
}

+ (instancetype)shadowWithNSShadow:(NSShadow *)nsShadow NS_RETURNS_RETAINED {
  if (!nsShadow) return nil;
  ASTextShadow *shadow = [self new];
  shadow.offset = nsShadow.shadowOffset;
  shadow.radius = nsShadow.shadowBlurRadius;
  id color = nsShadow.shadowColor;
  if (color) {
    if (CGColorGetTypeID() == CFGetTypeID((__bridge CFTypeRef)(color))) {
      color = [NSColor colorWithCGColor:(__bridge CGColorRef)(color)];
    }
    if ([color isKindOfClass:[NSColor class]]) {
      shadow.color = color;
    }
  }
  return shadow;
}

- (NSShadow *)nsShadow {
  NSShadow *shadow = [NSShadow new];
  shadow.shadowOffset = self.offset;
  shadow.shadowBlurRadius = self.radius;
  shadow.shadowColor = self.color;
  return shadow;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.color forKey:@"color"];
  [aCoder encodeObject:@(self.radius) forKey:@"radius"];
  [aCoder encodeObject:[NSValue valueWithSize:self.offset] forKey:@"offset"];
  [aCoder encodeObject:self.subShadow forKey:@"subShadow"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  _color = [aDecoder decodeObjectForKey:@"color"];
  _radius = ((NSNumber *)[aDecoder decodeObjectForKey:@"radius"]).floatValue;
  _offset = ((NSValue *)[aDecoder decodeObjectForKey:@"offset"]).sizeValue;
  _subShadow = [aDecoder decodeObjectForKey:@"subShadow"];
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.color = self.color;
  one.radius = self.radius;
  one.offset = self.offset;
  one.subShadow = self.subShadow.copy;
  return one;
}

@end


@implementation ASTextDecoration

- (instancetype)init {
  self = [super init];
  _style = ASTextLineStyleSingle;
  return self;
}

+ (instancetype)decorationWithStyle:(ASTextLineStyle)style NS_RETURNS_RETAINED {
  ASTextDecoration *one = [self new];
  one.style = style;
  return one;
}
+ (instancetype)decorationWithStyle:(ASTextLineStyle)style width:(NSNumber *)width color:(NSColor *)color NS_RETURNS_RETAINED {
  ASTextDecoration *one = [self new];
  one.style = style;
  one.width = width;
  one.color = color;
  return one;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:@(self.style) forKey:@"style"];
  [aCoder encodeObject:self.width forKey:@"width"];
  [aCoder encodeObject:self.color forKey:@"color"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  self.style = ((NSNumber *)[aDecoder decodeObjectForKey:@"style"]).unsignedIntegerValue;
  self.width = [aDecoder decodeObjectForKey:@"width"];
  self.color = [aDecoder decodeObjectForKey:@"color"];
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.style = self.style;
  one.width = self.width;
  one.color = self.color;
  return one;
}

@end


@implementation ASTextBorder

+ (instancetype)borderWithLineStyle:(ASTextLineStyle)lineStyle lineWidth:(CGFloat)width strokeColor:(NSColor *)color NS_RETURNS_RETAINED {
  ASTextBorder *one = [self new];
  one.lineStyle = lineStyle;
  one.strokeWidth = width;
  one.strokeColor = color;
  return one;
}

+ (instancetype)borderWithFillColor:(NSColor *)color cornerRadius:(CGFloat)cornerRadius NS_RETURNS_RETAINED {
  ASTextBorder *one = [self new];
  one.fillColor = color;
  one.cornerRadius = cornerRadius;
  one.insets = NSEdgeInsetsMake(-2, 0, 0, -2);
  return one;
}

- (instancetype)init {
  self = [super init];
  self.lineStyle = ASTextLineStyleSingle;
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:@(self.lineStyle) forKey:@"lineStyle"];
  [aCoder encodeObject:@(self.strokeWidth) forKey:@"strokeWidth"];
  [aCoder encodeObject:self.strokeColor forKey:@"strokeColor"];
  [aCoder encodeObject:@(self.lineJoin) forKey:@"lineJoin"];
  [aCoder encodeObject:[NSValue valueWithEdgeInsets:self.insets] forKey:@"insets"];
  [aCoder encodeObject:@(self.cornerRadius) forKey:@"cornerRadius"];
  [aCoder encodeObject:self.shadow forKey:@"shadow"];
  [aCoder encodeObject:self.fillColor forKey:@"fillColor"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  _lineStyle = ((NSNumber *)[aDecoder decodeObjectForKey:@"lineStyle"]).unsignedIntegerValue;
  _strokeWidth = ((NSNumber *)[aDecoder decodeObjectForKey:@"strokeWidth"]).doubleValue;
  _strokeColor = [aDecoder decodeObjectForKey:@"strokeColor"];
  _lineJoin = (CGLineJoin)((NSNumber *)[aDecoder decodeObjectForKey:@"join"]).unsignedIntegerValue;
  _insets = ((NSValue *)[aDecoder decodeObjectForKey:@"insets"]).edgeInsetsValue;
  _cornerRadius = ((NSNumber *)[aDecoder decodeObjectForKey:@"cornerRadius"]).doubleValue;
  _shadow = [aDecoder decodeObjectForKey:@"shadow"];
  _fillColor = [aDecoder decodeObjectForKey:@"fillColor"];
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.lineStyle = self.lineStyle;
  one.strokeWidth = self.strokeWidth;
  one.strokeColor = self.strokeColor;
  one.lineJoin = self.lineJoin;
  one.insets = self.insets;
  one.cornerRadius = self.cornerRadius;
  one.shadow = self.shadow.copy;
  one.fillColor = self.fillColor;
  return one;
}

@end


@implementation ASTextAttachment

+ (instancetype)attachmentWithContent:(id)content NS_RETURNS_RETAINED {
  ASTextAttachment *one = [self new];
  one.content = content;
  return one;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.content forKey:@"content"];
  [aCoder encodeObject:[NSValue valueWithEdgeInsets:self.contentInsets] forKey:@"contentInsets"];
  [aCoder encodeObject:self.userInfo forKey:@"userInfo"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  _content = [aDecoder decodeObjectForKey:@"content"];
  _contentInsets = ((NSValue *)[aDecoder decodeObjectForKey:@"contentInsets"]).edgeInsetsValue;
  _userInfo = [aDecoder decodeObjectForKey:@"userInfo"];
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  if ([self.content respondsToSelector:@selector(copy)]) {
    one.content = [self.content copy];
  } else {
    one.content = self.content;
  }
  one.contentInsets = self.contentInsets;
  one.userInfo = self.userInfo.copy;
  return one;
}

@end


@implementation ASTextHighlight

+ (instancetype)highlightWithAttributes:(NSDictionary *)attributes NS_RETURNS_RETAINED {
  ASTextHighlight *one = [self new];
  one.attributes = attributes;
  return one;
}

+ (instancetype)highlightWithBackgroundColor:(NSColor *)color NS_RETURNS_RETAINED {
  ASTextBorder *highlightBorder = [ASTextBorder new];
  highlightBorder.insets = NSEdgeInsetsMake(-2, -1, -2, -1);
  highlightBorder.cornerRadius = 3;
  highlightBorder.fillColor = color;
  
  ASTextHighlight *one = [self new];
  [one setBackgroundBorder:highlightBorder];
  return one;
}

- (void)setAttributes:(NSDictionary *)attributes {
  _attributes = attributes.mutableCopy;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.attributes = self.attributes.mutableCopy;
  return one;
}

- (void)_makeMutableAttributes {
  if (!_attributes) {
    _attributes = [NSMutableDictionary new];
  } else if (![_attributes isKindOfClass:[NSMutableDictionary class]]) {
    _attributes = _attributes.mutableCopy;
  }
}

- (void)setFont:(NSFont *)font {
  [self _makeMutableAttributes];
  if (font == (id)[NSNull null] || font == nil) {
    ((NSMutableDictionary *)_attributes)[(id)kCTFontAttributeName] = [NSNull null];
  } else {
    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    if (ctFont) {
      ((NSMutableDictionary *)_attributes)[(id)kCTFontAttributeName] = (__bridge id)(ctFont);
      CFRelease(ctFont);
    }
  }
}

- (void)setColor:(NSColor *)color {
  [self _makeMutableAttributes];
  if (color == (id)[NSNull null] || color == nil) {
    ((NSMutableDictionary *)_attributes)[(id)kCTForegroundColorAttributeName] = [NSNull null];
    ((NSMutableDictionary *)_attributes)[NSForegroundColorAttributeName] = [NSNull null];
  } else {
    ((NSMutableDictionary *)_attributes)[(id)kCTForegroundColorAttributeName] = (__bridge id)(color.CGColor);
    ((NSMutableDictionary *)_attributes)[NSForegroundColorAttributeName] = color;
  }
}

- (void)setStrokeWidth:(NSNumber *)width {
  [self _makeMutableAttributes];
  if (width == (id)[NSNull null] || width == nil) {
    ((NSMutableDictionary *)_attributes)[(id)kCTStrokeWidthAttributeName] = [NSNull null];
  } else {
    ((NSMutableDictionary *)_attributes)[(id)kCTStrokeWidthAttributeName] = width;
  }
}

- (void)setStrokeColor:(NSColor *)color {
  [self _makeMutableAttributes];
  if (color == (id)[NSNull null] || color == nil) {
    ((NSMutableDictionary *)_attributes)[(id)kCTStrokeColorAttributeName] = [NSNull null];
    ((NSMutableDictionary *)_attributes)[NSStrokeColorAttributeName] = [NSNull null];
  } else {
    ((NSMutableDictionary *)_attributes)[(id)kCTStrokeColorAttributeName] = (__bridge id)(color.CGColor);
    ((NSMutableDictionary *)_attributes)[NSStrokeColorAttributeName] = color;
  }
}

- (void)setTextAttribute:(NSString *)attribute value:(id)value {
  [self _makeMutableAttributes];
  if (value == nil) value = [NSNull null];
  ((NSMutableDictionary *)_attributes)[attribute] = value;
}

- (void)setShadow:(ASTextShadow *)shadow {
  [self setTextAttribute:ASTextShadowAttributeName value:shadow];
}

- (void)setInnerShadow:(ASTextShadow *)shadow {
  [self setTextAttribute:ASTextInnerShadowAttributeName value:shadow];
}

- (void)setUnderline:(ASTextDecoration *)underline {
  [self setTextAttribute:ASTextUnderlineAttributeName value:underline];
}

- (void)setStrikethrough:(ASTextDecoration *)strikethrough {
  [self setTextAttribute:ASTextStrikethroughAttributeName value:strikethrough];
}

- (void)setBackgroundBorder:(ASTextBorder *)border {
  [self setTextAttribute:ASTextBackgroundBorderAttributeName value:border];
}

- (void)setBorder:(ASTextBorder *)border {
  [self setTextAttribute:ASTextBorderAttributeName value:border];
}

- (void)setAttachment:(ASTextAttachment *)attachment {
  [self setTextAttribute:ASTextAttachmentAttributeName value:attachment];
}

@end

