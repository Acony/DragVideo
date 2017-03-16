//
//  VideoTableViewCell.h
//  SamplePlayVideo
//
//  Created by quanght2 on 9/1/16.
//  Copyright © 2016 VngCorp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVPlayerLayerView.h"
#import <AVFoundation/AVFoundation.h>


typedef void (^ExpandVideo) (BOOL isPlay);

@interface VideoTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgThumb;

@property (nonatomic, copy) ExpandVideo expandBlock;

- (void)setActionExpandVideo:(ExpandVideo)expand;
@end
