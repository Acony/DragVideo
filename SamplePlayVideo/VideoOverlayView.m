//
//  VideoOverlayView.m
//  SamplePlayVideo
//
//  Created by quanght2 on 9/1/16.
//  Copyright © 2016 VngCorp. All rights reserved.
//

#import "VideoOverlayView.h"
#import "CAAnimation+Blocks.h"
#import <POP/POP.h>

#define UIColorFromRGB(rgbValue, Alpha) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:Alpha]

#define kDuration       0.5f

#define marginX         5.f
#define marginY         [UIApplication sharedApplication].statusBarFrame.size.height

enum {
    TopLeft = 1,
    TopRight = 2,
    BotLeft = 3,
    BotRight = 4
};

typedef NSUInteger Position;

@interface VideoOverlayView() <AVPlayerLayerViewDelegate>

{
    // handle video
    AVPlayerLayerView *videoView;
    AVPlayer *avPlayer;
    AVPlayerItem *tempPlayerItem;
    
    UITapGestureRecognizer *tapRecognizer;
    
    // for size video
    CGFloat ratio;
    CGRect expandRect;
    CGSize screenSize;
    
    BOOL fullMode;
    BOOL isPause;
    
    NSObject *periodicTimeObserver;
    NSObject *playbackLikelyToKeepUpKVOToken;
    NSTimer *timer;
}
@property (nonatomic, assign) CGPoint startTouchPoint; // for drag video in full mode
@property (nonatomic, assign) CGPoint currentPoint; // for drag video in minimum mode
@property (nonatomic, assign) CGPoint firstPoint;


@end

@implementation VideoOverlayView

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        videoView = [[AVPlayerLayerView alloc]init];
        videoView.backgroundColor = [UIColor  blackColor];
        videoView.delegate = self;
        [self addSubview:videoView];
        
        // init gesture
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        [videoView addGestureRecognizer:panGesture];
        
        tapRecognizer= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandViewOnTap:)];
        tapRecognizer.numberOfTapsRequired=1;
        [videoView addGestureRecognizer:tapRecognizer];
        
        // init queue Video
        avPlayer = [[AVPlayer alloc]init];
        [avPlayer addObserver:self forKeyPath:@"rate" options:0 context:nil];
        videoView.playerLayer.player = avPlayer;
        
        __weak VideoOverlayView *weakSelf = self;
        if (periodicTimeObserver == nil){
            periodicTimeObserver = [videoView.playerLayer.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                
                [weakSelf updateSlider];
                
            }];
        }
        
        
        fullMode = YES;
        
        CGRect screenRect =  [UIScreen mainScreen].bounds;
        screenSize = CGSizeMake(screenRect.size.width, screenRect.size.height);
        
    }
    return self;
}

// allow all View under Video View receive Touch Event
// if we don't have it, we can't touch on any tableViewCell
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if (fullMode) {
        return hitView;
    }
    
    if (hitView == self) return nil;
    return hitView;
}

- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)recognizer

