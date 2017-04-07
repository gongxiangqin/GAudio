//
//  GAudioRecord.h
//  GAudioFoundation
//
//  Created by apple on 2017/4/7.
//  Copyright © 2017年 gong. All rights reserved.
//

#import "GAVFoundationBase.h"

@protocol GAudioRecordDelegate <NSObject>

- (void)recordFinishedWithRecordFilePath:(NSString *)filePath;

@end

@interface GAudioRecord : GAVFoundationBase

@property(nonatomic, weak)id<GAudioRecordDelegate> delegate;
@property(nonatomic, strong, readonly)NSString *aacFilePath;

- (void)recordConfigWithHandlerBlock:(void(^)(BOOL granted))handlerBlock;
- (BOOL)startRecordWithSavePath:(NSString *)recordFilePath;
- (void)stopRecord;
- (void)cancelRecord;
- (double)peakPowerForChannel;

@end
