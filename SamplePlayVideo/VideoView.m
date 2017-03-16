//
//  VideoView.m
//  SampleDragVideo
//
//  Created by quanght2 on 8/30/16.
//  Copyright © 2016 VngCorp. All rights reserved.
//

#import "VideoView.h"

#import <AVFoundation/AVFoundation.h>
#import "AVPlayerLayerView.h"

#define CGPointIntegral(point) CGPointMake(point.x, point.y)

#define kmin_Width_Video         160
#define kmin_Heigh_Video         100
#define kAnimation               0.25

#define h_VideoRatio            2/5

#define w_View                  self.frame.size.width
#define h_View                  self.frame.size.height

@interface VideoView()<UIGestureRecognizerDelegate>

{
    
    //local touch location
    CGFloat _touchPositionInHeaderY;
    CGFloat _touchPositionInHeaderX;
    
    BOOL isFullVideoMode;
    
    // for play video
    AVPlayer *player;
    
    AVPlayerLayerView *videoView;
    
    UIView *parentGreenView;
    
    UITapGestureRecognizer *tapRecognizer;
    
    
    // for update change Position of Video
    // only need when isFullVideoMode = NO
    CGPoint currentPanPoint;
}

@end

@implementation VideoView

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
        
        videoView = [[AVPlayerLayerView alloc]initWithFrame:CGRectMake(0, 0, w_View, h_View * 2/5)];
        
        parentGreenView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, w_View, h_View)];
        
        videoView.backgroundColor = [UIColor clearColor];

        [self addSubview:parentGreenView];
        [self addSubview:videoView];
        
        [self addVideo];

        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        [videoView addGestureRecognizer:panGesture];
        
        isFullVideoMode = YES;

    }
    return self;
}

// allow all View under Video View receive Touch Event
// if we don't have it, we can't touch on any tableViewCell
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if (isFullVideoMode) {
        return hitView;
    }
    
    if (hitView == self) return nil;
    return hitView;
}

#pragma mark -- handle video
- (void)addVideo
{
//    NSURL *urlString = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"big_buck_bunny" ofType:@"mp4"]];
    NSURL *urlString = [NSURL URLWithString:@"http://techslides.com/demos/sample-videos/small.mp4"];
    
    player = [AVPlayer playerWithURL:urlString];
    videoView.playerLayer.player = player;
    videoView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
}

- (void)playVideo
{
    if (player) {
        [player seekToTime:kCMTimeZero];
        [player play];
    }
}

#pragma mark --
#pragma mark -- Pan Gesture Event

-(IBAction)handlePanGesture:(UIPanGestureRecognizer *)recognizer
{
    if(recognizer.state == UIGestureRecognizerStateBegan){
        _touchPositionInHeaderX = [recognizer locationInView:videoView].x;
        _touchPositionInHeaderY = [recognizer locationInView:videoView].y;
        currentPanPoint = [recognizer locationInView:self];
    }
    
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        if (isFullVideoMode) {
            
            CGFloat y = [recognizer locationInView:self].y;
            CGFloat offsetY  = y - _touchPositionInHeaderY;
            CGFloat offsetX = offsetY * 0.35;
            
            if (offsetX < 0 || offsetX > w_View - kmin_Width_Video || offsetY < 0 || offsetY > h_View - kmin_Heigh_Video) {
                return;
            }
            
            CGFloat w_VideoView = w_View - offsetX;
            
            CGFloat offsetY_Video = (1 -(w_VideoView/ w_View)) * h_View * 2/5;
            CGFloat h_VideoView = h_View * 2/5 - offsetY_Video;
            
            // update video frame
            CGRect videoFrame = CGRectMake(offsetX, offsetY, w_VideoView, h_VideoView);
            
            videoView.frame = videoFrame;

            // update green frame
            parentGreenView.frame = CGRectMake(offsetX, offsetY - offsetY_Video, w_View, h_View);
            
            // calculator alpha
            CGFloat alpha = y/ (self.frame.size.height - 150);
            alpha = alpha >=1? 1: alpha;
            parentGreenView.alpha =  1 - alpha;
            
        } else {
            
            CGPoint movedPoint =  [recognizer locationInView:self];

            CGFloat deltaX = movedPoint.x - currentPanPoint.x;
            CGFloat deltaY = movedPoint.y - currentPanPoint.y;
            [self _moveByDeltaX:deltaX deltaY:deltaY];
            
            currentPanPoint =  movedPoint;
        }
        

        
    } else if ( recognizer.state == UIGestureRecognizerStateEnded) {
        
        if (isFullVideoMode) {
            
            CGFloat y = [recognizer locationInView:self].y;
            
            if (y > h_View * 3/5) {
                [self minimizeVideoView:YES];
            } else {
                [self expandVideoView];
            }
        }
        
        [self playVideo];
    }
}

