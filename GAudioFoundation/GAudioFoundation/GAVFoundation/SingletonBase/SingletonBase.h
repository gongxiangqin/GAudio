//
//  SingletonBase.h
//  RYDW(jz)
//
//  Created by apple on 2017/3/16.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SingletonBase : NSObject
+(instancetype) sharedInstance;
+ (void)destroyInstance;
@property (assign, readonly) BOOL isInitialized;
@end
