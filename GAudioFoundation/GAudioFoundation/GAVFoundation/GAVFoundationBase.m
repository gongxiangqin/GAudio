//
//  GAVFoundationBase.m
//  GAudioFoundation
//
//  Created by apple on 2017/4/7.
//  Copyright © 2017年 gong. All rights reserved.
//

#import "GAVFoundationBase.h"

@implementation GAVFoundationBase

//设置音频输出为扬声器.并在插上耳机的时候，会优先耳机。
- (void) configureAVAudioSession //To play through main iPhone Speakers
{
    //get your app's audioSession singleton object
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    //error handling
    BOOL success;
    NSError* error;
    
    //set the audioSession category.
    //Needs to be Record or PlayAndRecord to use audioRouteOverride:
    
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                             error:&error];
    
    if (!success)
        NSLog(@"AVAudioSession error setting category:%@",error);
    
    //设置播放器为扬声器模式
    success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                         error:&error];
    if (!success)
        NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    
    //activate the audio session
    success = [session setActive:YES error:&error];
    if (!success)
        NSLog(@"AVAudioSession error activating: %@",error);
    else
        NSLog(@"audioSession active");
    
}


@end
