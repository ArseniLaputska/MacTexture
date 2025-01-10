//
//  _ASCollectionViewCell.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "_ASCollectionViewCell.h"
#import "ASDisplayNode+Subclasses.h"

#import "ASCellNode+Internal.h"
#import "ASCollectionElement.h"
#import "ASInternalHelpers.h"

@implementation _ASCollectionViewCell

- (ASCellNode *)node
{
  return self.element.node;
}

- (void)setElement:(ASCollectionElement *)element
{
  ASDisplayNodeAssertMainThread();
  ASCellNode *node = element.node;
  node.layoutAttributes = _layoutAttributes;
  _element = element;
  
  [node __setSelectedFromUIKit:self.selected];
  [node __setHighlightedFromUIKit:self.highlightState != 0];
}

- (BOOL)consumesCellNodeVisibilityEvents
{
  ASCellNode *node = self.node;
  if (node == nil) {
    return NO;
  }
  return ASSubclassOverridesSelector([ASCellNode class], [node class], @selector(cellNodeVisibilityEvent:inScrollView:withCellFrame:));
}

- (void)cellNodeVisibilityEvent:(ASCellNodeVisibilityEvent)event inScrollView:(NSScrollView *)scrollView
{
  [self.node cellNodeVisibilityEvent:event inScrollView:scrollView withCellFrame:self.view.frame];
}

- (void)setSelected:(BOOL)selected
{
  [super setSelected:selected];
  [self.node __setSelectedFromUIKit:selected];
}

- (void)setHighlightState:(NSCollectionViewItemHighlightState)highlighted
{
  [super setHighlightState:highlighted];
  [self.node __setHighlightedFromUIKit:highlighted != 0];
}

- (void)setLayoutAttributes:(NSCollectionViewLayoutAttributes *)layoutAttributes
{
  _layoutAttributes = layoutAttributes;
  self.node.layoutAttributes = layoutAttributes;
}

- (void)prepareForReuse
{
  self.layoutAttributes = nil;

  // Need to clear element before UIKit calls setSelected:NO / setHighlighted:NO on its cells
  self.element = nil;
  [super prepareForReuse];
}

/**
 * In the initial case, this is called by UICollectionView during cell dequeueing, before
 *   we get a chance to assign a node to it, so we must be sure to set these layout attributes
 *   on our node when one is next assigned to us in @c setNode: . Since there may be cases when we _do_ already
 *   have our node assigned e.g. during a layout update for existing cells, we also attempt
 *   to update it now.
 */
- (void)applyLayoutAttributes:(NSCollectionViewLayoutAttributes *)layoutAttributes
{
  [super applyLayoutAttributes:layoutAttributes];
  self.layoutAttributes = layoutAttributes;
}

/**
 * Keep our node filling our content view.
 */
- (void)viewDidLayout
{
  [super viewDidLayout];
  self.node.frame = self.view.bounds;
}

- (NSView *)hitTest:(CGPoint)point withEvent:(NSEvent *)event
{
  ASCellNode *node = self.node;
  NSView *nodeView = node.view;
  
  /**
   * The documentation for hitTest:withEvent: on an UIView explicitly states the fact that:
   * it ignores view objects that are hidden, that have disabled user interactions, or have an
   * alpha level less than 0.01.
   * To be able to determine if the collection view cell should skip going further down the tree
   * based on the states above we use a valid point within the cells bounds and check the
   * superclass hitTest:withEvent: implementation. If this returns a valid value we can go on with
   * checking the node as it's expected to not be in one of these states.
   */
  CGPoint originPointOnView = [self.view convertPoint:nodeView.bounds.origin fromView:nodeView];
  if (![super accessibilityHitTest:originPointOnView]) {
    return nil;
  }

  CGPoint pointOnNode = [node.view convertPoint:point fromView:self.view];
  return [node hitTest:pointOnNode];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(nullable NSEvent *)event
{
  CGPoint pointOnNode = [self.node.view convertPoint:point fromView:self.view];
  return [self.node pointInside:pointOnNode withEvent:event];
}

@end

/**
 * A category that makes _ASCollectionViewCell conform to IGListBindable.
 *
 * We don't need to do anything to bind the view model – the cell node
 * serves the same purpose.
 */
#if __has_include(<IGListKit/IGListBindable.h>)

#import <IGListKit/IGListBindable.h>

@interface _ASCollectionViewCell (IGListBindable) <IGListBindable>
@end

@implementation _ASCollectionViewCell (IGListBindable)

- (void)bindViewModel:(id)viewModel
{
  // nop
}

@end

#endif
