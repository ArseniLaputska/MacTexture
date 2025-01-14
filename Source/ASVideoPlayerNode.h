//
//  ASVideoPlayerNode.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASAvailability.h"

#if AS_USE_VIDEO

#if TARGET_OS_IOS
#import <CoreMedia/CoreMedia.h>
#import "ASThread.h"
#import "ASVideoNode.h"
#import "ASDisplayNode+Subclasses.h"

@class AVAsset;
@class ASButtonNode;
@protocol ASVideoPlayerNodeDelegate;

typedef NS_ENUM(NSInteger, ASVideoPlayerNodeControlType) {
  ASVideoPlayerNodeControlTypePlaybackButton,
  ASVideoPlayerNodeControlTypeElapsedText,
  ASVideoPlayerNodeControlTypeDurationText,
  ASVideoPlayerNodeControlTypeScrubber,
  ASVideoPlayerNodeControlTypeFullScreenButton,
  ASVideoPlayerNodeControlTypeFlexGrowSpacer,
};

NS_ASSUME_NONNULL_BEGIN

@interface ASVideoPlayerNode : ASDisplayNode

@property (nullable, nonatomic, weak) id<ASVideoPlayerNodeDelegate> delegate;

@property (nonatomic, readonly) CMTime duration;

@property (nonatomic) BOOL controlsDisabled;

#pragma mark - ASVideoNode property proxy
/**
 * When shouldAutoplay is set to true, a video node will play when it has both loaded and entered the "visible" interfaceState.
 * If it leaves the visible interfaceState it will pause but will resume once it has returned.
 */
@property (nonatomic) BOOL shouldAutoPlay;
@property (nonatomic) BOOL shouldAutoRepeat;
@property (nonatomic) BOOL muted;
@property (nonatomic, readonly) ASVideoNodePlayerState playerState;
@property (nonatomic) BOOL shouldAggressivelyRecoverFromStall;
@property (nullable, nonatomic) NSURL *placeholderImageURL;

@property (nullable, nonatomic) AVAsset *asset;
/**
 ** @abstract The URL with which the asset was initialized.
 ** @discussion Setting the URL will override the current asset with a newly created AVURLAsset created from the given URL, and AVAsset *asset will point to that newly created AVURLAsset.  Please don't set both assetURL and asset.
 ** @return Current URL the asset was initialized or nil if no URL was given.
 **/
@property (nullable, nonatomic) NSURL *assetURL;

/// You should never set any value on the backing video node. Use exclusivively the video player node to set properties
@property (nonatomic, readonly) ASVideoNode *videoNode;

//! Defaults to 10000
@property (nonatomic) int32_t periodicTimeObserverTimescale;
//! Defaults to AVLayerVideoGravityResizeAspect
@property (nonatomic, copy) NSString *gravity;

#pragma mark - Lifecycle
- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithAsset:(AVAsset *)asset;
- (instancetype)initWithAsset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix;

#pragma mark - Public API
- (void)seekToTime:(CGFloat)percentComplete;
- (void)play;
- (void)pause;
- (BOOL)isPlaying;
- (void)resetToPlaceholder;

@end

#pragma mark - ASVideoPlayerNodeDelegate -
@protocol ASVideoPlayerNodeDelegate <NSObject>
@optional
/**
 * @abstract Delegate method invoked before creating controlbar controls
 * @param videoPlayer The sender
 */
- (NSArray *)videoPlayerNodeNeededDefaultControls:(ASVideoPlayerNode*)videoPlayer;

/**
 * @abstract Delegate method invoked before creating default controls, asks delegate for custom controls dictionary.
 * This dictionary must constain only ASDisplayNode subclass objects.
 * @param videoPlayer The sender
 * @discussion - This method is invoked only when developer implements videoPlayerNodeLayoutSpec:forControls:forMaximumSize:
 * and gives ability to add custom constrols to ASVideoPlayerNode, for example mute button.
 */
- (NSDictionary *)videoPlayerNodeCustomControls:(ASVideoPlayerNode*)videoPlayer;

/**
 * @abstract Delegate method invoked in layoutSpecThatFits:
 * @param videoPlayer The sender
 * @param controls - Dictionary of controls which are used in videoPlayer; Dictionary keys are ASVideoPlayerNodeControlType
 * @param maxSize - Maximum size for ASVideoPlayerNode
 * @discussion - Developer can layout whole ASVideoPlayerNode as he wants. ASVideoNode is locked and it can't be changed
 */
- (ASLayoutSpec *)videoPlayerNodeLayoutSpec:(ASVideoPlayerNode *)videoPlayer
                                forControls:(NSDictionary *)controls
                             forMaximumSize:(CGSize)maxSize;

#pragma mark Text delegate methods
/**
 * @abstract Delegate method invoked before creating ASVideoPlayerNodeControlTypeElapsedText and ASVideoPlayerNodeControlTypeDurationText
 * @param videoPlayer The sender
 * @param timeLabelType The of the time label
 */
- (NSDictionary *)videoPlayerNodeTimeLabelAttributes:(ASVideoPlayerNode *)videoPlayer timeLabelType:(ASVideoPlayerNodeControlType)timeLabelType;
- (NSString *)videoPlayerNode:(ASVideoPlayerNode *)videoPlayerNode
   timeStringForTimeLabelType:(ASVideoPlayerNodeControlType)timeLabelType
                      forTime:(CMTime)time;

