//
//  ASButtonNode+Private.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASButtonNode.h"
#import "ASTextNode.h"
#import "ASImageNode.h"
#import "ASStackLayoutDefines.h"

@interface ASButtonNode () {
  NSAttributedString *_normalAttributedTitle;
  NSAttributedString *_highlightedAttributedTitle;
  NSAttributedString *_selectedAttributedTitle;
  NSAttributedString *_selectedHighlightedAttributedTitle;
  NSAttributedString *_disabledAttributedTitle;

  NSImage *_normalImage;
  NSImage *_highlightedImage;
  NSImage *_selectedImage;
  NSImage *_selectedHighlightedImage;
  NSImage *_disabledImage;

  NSImage *_normalBackgroundImage;
  NSImage *_highlightedBackgroundImage;
  NSImage *_selectedBackgroundImage;
  NSImage *_selectedHighlightedBackgroundImage;
  NSImage *_disabledBackgroundImage;

  CGFloat _contentSpacing;
  NSEdgeInsets _contentEdgeInsets;
  ASTextNode *_titleNode;
  ASImageNode *_imageNode;
  ASImageNode *_backgroundImageNode;

  BOOL _laysOutHorizontally;
  ASVerticalAlignment _contentVerticalAlignment;
  ASHorizontalAlignment _contentHorizontalAlignment;
  ASButtonNodeImageAlignment _imageAlignment;
}

@end
