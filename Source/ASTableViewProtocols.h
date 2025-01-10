//
//  ASTableViewProtocols.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASBaseDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * This is a subset of UITableViewDataSource.
 *
 * @see ASTableDataSource
 */
@protocol ASCommonTableDataSource <NSObject>

@optional

- (NSInteger)tableView:(NSTableView *)tableView numberOfRowsInSection:(NSInteger)section ASDISPLAYNODE_DEPRECATED_MSG("Implement -tableNode:numberOfRowsInSection: instead.");

- (NSInteger)numberOfSectionsInTableView:(NSTableView *)tableView ASDISPLAYNODE_DEPRECATED_MSG("Implement numberOfSectionsInTableNode: instead.");

- (nullable NSString *)tableView:(NSTableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (nullable NSString *)tableView:(NSTableView *)tableView titleForFooterInSection:(NSInteger)section;

- (BOOL)tableView:(NSTableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)tableView:(NSTableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;

- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(NSTableView *)tableView;
- (NSInteger)tableView:(NSTableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;

- (void)tableView:(NSTableView *)tableView commitEditingStyle:(NSInteger)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(NSTableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end


/**
 * This is a subset of UITableViewDelegate.
 *
 * @see ASTableDelegate
 */
@protocol ASCommonTableViewDelegate <NSObject, NSTableViewDelegate>

@optional

/**
 * iOS: willDisplayHeaderView, willDisplayFooterView, etc.
 * macOS: there's "headerView" for columns, not sections. So this is bridging logic only.
 */
- (void)tableView:(NSTableView *)tableView willDisplayHeaderView:(NSView *)view forSection:(NSInteger)section;
- (void)tableView:(NSTableView *)tableView willDisplayFooterView:(NSView *)view forSection:(NSInteger)section;
- (void)tableView:(NSTableView *)tableView didEndDisplayingHeaderView:(NSView *)view forSection:(NSInteger)section;
- (void)tableView:(NSTableView *)tableView didEndDisplayingFooterView:(NSView *)view forSection:(NSInteger)section;

/**
 * iOS: heightForHeaderInSection. macOS uses rowHeight or view-based table with own constraints.
 * We'll keep as bridging logic.
 */
- (CGFloat)tableView:(NSTableView *)tableView heightForHeaderInSection:(NSInteger)section;
- (CGFloat)tableView:(NSTableView *)tableView heightForFooterInSection:(NSInteger)section;

/**
 * iOS: viewForHeaderInSection. On macOS you might do tableView:viewForTableColumn:row: or
 * NSTableHeaderView. We'll keep bridging logic.
 */
- (nullable NSView *)tableView:(NSTableView *)tableView viewForHeaderInSection:(NSInteger)section;
- (nullable NSView *)tableView:(NSTableView *)tableView viewForFooterInSection:(NSInteger)section;

/**
 * iOS: accessoryButtonTappedForRowWithIndexPath -> Mac bridging stub
 */
- (void)tableView:(NSTableView *)tableView accessoryButtonTappedForRow:(NSInteger)row;

/**
 * iOS highlight / selection callbacks, bridging to macOS
 */
- (BOOL)tableView:(NSTableView *)tableView shouldHighlightRow:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView didHighlightRow:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView didUnhighlightRow:(NSInteger)row;

/**
 * iOS: willSelectRow, willDeselectRow, didSelectRow, didDeselectRow
 */
- (NSInteger)tableView:(NSTableView *)tableView willSelectRow:(NSInteger)row;
- (NSInteger)tableView:(NSTableView *)tableView willDeselectRow:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView didSelectRow:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView didDeselectRow:(NSInteger)row;

/**
 * iOS: editingStyleForRowAtIndexPath, titleForDeleteConfirmationButton...
 * macOS doesn't do that the same way. We'll keep bridging stubs.
 */
- (NSInteger)tableView:(NSTableView *)tableView editingStyleForRow:(NSInteger)row;
- (nullable NSString *)tableView:(NSTableView *)tableView titleForDeleteConfirmationButtonForRow:(NSInteger)row;

/**
 * iOS: indentationLevelForRowAtIndexPath -> macOS bridging
 */
- (NSInteger)tableView:(NSTableView *)tableView indentationLevelForRow:(NSInteger)row;

/**
 * iOS: targetIndexPathForMoveFromRowAtIndexPath -> bridging to macOS
 */
- (NSInteger)tableView:(NSTableView *)tableView targetIndexForMoveFromRow:(NSInteger)sourceRow toProposedIndex:(NSInteger)proposedIndex;

@end

NS_ASSUME_NONNULL_END
