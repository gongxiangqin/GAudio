//
//  GAudioRecord.m
//  GAudioFoundation
//
//  Created by apple on 2017/4/7.
//  Copyright © 2017年 gong. All rights reserved.
//

#import "GAudioRecord.h"

@interface GAudioRecord ()
{
    AVAudioRecorder *_avRecorder;
    
    BOOL _stoppedRecord;
    BOOL _isFinishConvert;
}

@end

@implementation GAudioRecord
- (instancetype)init
{
    if(self = [super init])
    {
    }
    return self;
}

- (void)recordConfigWithHandlerBlock:(void(^)(BOOL granted))handlerBlock
{
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    
    //配置
    [self configureAVAudioSession];
    
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        //请求麦克风权限
        [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            if (granted) {
                // Microphone enabled code
                NSLog(@"麦克风权限正常");
            }
            else {
                // Microphone disabled code
                NSLog(@"获取麦克风权限失败");
            }
            
            if(handlerBlock)
                handlerBlock(granted);
        }];
    }
}

- (BOOL)startRecordWithSavePath:(NSString *)recordFilePath
{
    _aacFilePath = recordFilePath;
    
    NSError *error = nil;
    
    //创建了一个编码格式为AAC的AVAudioRecorder对象
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,
                              [NSNumber numberWithInt:44100.0],AVSampleRateKey,
                              [NSNumber numberWithInt:2],AVNumberOfChannelsKey,
                              [NSNumber numberWithInt:8],AVLinearPCMBitDepthKey,
                              [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                              [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                              nil];
    
    _avRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:_aacFilePath]
                                              settings:settings
                                                 error:&error];
    if(error)
    {
        return NO;
    }
    
    if([_avRecorder prepareToRecord])
    {
        BOOL retValue = [_avRecorder record];
        
        return retValue;
    }
    
    
    return NO;
}

- (void)stopRecord
{
    [_avRecorder stop];
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    NSError *error = nil;
    [audioSession setActive:NO error:&error];
    _avRecorder = nil;
    _stoppedRecord = YES;
    
}

- (void)cancelRecord
{
    _stoppedRecord = YES;
    [_avRecorder stop];
    [_avRecorder deleteRecording];
}

- (double)peakPowerForChannel
{
    if (_avRecorder) {
        
        /*  发送updateMeters消息来刷新平均和峰值功率。
         *  此计数是以对数刻度计量的，-160表示完全安静，
         *  0表示最大输入值
         */
        _avRecorder.meteringEnabled = YES;
        [_avRecorder updateMeters];
        
        float peakPower = [_avRecorder averagePowerForChannel:0];
        
        double ALPHA = 0.05;
        //double peakPowerForChannel = pow(10, (ALPHA * peakPower));
        
        return pow(10, (ALPHA * peakPower));
    }
    
    return 0.0;
}
@end
