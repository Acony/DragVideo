//
//  CacheThumbVideo.h
//  SamplePlayVideo
//
//  Created by quanght2 on 9/1/16.
//  Copyright © 2016 VngCorp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CacheThumbVideo : NSObject

- (UIImage*) getThumbFromUrl:(NSString*)url;
- (void)setThumb:(UIImage*)thumb intoKey:(NSString*)url;
- (CGSize)getSizeVideo:(NSString*)url;

+(id) sharedInstance;

@end
