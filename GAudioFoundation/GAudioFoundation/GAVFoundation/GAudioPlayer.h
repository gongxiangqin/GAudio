//
//  GAudioPlayer.h
//  GAudioFoundation
//
//  Created by apple on 2017/4/7.
//  Copyright © 2017年 gong. All rights reserved.
//

#import "GAVFoundationBase.h"

@protocol GAudioPlayerDelegate <NSObject>

@optional
- (void)audioPlayerDidFinishPlaying;
- (void)audioPlayerDecodeErrorDidOccur:(NSError *)error;
- (void)audioPlayerFailedToPlay;
- (void)audioPlayerInterruption;//播放被中断，有可能是因为用户启动了其他音乐播放器
- (void)audioPlayerPaused;
- (void)audioPlayerResume;
- (void)headphoneStatusChange:(BOOL)pluggedIn;
@end

typedef NS_ENUM(NSInteger, GAudioPlayerState) {
    GAudioPlayerStateWaiting,
    GAudioPlayerStatePlaying,
    GAudioPlayerStatePaused,
    GAudioPlayerStateStopped,
    GAudioPlayerStateBuffering,
    GAudioPlayerStateError
};

@interface GAudioPlayer : GAVFoundationBase

@property (nonatomic, assign) GAudioPlayerState state;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) CGFloat cacheProgress;

//播放本地音频
- (BOOL)playAudioWithFilePath:(NSString *)audioFilePath;

//播放本地音频
- (BOOL)playAudioWithData:(NSData *)audioData withDelegate:(id)delegate;

//播放网络音频
- (void)playAudioWithURL:(NSURL *)audioURL
             withArtwork:(NSString *)artwork//专辑封面
               withTitle:(NSString *)title
              withArtist:(NSString *)artist
          withAlbumTitle:(NSString *)albumTitle
            withDelegate:(id)delegate;
/**
 *  播放下一首歌曲，url：歌曲的网络地址或者本地地址
 *  逻辑：stop -> replace -> play
 */
- (void)replaceItemWithURL:(NSURL *)url;

/**
 *  跳到某个时间进度
 */
- (void)seekToTime:(CGFloat)seconds;

- (void)stop;
- (void)pause;
- (void)resume;


- (void)updateProgress;
- (NSTimer *)timer;

@end
