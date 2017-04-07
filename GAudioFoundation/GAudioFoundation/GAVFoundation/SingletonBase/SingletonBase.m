//
//  SingletonBase.m
//  RYDW(jz)
//
//  Created by apple on 2017/3/16.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "SingletonBase.h"

@implementation SingletonBase
static NSMutableDictionary *_sharedInstances = nil;

+ (void)initialize
{
    if (_sharedInstances == nil) {
        _sharedInstances = [NSMutableDictionary dictionary];
    }
}

+(instancetype) sharedInstance
{
    id sharedInstance = nil;
    
    @synchronized(self) {
        NSString *instanceClass = NSStringFromClass(self);
        
        // Looking for existing instance
        sharedInstance = [_sharedInstances objectForKey:instanceClass];
        
        // If there's no instance – create one and add it to the dictionary
        if (sharedInstance == nil) {
            sharedInstance = [[super allocWithZone:nil] init];
            [_sharedInstances setObject:sharedInstance forKey:instanceClass];
        }
    }
    
    return sharedInstance;
}

+ (void)destroyInstance
{
    [_sharedInstances removeObjectForKey:NSStringFromClass(self)];
}

#pragma mark 阻止程序被创建出其他的实例

//覆盖该方法主要确保当用户通过copy方法产生对象时对象的唯一性
-(id)copyWithZone:(NSZone *)zone
{
    return [[self class] sharedInstance];
}

//覆盖该方法主要确保当用户通过mutableCopy方法产生对象时对象的唯一性
- (id)mutableCopyWithZone:(struct _NSZone *)zone
{
    return [[self class] sharedInstance];
}
//alloc 方法实际上就是调用这两个方法
+(id)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedInstance];
}

+(id)copy
{
    return [self sharedInstance];
}

//自定义描述信息，用于log详细打印
- (NSString *)description
{
    return [NSString stringWithFormat:@"memeory address:%p",self];
}

- (instancetype)init
{
    self = [super init];
    
    if (self && !self.isInitialized) {
        // Thread-safe because it called from +sharedInstance
        _isInitialized = YES;
    }
    
    return self;
}

@end
