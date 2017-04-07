//
//  GAudioPlayer.m
//  GAudioFoundation
//
//  Created by apple on 2017/4/7.
//  Copyright © 2017年 gong. All rights reserved.
//

#import "GAudioPlayer.h"

@import MediaPlayer;
@import AVFoundation;

@interface GAudioPlayer()<AVAudioPlayerDelegate>
@property(nonatomic, weak)id<GAudioPlayerDelegate> delegate;
@property (weak ,nonatomic) NSTimer *timer;//进度更新定时器
@property(nonatomic, strong)AVAudioPlayer *audioPlayer;

//网络音频
@property (nonatomic, strong)NSURL * URL;
@property(nonatomic, strong)AVPlayerItem *internetPlayerItem;
@property(nonatomic, strong)AVPlayer *internetAudioPlayer;
@property(nonatomic, assign)UIBackgroundTaskIdentifier bgTaskId;
@property (nonatomic, strong) id timeObserve;
@end

@implementation GAudioPlayer
- (instancetype)init
{
    if(self == [super init])
    {
        
    }
    return self;
}

/**
 *  创建播放器
 *
 *  @return 音频播放器
 */
- (BOOL)playAudioWithFilePath:(NSString *)audioFilePath
{
    //先停止并销毁现有的音频播放器
    [self stop];
    
    [self configureAVAudioSession];
    
    //重新创建一个音频播放器
    if (!_audioPlayer)
    {
        //注意这里的Url参数只能时文件路径，不支持HTTP Url
        //audioFilePath = [[NSBundle mainBundle]pathForResource:@"AAC测试音频.aac" ofType:nil];
        NSURL *fileURL=[NSURL fileURLWithPath:audioFilePath];
        
        NSError *error=nil;
        // 2.创建 AVAudioPlayer 对象
        _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:fileURL error:&error];
        
        // 3.打印歌曲信息
#ifdef DEBUG
        NSString *msg = [NSString stringWithFormat:@"音频文件声道数:%ld\n 音频文件持续时间:%g",(unsigned long)_audioPlayer.numberOfChannels,_audioPlayer.duration];
        NSLog(@"%@",msg);
#endif
        
        // 4.设置循环播放
        _audioPlayer.numberOfLoops = 1;
        _audioPlayer.delegate = self;
        
        [_audioPlayer prepareToPlay];//加载音频文件到缓存
        
        if(error){
            NSLog(@"初始化播放器过程发生错误,错误信息:%@",error.localizedDescription);
            return NO;
        }
        else
        {
            [_audioPlayer play];
            [self timer];
        }
    }
    return YES;
}

- (BOOL)playAudioWithData:(NSData *)audioData withDelegate:(id)delegate
{
    _delegate = delegate;
    
    //先停止并销毁现有的音频播放器
    [self stop];
    
    [self configureAVAudioSession];
    
    //重新创建一个音频播放器
    if (!_audioPlayer)
    {
        NSError *error=nil;
        // 2.创建 AVAudioPlayer 对象
        _audioPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:&error];
        
        // 3.打印歌曲信息
#ifdef DEBUG
        NSString *msg = [NSString stringWithFormat:@"音频文件声道数:%ld\n 音频文件持续时间:%g",(unsigned long)_audioPlayer.numberOfChannels,_audioPlayer.duration];
        NSLog(@"%@",msg);
#endif
        
        // 4.设置循环播放
        _audioPlayer.numberOfLoops = 1;
        _audioPlayer.delegate = self;
        
        [_audioPlayer prepareToPlay];//加载音频文件到缓存
        
        if(error){
            NSLog(@"初始化播放器过程发生错误,错误信息:%@",error.localizedDescription);
            return NO;
        }
        else
        {
            [_audioPlayer play];
            [self timer];
        }
    }
    return YES;
}

