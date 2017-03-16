//
//  AVPlayerLayerView.m
//  SampleDragVideo
//
//  Created by quanght2 on 8/31/16.
//  Copyright © 2016 VngCorp. All rights reserved.
//

#import "AVPlayerLayerView.h"

#define HEIGHT                  30.f
#define WIDTH_LABEL             30.f

#define FONT_SIZE               12.f
#define margin_view_width       10.f

@implementation AVPlayerLayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

- (void)initSubViews:(CGRect)frame
{
    
    CGSize parentSize = frame.size;
    _btnPlay = [[UIButton alloc]init];
    CGRect btnPlayRect = CGRectMake(0, 0, WIDTH_LABEL, HEIGHT);
    btnPlayRect.origin.x = 0;
    btnPlayRect.origin.y = parentSize.height - HEIGHT;
    _btnPlay.frame = btnPlayRect;
    [_btnPlay setImage:[UIImage imageNamed:@"player_button_play_normal"] forState:UIControlStateNormal];
    [_btnPlay addTarget:self action:@selector(playTouch) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:_btnPlay];
    
    _lbTime = [[UILabel alloc]init];
    _lbTime.text = @"0:00";
    _lbTime.textColor = [UIColor whiteColor];
    _lbTime.font = [UIFont systemFontOfSize:FONT_SIZE];
    CGRect btnLbTimeRect = CGRectMake(0, 0, WIDTH_LABEL, HEIGHT);
    btnLbTimeRect.origin.y = parentSize.height - HEIGHT;
    btnLbTimeRect.origin.x =  btnPlayRect.origin.x +  btnPlayRect.size.width + margin_view_width;
    _lbTime.frame = btnLbTimeRect;
    
    [self addSubview:_lbTime];
    
    _slider = [[UISlider alloc]init];
    CGRect silderRect = CGRectMake(0, 0, frame.size.width - (WIDTH_LABEL+margin_view_width) *3, HEIGHT);
    silderRect.origin.y = parentSize.height - HEIGHT;
    silderRect.origin.x = btnLbTimeRect.origin.x + btnLbTimeRect.size.width;
    _slider.frame = silderRect;
    
    UIImage *sliderLeftTrackImage = [[UIImage imageNamed: @"player_slider_active"] stretchableImageWithLeftCapWidth: 9 topCapHeight: 0];
    UIImage *sliderRightTrackImage = [[UIImage imageNamed: @"player_slider_normal"] stretchableImageWithLeftCapWidth: 9 topCapHeight: 0];
    [_slider setMinimumTrackImage: sliderLeftTrackImage forState: UIControlStateNormal];
    [_slider setMaximumTrackImage: sliderRightTrackImage forState: UIControlStateNormal];
    [_slider setThumbImage:[UIImage imageNamed:@"player_slider_thumb"] forState:UIControlStateNormal];
    
    
    [self addSubview:_slider];
    
    _lbTimeRemain = [[UILabel alloc]init];
    _lbTimeRemain.text = @"0:00";
    _lbTimeRemain.textColor = [UIColor whiteColor];
    _lbTimeRemain.font = [UIFont systemFontOfSize:FONT_SIZE];
    CGRect lbTimeRemainRect = CGRectMake(0, 0, WIDTH_LABEL, HEIGHT);
    lbTimeRemainRect.origin.y = parentSize.height - HEIGHT;
    lbTimeRemainRect.origin.x =  silderRect.origin.x +  silderRect.size.width + margin_view_width;
    _lbTimeRemain.frame = lbTimeRemainRect;
    
    [self addSubview:_lbTimeRemain];
    
    
    _btnMinimize = [[UIButton alloc]init];
    CGRect btnMiniRect = CGRectMake(0, 0, WIDTH_LABEL, HEIGHT);
    btnMiniRect.origin.x = parentSize.width - WIDTH_LABEL;
    btnMiniRect.origin.y = 0;
    _btnMinimize.frame = btnMiniRect;
    [_btnMinimize setImage:[UIImage imageNamed:@"player_button_share_normal"] forState:UIControlStateNormal];
    [_btnMinimize addTarget:self action:@selector(minimizeTouch) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnMinimize];
    
}

- (void)minimizeTouch
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(miniMum)]) {
        [self.delegate miniMum];
    }
}

- (void)playTouch
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(playVideo)]) {
        [self.delegate playVideo];
    }
}

- (void)hidenAllBtn
{
   for (UIView *view in [self subviews])
   {
       if (![view isKindOfClass:[UIActivityIndicatorView class]]) {
           view.hidden = YES;
       }
   }
}

- (void)showAllBtn
{
    for (UIView *view in [self subviews])
    {
        if (![view isKindOfClass:[UIActivityIndicatorView class]]) {
            view.hidden = NO;
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _activityView.center = CGPointMake(self.bounds.size.width / 2.0f, self.bounds.size.height / 2.0f);

}

- (void)showProgrees
{
    dispatch_async(dispatch_get_main_queue(), ^{

        if (_activityView) {
            [_activityView removeFromSuperview];
            _activityView = nil;
        }
        
        _activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        _activityView.center = CGPointMake(self.bounds.size.width / 2.0f, self.bounds.size.height / 2.0f);
        [self addSubview:_activityView];
        [_activityView startAnimating];
    });
    
}

- (void)hideProgress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_activityView stopAnimating];
    });
    

}


@end
