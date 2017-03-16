//
//  VideoTableViewCell.m
//  SamplePlayVideo
//
//  Created by quanght2 on 9/1/16.
//  Copyright © 2016 VngCorp. All rights reserved.
//

#import "VideoTableViewCell.h"

@implementation VideoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)prepareForReuse
{
    self.imgThumb.hidden = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setActionExpandVideo:(ExpandVideo)expand
{
    self.expandBlock = expand;

}
- (IBAction)expandVideo:(id)sender {
    if (self.expandBlock) {
        self.expandBlock(TRUE);
    }
}

@end
