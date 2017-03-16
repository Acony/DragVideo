//
//  CacheThumbVideo.m
//  SamplePlayVideo
//
//  Created by quanght2 on 9/1/16.
//  Copyright © 2016 VngCorp. All rights reserved.
//

#import "CacheThumbVideo.h"

@interface WrapperSize : NSObject

@property (nonatomic) CGSize size;

@end

@implementation WrapperSize



@end

@interface CacheThumbVideo()

@property (nonatomic, strong) NSMutableDictionary *videoCache;
@property (nonatomic, strong) NSMutableDictionary *videoSizeCache;



@end

@implementation CacheThumbVideo

+(id) sharedInstance {
    
    static CacheThumbVideo* c_manager = nil;
    static dispatch_once_t c_token;
    dispatch_once(&c_token, ^{
        c_manager = [[CacheThumbVideo alloc] init];
    });
    return c_manager;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        
        self.videoCache   = [NSMutableDictionary new];
        self.videoSizeCache = [NSMutableDictionary new];
    }
    
    return self;
}


- (UIImage*) getThumbFromUrl:(NSString*)url
{
    return [self.videoCache objectForKey:url];
}

- (void)setThumb:(UIImage*)thumb intoKey:(NSString*)url
{
    [self.videoCache setObject:thumb forKey:url];
    
    WrapperSize *size = [[WrapperSize alloc]init];
    size.size = CGSizeMake(thumb.size.width, thumb.size.height);
    [self.videoSizeCache setObject:size forKey:url];
}

- (CGSize)getSizeVideo:(NSString*)url
{
    WrapperSize *size = [self.videoSizeCache objectForKey:url];
    if (size) {
        return size.size;
    }
    return CGSizeZero;
    
}

@end