{
    if(recognizer.state == UIGestureRecognizerStateBegan) {
        
        _startTouchPoint = [recognizer locationInView:videoView];
        _currentPoint = [recognizer locationInView:self];
        _firstPoint = [recognizer locationInView:self];
        if (!fullMode) {

            POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
            positionAnimation.toValue = [NSValue valueWithCGPoint:videoView.center];
            [videoView.layer pop_addAnimation:positionAnimation forKey:@"layerPositionAnimation"];
            
            POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
            scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.1, 1.1)];
            scaleAnimation.springBounciness = 10.f;
            [videoView.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
            
        }
    }
    
    else if (recognizer.state == UIGestureRecognizerStateChanged) {

        if (fullMode) {
            
            [videoView hidenAllBtn];
            CGPoint movedPoint = [recognizer locationInView:self];
            
            CGFloat offsetY = movedPoint.y - _startTouchPoint.y;
            
            
            CGFloat offsetX = ABS(offsetY - expandRect.origin.y);
            if (offsetX > self.frame.size.width - 160) {
                offsetX = self.frame.size.width - 160;
            }
            CGFloat widthX =  self.frame.size.width - offsetX;
            
            CGRect frame =  videoView.frame;
            frame.origin.y = offsetY;
            frame.origin.x = offsetX;
            frame.size.width = widthX;
            frame.size.height =  frame.size.width * expandRect.size.height /expandRect.size.width;
            videoView.frame = frame;
            
            CGFloat minHeight = 160 *expandRect.size.height /expandRect.size.width;
            
            CGFloat centerHeight = self.frame.size.height/2;
            CGFloat alpha =  offsetX / (centerHeight - frame.size.height/2 - minHeight/2);
            
            self.backgroundColor = UIColorFromRGB(0X000000, 1 - alpha);
            
        } else {
            
            CGPoint movedPoint = [recognizer locationInView:self];
            
            CGFloat deltaX = movedPoint.x - _currentPoint.x;
            CGFloat deltaY = movedPoint.y - _currentPoint.y;
            [self _moveByDeltaX:deltaX deltaY:deltaY];
            _currentPoint = movedPoint;

        }

    }
    
    else if ( recognizer.state == UIGestureRecognizerStateEnded) {
        
        if (fullMode) {
            CGPoint point = [recognizer locationInView:self];
            fullMode = [self minimumVideoView:point];
            if (fullMode) {
                [UIView animateWithDuration:0.2 animations:^{
                    [videoView showAllBtn];
                }];
            }
        } else {
            
            // logic drag mini video
            // if velocity > 500 -->  animation dismis VideoView
            // else -> animation new location VideoView
            
            POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
            scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.0, 1.0)];
            scaleAnimation.springBounciness = 10.f;
            [videoView.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
            
            
            CGFloat velocityY = [recognizer velocityInView:self].y;
            CGFloat velocityX = [recognizer velocityInView:self].x;
            CGRect dismissFrame = CGRectZero;
            if (velocityY < -500) {
                
                CGPoint movedPoint = [recognizer locationInView:self];
                if (ABS(movedPoint.y - _firstPoint.y) > 100) {
                    
                    if (velocityX > 0) {
                        
                        dismissFrame = CGRectMake(self.frame.size.width - 160 - marginX, -videoView.frame.size.height, videoView.frame.size.width, videoView.frame.size.height);
                    } else {
                        dismissFrame = CGRectMake(marginX, -videoView.frame.size.height, videoView.frame.size.width, videoView.frame.size.height);
                    }

                }

            } else  if (velocityY > 500) {
                
                CGPoint movedPoint = [recognizer locationInView:self];
                if (ABS(movedPoint.y - _firstPoint.y) > 100) {
                    
                    if (velocityX > 0) {
                        
                        dismissFrame = CGRectMake(self.frame.size.width - 160 - marginX, self.frame.size.height, videoView.frame.size.width, videoView.frame.size.height);
                    } else {
                        dismissFrame = CGRectMake(marginX, self.frame.size.height,videoView.frame.size.width, videoView.frame.size.height);
                    }

                }

            }
            
            if (dismissFrame.size.width > 0) {
                
                [UIView animateWithDuration:kDuration/2 animations:^{
                    videoView.frame = dismissFrame;
                    self.backgroundColor = UIColorFromRGB(0X000000, 0 );
                } completion:^(BOOL finished) {
                    
                    [avPlayer pause];
                    [avPlayer.currentItem removeObserver:self forKeyPath:@"status"];
                    [avPlayer removeObserver:self forKeyPath:@"rate"];

                    [videoView removeFromSuperview];
                    videoView = nil;
                    if (self.delegate && [self.delegate respondsToSelector:@selector(removeVideOverlay)]) {
                        [self.delegate removeVideOverlay];
                    }
                    
                }];
                return;
            }

            
            Position pos = [self getPosition:videoView.center];
            CGPoint toPoint;
            CGFloat centerWidth =  videoView.frame.size.width/2;
            CGFloat centerHeight = videoView.frame.size.height/2;
            switch (pos) {
                case TopLeft:
                {
                    
                    toPoint = CGPointMake(marginX + centerWidth, marginY + centerHeight);

                    
                }
                    break;
                case TopRight:
                {
                    toPoint = CGPointMake(self.frame.size.width - marginX - centerWidth, marginY + centerHeight);
                }
                    break;
                case BotLeft:
                {
                    toPoint = CGPointMake(marginX + centerWidth, self.frame.size.height - marginY - centerHeight);
                }
                    break;
                case BotRight:
                {
                    toPoint = CGPointMake(self.frame.size.width - marginX - centerWidth, self.frame.size.height - marginY - centerHeight);
                }
                    break;
                    
                default:
                    break;
            }
            

            POPSpringAnimation *positionAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
            positionAnimation.toValue = [NSValue valueWithCGPoint:toPoint];
            positionAnimation.springBounciness = 10.f;

            [videoView.layer pop_addAnimation:positionAnimation forKey:@"layerPositionAnimation"];
      
            
        }
    }
}


