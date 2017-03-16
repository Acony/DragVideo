//
//  AVPlayerLayerView.h
//  SampleDragVideo
//
//  Created by quanght2 on 8/31/16.
//  Copyright © 2016 VngCorp. All rights reserved.
//
//http://stackoverflow.com/questions/6548290/avplayerlayer-animates-frame-changes

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class AVPlayerLayerViewDelegate;

@protocol AVPlayerLayerViewDelegate <NSObject>

- (void)playVideo;
- (void)miniMum;

@end

@interface AVPlayerLayerView : UIView

@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) UIButton *btnPlay;
@property (nonatomic, strong) UILabel *lbTime;
@property (nonatomic, strong) UILabel *lbTimeRemain;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIButton *miniBtn;
@property (nonatomic, strong) UIButton *btnMinimize;

@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@property (nonatomic, weak) id<AVPlayerLayerViewDelegate> delegate;


- (void)initSubViews:(CGRect)frame;
- (void)hidenAllBtn;
- (void)showAllBtn;

- (void)showProgrees;
- (void)hideProgress;

@end