#pragma mark Scrubber delegate methods
- (NSColor *)videoPlayerNodeScrubberMaximumTrackTint:(ASVideoPlayerNode *)videoPlayer;
- (NSColor *)videoPlayerNodeScrubberMinimumTrackTint:(ASVideoPlayerNode *)videoPlayer;
- (NSColor *)videoPlayerNodeScrubberThumbTint:(ASVideoPlayerNode *)videoPlayer;
- (NSImage *)videoPlayerNodeScrubberThumbImage:(ASVideoPlayerNode *)videoPlayer;

#pragma mark - Spinner delegate methods
- (NSColor *)videoPlayerNodeSpinnerTint:(ASVideoPlayerNode *)videoPlayer;
- (UIActivityIndicatorViewStyle)videoPlayerNodeSpinnerStyle:(ASVideoPlayerNode *)videoPlayer;

#pragma mark - Playback button delegate methods
- (NSColor *)videoPlayerNodePlaybackButtonTint:(ASVideoPlayerNode *)videoPlayer;

#pragma mark - Fullscreen button delegate methods

- (NSImage *)videoPlayerNodeFullScreenButtonImage:(ASVideoPlayerNode *)videoPlayer;


#pragma mark ASVideoNodeDelegate proxy methods
/**
 * @abstract Delegate method invoked when ASVideoPlayerNode is taped.
 * @param videoPlayer The ASVideoPlayerNode that was tapped.
 */
- (void)didTapVideoPlayerNode:(ASVideoPlayerNode *)videoPlayer;

/**
 * @abstract Delegate method invoked when fullcreen button is taped.
 * @param buttonNode The fullscreen button node that was tapped.
 */
- (void)didTapFullScreenButtonNode:(ASButtonNode *)buttonNode;

/**
 * @abstract Delegate method invoked when ASVideoNode playback time is updated.
 * @param videoPlayer The video player node
 * @param time current playback time.
 */
- (void)videoPlayerNode:(ASVideoPlayerNode *)videoPlayer didPlayToTime:(CMTime)time;

/**
 * @abstract Delegate method invoked when ASVideoNode changes state.
 * @param videoPlayer The ASVideoPlayerNode whose ASVideoNode is changing state.
 * @param state ASVideoNode state before this change.
 * @param toState ASVideoNode new state.
 * @discussion This method is called after each state change
 */
- (void)videoPlayerNode:(ASVideoPlayerNode *)videoPlayer willChangeVideoNodeState:(ASVideoNodePlayerState)state toVideoNodeState:(ASVideoNodePlayerState)toState;

/**
 * @abstract Delegate method is invoked when ASVideoNode decides to change state.
 * @param videoPlayer The ASVideoPlayerNode whose ASVideoNode is changing state.
 * @param state ASVideoNode that is going to be set.
 * @discussion Delegate method invoked when player changes it's state to
 * ASVideoNodePlayerStatePlaying or ASVideoNodePlayerStatePaused
 * and asks delegate if state change is valid
 */
- (BOOL)videoPlayerNode:(ASVideoPlayerNode*)videoPlayer shouldChangeVideoNodeStateTo:(ASVideoNodePlayerState)state;

/**
 * @abstract Delegate method invoked when the ASVideoNode has played to its end time.
 * @param videoPlayer The video node has played to its end time.
 */
- (void)videoPlayerNodeDidPlayToEnd:(ASVideoPlayerNode *)videoPlayer;

/**
 * @abstract Delegate method invoked when the ASVideoNode has constructed its AVPlayerItem for the asset.
 * @param videoPlayer The video player node.
 * @param currentItem The AVPlayerItem that was constructed from the asset.
 */
- (void)videoPlayerNode:(ASVideoPlayerNode *)videoPlayer didSetCurrentItem:(AVPlayerItem *)currentItem;

/**
 * @abstract Delegate method invoked when the ASVideoNode stalls.
 * @param videoPlayer The video player node that has experienced the stall
 * @param timeInterval Current playback time when the stall happens
 */
- (void)videoPlayerNode:(ASVideoPlayerNode *)videoPlayer didStallAtTimeInterval:(NSTimeInterval)timeInterval;

/**
 * @abstract Delegate method invoked when the ASVideoNode starts the inital asset loading
 * @param videoPlayer The videoPlayer
 */
- (void)videoPlayerNodeDidStartInitialLoading:(ASVideoPlayerNode *)videoPlayer;

/**
 * @abstract Delegate method invoked when the ASVideoNode is done loading the asset and can start the playback
 * @param videoPlayer The videoPlayer
 */
- (void)videoPlayerNodeDidFinishInitialLoading:(ASVideoPlayerNode *)videoPlayer;

/**
 * @abstract Delegate method invoked when the ASVideoNode has recovered from the stall
 * @param videoPlayer The videoplayer
 */
- (void)videoPlayerNodeDidRecoverFromStall:(ASVideoPlayerNode *)videoPlayer;


@end
NS_ASSUME_NONNULL_END
#endif  // TARGET_OS_IOS

#endif
