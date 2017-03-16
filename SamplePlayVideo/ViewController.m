//
//  ViewController.m
//  SamplePlayVideo
//
//  Created by quanght2 on 8/31/16.
//  Copyright © 2016 VngCorp. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "VideoView.h"
#import "VideoTableViewCell.h"
#import "CacheThumbVideo.h"
#import "VideoOverlayView.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource ,VideoOverlayViewDelegate>

{
    UITableView *mTableView;

}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    mTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    mTableView.delegate = self;
    mTableView.dataSource = self;
    
    [self.view addSubview:mTableView];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}



#pragma mark --
#pragma mark -- UITableViewDelegate



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 10;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return 110;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"VideoCell";
    
    VideoTableViewCell *cell = (VideoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"VideoTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    
    NSURL *urlString ;
    if (indexPath.row %2 == 0) {
//        urlString = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"big_buck_bunny" ofType:@"mp4"]];
//        urlString = [NSURL URLWithString:@"http://techslides.com/demos/sample-videos/small.mp4"];
        urlString = [NSURL URLWithString:@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"];

        
        
    } else {
//        urlString = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample" ofType:@"mp4"]];
//        urlString = [NSURL URLWithString:@"http://188.143.133.203/106.3/index.m3u8"];

        urlString = [NSURL URLWithString:@"http://www.quirksmode.org/html5/videos/big_buck_bunny.mp4"];


    }

    if ([[CacheThumbVideo sharedInstance] getThumbFromUrl:urlString.absoluteString]) {
        
        UIImage *img = [[CacheThumbVideo sharedInstance] getThumbFromUrl:urlString.absoluteString];
        cell.imgThumb.image = img;
    } else {
        
        AVAsset *asset = [AVAsset assetWithURL:urlString];
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
        CMTime time = CMTimeMake(1, 1);
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
        UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
        
        cell.imgThumb.image = thumbnail;
        if (thumbnail) {
            [[CacheThumbVideo sharedInstance] setThumb:thumbnail intoKey:urlString.absoluteString];
        }
    }
    
    __weak VideoTableViewCell *weakCell = cell;

    [cell setActionExpandVideo:^(BOOL isPlay) {
       
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        UIWindow *window = delegate.window;
        
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:urlString];

        VideoOverlayView * overlayView = [window viewWithTag:1000];
        if (overlayView == nil) {
            overlayView = [[VideoOverlayView alloc]initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
            
            overlayView.tag = 1000;
            [window addSubview:overlayView];
            overlayView.delegate = self;
            
            
            CGSize size = [[CacheThumbVideo sharedInstance]getSizeVideo:urlString.absoluteString];
            
            if (size.width == 0) {
                size.width = 560;
                size.height = 300;
            }
            CGFloat sizeHeight =  window.frame.size.width /size.width * size.height;
            CGRect fromFrame =  [weakCell.imgThumb convertRect:weakCell.imgThumb.bounds toView:window];
            
            CGRect toFrame = CGRectMake(0, (window.frame.size.height - sizeHeight)/2, window.frame.size.width, sizeHeight);
            
            [overlayView expandVideoViewFrom:fromFrame to:toFrame withPlayItem:playerItem];
        } else {
            
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:urlString];
            [overlayView playWith:playerItem];
        }
 
    }];
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark --
#pragma mark -- VideoOverlayDelegate

- (void)removeVideOverlay
{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    UIWindow *window = delegate.window;
    VideoOverlayView * overlayView = [window viewWithTag:1000];
    if (overlayView) {
        [overlayView removeFromSuperview];
        overlayView = nil;
    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