- (void)minimizeVideoView:(BOOL)animation
{
   
    CGFloat width = kmin_Width_Video;
    CGFloat height = kmin_Heigh_Video;
    
    CGFloat xPos = w_View - width;
    CGFloat yPos = h_View - height;
    
    CGFloat kDuration = animation ? kAnimation * 2 : 0;
    [UIView animateWithDuration:kDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         
                         videoView.frame = CGRectMake(xPos, yPos, width, height);
                         parentGreenView.frame = CGRectMake(xPos, yPos, width, h_View);
                         
                         
                     }
                     completion:^(BOOL finished) {
                         
                         isFullVideoMode= NO;
                         
                         // add Tap Gesture for Video View
                         tapRecognizer=nil;
                         if(tapRecognizer==nil)
                         {
                             tapRecognizer= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandViewOnTap:)];
                             tapRecognizer.numberOfTapsRequired=1;
                             tapRecognizer.delegate=self;
                             [videoView addGestureRecognizer:tapRecognizer];
                         }
                     }];
    
 
}

- (void)expandViewOnTap:(UITapGestureRecognizer*)sender {
    
    [self expandVideoView];
    for (UIGestureRecognizer *recognizer in videoView.gestureRecognizers) {
        
        if([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            [videoView removeGestureRecognizer:recognizer];
        }
    }
    
}

- (void)expandVideoView
{
    
    [UIView animateWithDuration:kAnimation
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         
                         videoView.frame = CGRectMake(0, 0, w_View, h_View * 2/5);
                         parentGreenView.frame = CGRectMake(0, 0, w_View ,h_View);
                         parentGreenView.alpha = 1.0;
                         
                     }
                     completion:^(BOOL finished) {
                         isFullVideoMode=TRUE;
                         
                     }];
    
    
    
}

#pragma mark --
#pragma mark -- Update Video Frame when drag in minimumMode

- (void)_moveByDeltaX:(CGFloat)x deltaY:(CGFloat)y
{

    CGPoint center = videoView.center;
    center.x += x;
    center.y += y;
    center = CGPointIntegral(center);
    center = [self updateValidPoint:center];
    videoView.center = center;
    
}

// if this point cause Video out of screen ->> fix this point
- (CGPoint)updateValidPoint:(CGPoint)center
{
    CGRect screenRect =  [UIScreen mainScreen].bounds;
    CGSize screenSize = CGSizeMake(screenRect.size.width, screenRect.size.height);
    CGSize size = videoView.frame.size;
    if (center.x + size.width/2 > screenSize.width)
    {
        center.x = screenSize.width - size.width/2;
        return center;
    }
    if (center.x - size.width/2 < 0) {
        center.x = size.width/2;
        return center;
    }
    if (center.y + size.height/2 > screenSize.height)
    {
        center.y = screenSize.height - size.height/2;
        return center;
    }
    if(center.y - size.height/2 < 0) {
        center.y = size.height/2;
        return center;
    }
    return center;
}


@end
