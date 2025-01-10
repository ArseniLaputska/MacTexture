//
//  ASTableLayoutController.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTableLayoutController.h"

#import <AppKit/AppKit.h>

#import "ASAssert.h"
#import "ASElementMap.h"

@interface ASTableLayoutController()
@end

@implementation ASTableLayoutController

- (instancetype)initWithTableView:(NSTableView *)tableView
{
  if (!(self = [super init])) {
    return nil;
  }
  _tableView = tableView;
  return self;
}

#pragma mark - ASLayoutController

- (NSHashTable<ASCollectionElement *> *)elementsForScrolling:(ASScrollDirection)scrollDirection rangeMode:(ASLayoutRangeMode)rangeMode rangeType:(ASLayoutRangeType)rangeType map:(ASElementMap *)map
{
  CGRect bounds = _tableView.bounds;

  ASRangeTuningParameters tuningParameters = [self tuningParametersForRangeMode:rangeMode rangeType:rangeType];
  CGRect rangeBounds = CGRectExpandToRangeWithScrollableDirections(bounds, tuningParameters, ASScrollDirectionVerticalDirections, scrollDirection);
  NSArray *array = [self rowsInRect:rangeBounds forTableView:_tableView];
  return ASPointerTableByFlatMapping(array, NSIndexPath *indexPath, [map elementForItemAtIndexPath:indexPath]);
}

- (void)allElementsForScrolling:(ASScrollDirection)scrollDirection rangeMode:(ASLayoutRangeMode)rangeMode displaySet:(NSHashTable<ASCollectionElement *> *__autoreleasing  _Nullable *)displaySet preloadSet:(NSHashTable<ASCollectionElement *> *__autoreleasing  _Nullable *)preloadSet map:(ASElementMap *)map
{
  if (displaySet == NULL || preloadSet == NULL) {
    return;
  }

  *displaySet = [self elementsForScrolling:scrollDirection rangeMode:rangeMode rangeType:ASLayoutRangeTypeDisplay map:map];
  *preloadSet = [self elementsForScrolling:scrollDirection rangeMode:rangeMode rangeType:ASLayoutRangeTypePreload map:map];
  return;
}

- (NSArray<NSNumber *> *)rowsInRect:(NSRect)rangeBounds forTableView:(NSTableView *)tableView {
  NSMutableArray<NSNumber *> *visibleRows = [NSMutableArray array];
  
  // Найти видимый прямоугольник таблицы
  NSRect visibleRect = [tableView visibleRect];
  NSInteger firstVisibleRow = [tableView rowAtPoint:visibleRect.origin];
  NSInteger lastVisibleRow = [tableView rowAtPoint:NSMakePoint(NSMinX(visibleRect), NSMaxY(visibleRect))];
  
  // Проверить строки в диапазоне
  for (NSInteger row = firstVisibleRow; row <= lastVisibleRow; row++) {
    NSRect rowRect = [tableView rectOfRow:row];
    
    // Проверяем пересечение строки с rangeBounds
    if (NSIntersectsRect(rowRect, rangeBounds)) {
      [visibleRows addObject:@(row)];
    }
  }
  
  return visibleRows;
}

@end
