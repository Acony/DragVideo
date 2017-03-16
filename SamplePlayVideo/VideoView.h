//
//  VideoView.h
//  SampleDragVideo
//
//  Created by quanght2 on 8/30/16.
//  Copyright © 2016 VngCorp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoView : UIView

/**
 *  minimum Video
 *
 *  @param animation
 */
- (void)minimizeVideoView:(BOOL)animation;

/**
 *  full Video
 */
- (void)expandVideoView;


- (void)playVideo;

@end
