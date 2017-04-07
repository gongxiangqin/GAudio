//
//  GAVFoundationBase.h
//  GAudioFoundation
//
//  Created by apple on 2017/4/7.
//  Copyright © 2017年 gong. All rights reserved.
//

#import "SingletonBase.h"
#import <AVFoundation/AVFoundation.h>

@interface GAVFoundationBase : SingletonBase
- (void)configureAVAudioSession;
@end
