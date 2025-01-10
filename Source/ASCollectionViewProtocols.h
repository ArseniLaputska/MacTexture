//
//  ASCollectionViewProtocols.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AppKit/AppKit.h>
#import "ASBaseDefines.h"

typedef NS_OPTIONS(unsigned short, ASCellLayoutMode) {
  /**
   * No options set. If cell layout mode is set to ASCellLayoutModeNone, the default values for
   * each flag listed below is used.
   */
  ASCellLayoutModeNone = 0,
  /**
   * If ASCellLayoutModeAlwaysSync is enabled it will cause the ASDataController to wait on the
   * background queue, and this ensures that any new / changed cells are in the hierarchy by the
   * very next CATransaction / frame draw.
   *
   * Note: Sync & Async flags force the behavior to be always one or the other, regardless of the
   * items. Default: If neither ASCellLayoutModeAlwaysSync or ASCellLayoutModeAlwaysAsync is set,
   * default behavior is synchronous when there are 0 or 1 ASCellNodes in the data source, and
   * asynchronous when there are 2 or more.
  */
  ASCellLayoutModeAlwaysSync = 1 << 1,                // Default OFF
  ASCellLayoutModeAlwaysAsync = 1 << 2,               // Default OFF
  ASCellLayoutModeForceIfNeeded = 1 << 3,             // Deprecated, default OFF.
  ASCellLayoutModeAlwaysPassthroughDelegate = 1 << 4, // Deprecated, default ON.
  /** Instead of using performBatchUpdates: prefer using reloadData for changes for collection view */
  ASCellLayoutModeAlwaysReloadData = 1 << 5,          // Default OFF
  /** If flag is enabled nodes are *not* gonna be range managed. */
  ASCellLayoutModeDisableRangeController = 1 << 6,    // Default OFF
  ASCellLayoutModeAlwaysLazy = 1 << 7,                // Deprecated, default OFF.
  /**
   * Defines if the node creation should happen serialized and not in parallel within the
   * data controller
   */
  ASCellLayoutModeSerializeNodeCreation = 1 << 8,     // Default OFF
  /**
   * When set, the performBatchUpdates: API (including animation) is used when handling Section
   * Reload operations. This is useful only when ASCellLayoutModeAlwaysReloadData is enabled and
   * cell height animations are desired.
   */
  ASCellLayoutModeAlwaysBatchUpdateSectionReload = 1 << 9, // Default OFF
};

NS_ASSUME_NONNULL_BEGIN

/**
 * This is a subset of UICollectionViewDataSource.
 *
 * @see ASCollectionDataSource
 */
@protocol ASCommonCollectionDataSource <NSObject>

@optional

- (NSInteger)collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;

- (NSInteger)numberOfSectionsInCollectionView:(NSCollectionView *)collectionView;

- (NSView *)collectionView:(NSCollectionView *)collectionView
   viewForSupplementaryElementOfKind:(NSCollectionViewSupplementaryElementKind)kind
                     atIndexPath:(NSIndexPath *)indexPath;

@end


/**
 * This is a subset of UICollectionViewDelegate.
 *
 * @see ASCollectionDelegate
 */
@protocol ASCommonCollectionDelegate <NSObject>

@optional

- (NSCollectionViewTransitionLayout *)collectionView:(NSCollectionView *)collectionView
                     transitionLayoutForOldLayout:(NSCollectionViewLayout *)fromLayout
                                      newLayout:(NSCollectionViewLayout *)toLayout;

- (void)collectionView:(NSCollectionView *)collectionView
    willDisplaySupplementaryView:(NSView *)view
              forElementKind:(NSCollectionViewSupplementaryElementKind)elementKind
                 atIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(NSCollectionView *)collectionView
  didEndDisplayingSupplementaryView:(NSView *)view
                   forElementOfKind:(NSCollectionViewSupplementaryElementKind)elementKind
                        atIndexPath:(NSIndexPath *)indexPath;

/**
 * Called when an item is about to be highlighted, or was just highlighted/unhighlighted, etc.
 * The iOS code: shouldHighlightItemAtIndexPath, didHighlightItemAtIndexPath, etc.
 */
- (BOOL)collectionView:(NSCollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(NSCollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(NSCollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Called when an item is about to be selected / was selected, etc.
 */
- (BOOL)collectionView:(NSCollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(NSCollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(NSCollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(NSCollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Context menu items? On macOS, we'd typically use -menuForEvent: or NSMenuDelegate.
 * For now we just remove or adapt the method stubs if needed.
 */

@end

NS_ASSUME_NONNULL_END
