//
//  VideoOverlayView.h
//  SamplePlayVideo
//
//  Created by quanght2 on 9/1/16.
//  Copyright © 2016 VngCorp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVPlayerLayerView.h"

@protocol VideoOverlayViewDelegate <NSObject>

- (void)removeVideOverlay;

@end

@interface VideoOverlayView : UIView

- (void)expandVideoViewFrom:(CGRect)fromRect to:(CGRect)toRect withPlayItem:(AVPlayerItem *)playerItem;
- (void)playWith:(AVPlayerItem *)playerItem;

@property (nonatomic, weak)id<VideoOverlayViewDelegate>delegate;

@end