#pragma mark 播放网络音频
- (void)playAudioWithURL:(NSURL *)audioURL
             withArtwork:(NSString *)artwork
               withTitle:(NSString *)title
              withArtist:(NSString *)artist
          withAlbumTitle:(NSString *)albumTitle
            withDelegate:(id)delegate
{
    self.URL = audioURL;
    
    [self stop];
    
    //禁止混音
    //    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
    //                                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
    //                                           error:nil];
    //后台播放
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                           error:nil];
    
    //设置锁屏播放信息
    NSMutableDictionary<NSString *, id> *nowPlayingInfo = [[NSMutableDictionary alloc] init];
    
    if(artwork){
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork;
    }
    if(title){
        nowPlayingInfo[MPMediaItemPropertyTitle] = title;
    }
    if(albumTitle){
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumTitle;
    }
    if(artist){
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist;
    }
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nowPlayingInfo];
    
    //开始播放
    self.delegate = delegate;
    
    
    self.internetPlayerItem = [AVPlayerItem playerItemWithURL:self.URL];
    
    self.internetAudioPlayer = [[AVPlayer alloc] initWithPlayerItem:self.internetPlayerItem];
    
    [self addObserver];//添加监听
    
    [self.internetAudioPlayer play];
    
    [self enableBackgroundPlay];
    
    self.state = GAudioPlayerStateWaiting;
}

- (void)addObserver{
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    [commandCenter.playCommand addTarget:self action:@selector(didReceivePlayCommand:)];
    [commandCenter.pauseCommand addTarget:self action:@selector(didReceivePauseCommand:)];
    //[commandCenter.nextTrackCommand addTarget:self action:@selector(didReceiveNextTrackCommand)];
    //[commandCenter.previousTrackCommand addTarget:self action:@selector(didReceivePreviousTrackCommand)];
    
    commandCenter.stopCommand.enabled = NO;
    
    //播放被中断
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interruptionNotificationCallback:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
    //耳机插拔
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioRouteChangeListenerCallback:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    
    //添加对对音频播放情况的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    //播放状态的变更
    if(self.internetPlayerItem){
        [self.internetPlayerItem addObserver:self
                                  forKeyPath:@"status"
                                     options:0
                                     context:nil];
        
        [self.internetPlayerItem addObserver:self
                                  forKeyPath:@"loadedTimeRanges"
                                     options:NSKeyValueObservingOptionNew
                                     context:nil];
        
        [self.internetPlayerItem addObserver:self
                                  forKeyPath:@"playbackBufferEmpty"
                                     options:NSKeyValueObservingOptionNew
                                     context:nil];
        
        [self.internetPlayerItem addObserver:self
                                  forKeyPath:@"playbackLikelyToKeepUp"
                                     options:NSKeyValueObservingOptionNew
                                     context:nil];
    }
    
    __weak typeof(self) wSelf = self;
    
    //监听播放进度
    if(self.internetAudioPlayer){
        self.timeObserve = [self.internetAudioPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 2.0)
                                                                                  queue:dispatch_get_main_queue()
                                                                             usingBlock:^(CMTime time)
                            {
                                CGFloat current = CMTimeGetSeconds(time);
                                CGFloat total = CMTimeGetSeconds(wSelf.internetPlayerItem.duration);
                                total = isnan(total)?0:total;
                                
                                wSelf.duration = total;
                                
                                if(total>0)
                                    wSelf.progress = current / total;
                                else
                                    wSelf.progress = 0;
                                
                                [wSelf updateNowPlayingInfoWithRate:1.0];
                            }];
        
        [self.internetAudioPlayer addObserver:self
                                   forKeyPath:@"rate"
                                      options:NSKeyValueObservingOptionNew
                                      context:nil];
    }
}