- (void)updateSlider
{
    AVPlayerItem *currentItem = avPlayer.currentItem;
    CMTime duration = currentItem.duration; //total time
    CMTime currentTime = currentItem.currentTime; //playing time
    
    Float64 dur = CMTimeGetSeconds(duration);
    Float64 cur = CMTimeGetSeconds(currentTime);

    videoView.lbTime.text = [self getStringFormatFromSecond:cur];
    videoView.lbTimeRemain.text = [self getStringFormatFromSecond:(dur - cur)];
    videoView.slider.value =  cur;
}

- (IBAction)expandViewOnTap:(id)sender {
    
    
    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    scaleAnimation.toValue = [NSValue valueWithCGRect:expandRect];
    scaleAnimation.springBounciness = 10.f;
    [videoView.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
    
    fullMode = YES;
    
    [UIView animateWithDuration:kDuration animations:^{
        
        self.backgroundColor = UIColorFromRGB(0X000000, 1 );
        videoView.playerLayer.cornerRadius = 0.f;
        [videoView showAllBtn];
        
    }completion:NULL];
    
    [videoView.playerLayer.player play];
    
}

- (BOOL)minimumVideoView:(CGPoint)point
{

    if (ABS(videoView.center.y - self.frame.size.height/2) < 50) {
        
        // not minimum
        
        [self expandViewOnTap:NULL];
        
        return YES;
        
    } else {
        Position pos = [self getPosition:point];
        
        [self minimumVideoViewWithPosition:pos];
        
        return NO;
    }

}

- (void)minimumVideoViewWithPosition:(Position)position
{
    CGFloat width = 160;
    CGFloat height = 160 / ratio;
    CGFloat offsetX ;
    CGFloat offsetY ;
    switch (position) {
        case TopLeft:
        {
            offsetX =  0;
            offsetY = 0;
        }
            break;
            
        case TopRight:
        {
            offsetX =  self.frame.size.width - width - marginX;
            offsetY =  marginY;
        }
            break;
            
        case BotLeft:
        {
            offsetX =  0;
            offsetY = self.frame.size.height - height;
        }
            break;
            
        case BotRight:
        {
            offsetX =  self.frame.size.width - width - marginX;
            offsetY =  self.frame.size.height - height - marginY;
        }
            break;
            
        default:
            break;
    }
    
    [UIView animateWithDuration:kDuration/2 animations:^{
        self.backgroundColor = UIColorFromRGB(0X000000, 0 );
    }];
    
    
    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    scaleAnimation.toValue = [NSValue valueWithCGRect:CGRectMake(offsetX, offsetY, width, height)];
    scaleAnimation.springBounciness = 10.f;
    [videoView.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];

    videoView.playerLayer.cornerRadius = 5.f;
    [videoView.playerLayer setMasksToBounds:YES];
    
}

- (Position)getPosition:(CGPoint)point
{
    CGFloat width =  self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    if (fullMode) {

        if (point.y < height/2)
        {
            
            return TopRight;
            
        } else {
            
            return BotRight;
            
        }
        
    } else {
        
        if (point.y < height/2)
        {
            if (point.x < width/2) {
                return TopLeft;
            } else  {
                return TopRight;
            }
        } else {
            if (point.x < width/2) {
                return BotLeft;
            } else {
                return BotRight;
            }
        }
    }

}

// move Minimum video
- (void)_moveByDeltaX:(CGFloat)x deltaY:(CGFloat)y
{
    CGPoint center = videoView.center;
    center.x += x;
    center.y += y;
    videoView.center = center;
    
}

#pragma mark --
#pragma mark -- from .h file
- (void)expandVideoViewFrom:(CGRect)fromRect to:(CGRect)toRect withPlayItem:(AVPlayerItem *)playerItem
{
    
    expandRect =  toRect;
    ratio =  toRect.size.width / toRect.size.height;
    videoView.playerLayer.videoGravity = AVLayerVideoGravityResize;
    videoView.frame = fromRect;
    if (playerItem) {
        [avPlayer replaceCurrentItemWithPlayerItem:playerItem];
//        [avPlayer removeAllItems];
//        [quePlay insertItem:playerItem afterItem:nil];
        [avPlayer.currentItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    }
    
    videoView.frame = fromRect;
    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    scaleAnimation.toValue = [NSValue valueWithCGRect:toRect];
    scaleAnimation.springBounciness = 10.f;
    [videoView.layer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
    [scaleAnimation setCompletionBlock:^(POPAnimation *animation, BOOL result) {
    
        [videoView initSubViews:CGRectMake(0, 0, toRect.size.width, toRect.size.height)];
//        if (videoView.playerLayer.player.status == AVPlayerStatusUnknown || videoView.playerLayer.player.status == AVPlayerStatusFailed) {
        
            [videoView showProgrees];
//        }
        
    }];

}


- (void)playWith:(AVPlayerItem *)playerItem
{
    
    [videoView showProgrees];
    [avPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    tempPlayerItem = playerItem;
    [avPlayer replaceCurrentItemWithPlayerItem:playerItem];
    [avPlayer.currentItem addObserver:self forKeyPath:@"status" options:0 context:@"abc"];

}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    
    if ([object isKindOfClass:[AVPlayerItem class]]) {
        
        AVPlayerItem *playItem = (AVPlayerItem*)object;
        if ([keyPath isEqualToString:@"status"]) {
            if (playItem.status == AVPlayerItemStatusReadyToPlay) {
                
                NSString *temp = (__bridge NSString*)context;
                
                
                if (!temp) {
                    [UIView animateWithDuration:kDuration animations:^{
                        self.backgroundColor = UIColorFromRGB(0X000000, 1 );
                        
                    }completion:NULL];
                }
                [playItem seekToTime:kCMTimeZero];
                //            [quePlay.currentItem removeObserver:self forKeyPath:@"status"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [avPlayer play];
                    [videoView hideProgress];
                });
            }
            
            AVPlayerItem *currentItem = avPlayer.currentItem;
            CMTime duration = currentItem.duration; //total time
            Float64 dur = CMTimeGetSeconds(duration);
            
            videoView.slider.minimumValue = 0;
            videoView.slider.maximumValue = dur;
            
            [videoView.slider addTarget:self action:@selector(valueChangeSliderTimer:) forControlEvents:UIControlEventValueChanged];
            
        } else if (playItem.status == AVPlayerItemStatusReadyToPlay) {
            // something went wrong. player.error should contain some information
        }
        
        
    } else {
        
        if (avPlayer.rate > 0) {
            if (videoView.activityView.isAnimating) {
                [videoView hideProgress];
            }
            
        } else {
            //
            if (!isPause)
            {
                if (CMTimeGetSeconds(videoView.playerLayer.player.currentItem.duration) != CMTimeGetSeconds(videoView.playerLayer.player.currentItem.currentTime)) {
                    if (!timer) {
                        
                        timer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                                 target: self
                                                               selector:@selector(onTick:)                                          userInfo: nil repeats:NO];
                    }
                } else {
                    
                    [avPlayer seekToTime:kCMTimeZero];
                    
                }
                
            }
            
        }
    }
    
}

- (void)onTick:(NSTimer *)Timer {
    //do smth
    [avPlayer play];
    [timer invalidate];
    timer = nil;
}

- (NSString*)getStringFormatFromSecond:(int)duration
{
    int minutes = duration / 60;
    int seconds = duration % 60;
    
    NSString *time = [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
    return time;
}

#pragma mark --
#pragma mark --

- (void)miniMum
{
    [self minimumVideoViewWithPosition:BotRight];
}

- (void)playVideo
{
    if (avPlayer.rate == 0.0) {
        isPause = NO;
        [avPlayer play];
        
    } else {
        isPause = YES;
        [avPlayer pause];
        
    }
}

-(IBAction) valueChangeSliderTimer:(id)sender{
    [avPlayer pause];
//    isPlaying = FALSE;
    
    float timeInSecond = videoView.slider.value;
    
    timeInSecond *= 1000;
    CMTime cmTime = CMTimeMake(timeInSecond, 1000);

    [avPlayer seekToTime:cmTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];

    if (!videoView.activityView.isAnimating) {
        [videoView showProgrees];
    }

}

@end