- (void)removeObserver {
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.playCommand removeTarget:self];
    [commandCenter.pauseCommand removeTarget:self];
    [commandCenter.nextTrackCommand removeTarget:self];
    [commandCenter.previousTrackCommand removeTarget:self];
    
    //移除对ControlCenter的监听
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.timeObserve) {
        [self.internetAudioPlayer removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    
    if(self.internetPlayerItem){
        [self.internetPlayerItem removeObserver:self forKeyPath:@"status"];
        [self.internetPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [self.internetPlayerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.internetPlayerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    
    if(self.internetAudioPlayer){
        [self.internetAudioPlayer removeObserver:self forKeyPath:@"rate"];
        [self.internetAudioPlayer replaceCurrentItemWithPlayerItem:nil];
    }
}

- (void)enableBackgroundPlay{
    //开启后台处理多媒体事件
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    //这样做，可以在按home键进入后台后 ，播放一段时间，几分钟吧。但是不能持续播放网络歌曲，若需要持续播放网络歌曲，还需要申请后台任务id，具体做法是：
    self.bgTaskId = [self backgroundPlayerID:self.bgTaskId];
    //其中的_bgTaskId是后台任务UIBackgroundTaskIdentifier _bgTaskId;
}

//实现一下backgroundPlayerID:这个方法:
- (UIBackgroundTaskIdentifier)backgroundPlayerID:(UIBackgroundTaskIdentifier)backTaskId
{
    //设置并激活音频会话类别
    AVAudioSession *session=[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    //允许应用程序接收远程控制
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    //设置后台任务ID
    UIBackgroundTaskIdentifier newTaskId=UIBackgroundTaskInvalid;
    newTaskId=[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    if(newTaskId!=UIBackgroundTaskInvalid&&backTaskId!=UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:backTaskId];
    }
    return newTaskId;
}

#pragma mark 控制中心操作
- (void)didReceivePlayCommand:(MPRemoteCommandEvent *)event
{
    if([_delegate respondsToSelector:@selector(audioPlayerResume)]){
        [_delegate audioPlayerResume];
    }
    [self resume];
}

- (void)didReceivePauseCommand:(MPRemoteCommandEvent *)event
{
    if([_delegate respondsToSelector:@selector(audioPlayerPaused)]){
        [_delegate audioPlayerPaused];
    }
    [self pause];
}
#pragma mark - 网络播放回调
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem * item = (AVPlayerItem *)object;
        if (item.status == AVPlayerItemStatusFailed){ //失败
            [self itemFailedToPlay];
            self.state = GAudioPlayerStateError;
        }
        else if(item.status == AVPlayerItemStatusReadyToPlay){
            [self updateNowPlayingInfoWithRate:1.0];//更新控制中心的时间进度条
            self.state = GAudioPlayerStatePlaying;
#ifdef DEBUG
            NSLog(@"ready to play");
#endif
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        AVPlayerItem * item = (AVPlayerItem *)object;
        NSArray * array = item.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue]; //本次缓冲的时间范围
        NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration); //缓冲总长度
#ifdef DEBUG
        NSLog(@"共缓冲%.2f",totalBuffer);
#endif
    }
    if ([keyPath isEqualToString:@"rate"]) {
        AVPlayer *player = (AVPlayer *)object;
        
        if (player.rate == 0.0) {
            _state = GAudioPlayerStatePaused;
        }else {
            _state = GAudioPlayerStatePlaying;
        }
    }
}

#pragma mark - Property Set
- (void)setProgress:(CGFloat)progress {
    [self willChangeValueForKey:@"progress"];
    _progress = progress;
    [self didChangeValueForKey:@"progress"];
}

- (void)setState:(GAudioPlayerState)state {
    [self willChangeValueForKey:@"progress"];
    _state = state;
    [self didChangeValueForKey:@"progress"];
}

- (void)setCacheProgress:(CGFloat)cacheProgress {
    [self willChangeValueForKey:@"progress"];
    _cacheProgress = cacheProgress;
    [self didChangeValueForKey:@"progress"];
}

- (void)setDuration:(CGFloat)duration {
    if (duration != _duration && !isnan(duration)) {
        [self willChangeValueForKey:@"duration"];
#ifdef DEBUG
        NSLog(@"duration %f",duration);
#endif
        _duration = duration;
        [self didChangeValueForKey:@"duration"];
    }
}


#pragma mark 播放状态变更通知

//播放完成
- (void)itemDidFinishPlaying:(NSNotification *)notification{
    if([_delegate respondsToSelector:@selector(audioPlayerDidFinishPlaying)]){
        [_delegate audioPlayerDidFinishPlaying];
    }
}

//播放失败
- (void)itemFailedToPlay{
    if([_delegate respondsToSelector:@selector(audioPlayerFailedToPlay)]){
        [_delegate audioPlayerFailedToPlay];
    }
}

//播放中断
- (void)interruptionNotificationCallback:(NSNotification *)notification{
    //打开网易云音乐会触发
    if([_delegate respondsToSelector:@selector(audioPlayerInterruption)]){
        [_delegate audioPlayerInterruption];
    }
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
#ifdef DEBUG
            NSLog(@"AVAudioSessionRouteChangeReasonNewDeviceAvailable");
            NSLog(@"Headphone/Line plugged in");
#endif
            if([_delegate respondsToSelector:@selector(headphoneStatusChange:)]){
                [_delegate headphoneStatusChange:YES];
            }
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
#ifdef DEBUG
            NSLog(@"AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
            NSLog(@"Headphone/Line was pulled. Stopping player....");
#endif
            if([_delegate respondsToSelector:@selector(headphoneStatusChange:)]){
                [_delegate headphoneStatusChange:NO];
            }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
#ifdef DEBUG
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
#endif
            break;
    }
}

//更新控制中心的播放进度
- (void)updateNowPlayingInfoWithRate:(CGFloat)rate
{
    NSMutableDictionary * info = [[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo mutableCopy];
    [info setObject:@(CMTimeGetSeconds(self.internetPlayerItem.currentTime)) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime]; //音乐当前已经播放时间
    [info setObject:@(rate) forKey:MPNowPlayingInfoPropertyPlaybackRate];//进度光标的速度 （这个随 自己的播放速率调整，我默认是原速播放）
    [info setObject:@(CMTimeGetSeconds(self.internetPlayerItem.duration)) forKey:MPMediaItemPropertyPlaybackDuration];//歌曲总时间设置
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
}

#pragma mark -

- (void)reloadCurrentItem {
    
    //Player
    self.internetAudioPlayer = [AVPlayer playerWithPlayerItem:self.internetPlayerItem];
    //Observer
    [self addObserver];
    
    //State
    _state = GAudioPlayerStateWaiting;
}

#pragma mark 播放下一首
- (void)replaceItemWithURL:(NSURL *)url {
    self.URL = url;
    //[self reloadCurrentItem];
}

#pragma mark -

- (void)stop
{
    if (self.state == GAudioPlayerStateStopped) {
        return;
    }
    
    if(_audioPlayer)
    {
        [_audioPlayer stop];
        _audioPlayer.delegate = nil;
        _audioPlayer = nil;
    }
    
    if(self.timer){
        [self.timer invalidate];
        self.timer = nil;
    }
    
    [self removeObserver];//移除通知
    
    if(self.internetAudioPlayer){
        [self.internetAudioPlayer pause];
        self.internetAudioPlayer = nil;
        [self updateNowPlayingInfoWithRate:0.f];
    }
    
    if(self.internetPlayerItem){
        self.internetPlayerItem = nil;
    }
    
    self.progress = 0.0;
    self.duration = 0.0;
    self.state = GAudioPlayerStateStopped;
}

/**
 *  暂停播放
 */
-(void)pause
{
    if (self.state == GAudioPlayerStatePlaying)
    {
        if (_audioPlayer)
        {
            [_audioPlayer pause];
            self.timer.fireDate=[NSDate distantFuture];//暂停定时器，注意不能调用invalidate方法，此方法会取消，之后无法恢复
        }
        
        if(self.internetAudioPlayer){
            [self.internetAudioPlayer pause];
        }
        
        self.state = GAudioPlayerStatePaused;
    }
}

//继续播放
- (void)resume
{
    if (self.state == GAudioPlayerStatePaused || self.state == GAudioPlayerStateWaiting)
    {
        if (_audioPlayer) {
            [_audioPlayer play];
            self.timer.fireDate=[NSDate distantPast];//恢复定时器
        }
        
        if(self.internetAudioPlayer){
            [self.internetAudioPlayer play];
        }
        
        self.state = GAudioPlayerStatePlaying;
    }
}

- (void)seekToTime:(CGFloat)seconds {
    if (self.state == GAudioPlayerStatePlaying || self.state == GAudioPlayerStatePaused) {
        [self.internetAudioPlayer pause];
        
        [self.internetAudioPlayer seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC)
                           completionHandler:^(BOOL finished)
         {
#ifdef DEBUG
             NSLog(@"seekComplete!!");
#endif
             [self.internetAudioPlayer play];
         }];;
    }
}



/**
 *  更新播放进度
 */
-(void)updateProgress
{
#ifdef DEBUG
    float progress= _audioPlayer.currentTime / _audioPlayer.duration;
    NSLog(@"%lf", progress);
#endif
    //[self.playProgress setProgress:progress animated:true];
}

-(NSTimer *)timer
{
    if (!_timer) {
        _timer=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateProgress) userInfo:nil repeats:true];
    }
    return _timer;
}

#pragma mark - 本地播放器代理方法
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"音乐播放完成...");
    
    if ([_delegate respondsToSelector:@selector(audioPlayerDidFinishPlaying)]) {
        
        [_delegate audioPlayerDidFinishPlaying];
        
    }
    [self.timer invalidate];
    self.timer = nil;
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error
{
#ifdef DEBUG
    NSLog(@"%@",error.description);
#endif
}


- (void)dealloc{
    
    
    [self stop];
}

@end
