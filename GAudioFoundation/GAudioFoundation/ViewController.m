//
//  ViewController.m
//  GAudioFoundation
//
//  Created by apple on 2017/4/7.
//  Copyright © 2017年 gong. All rights reserved.
//

#import "ViewController.h"
#import "GAudioRecord.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    GAudioRecord *record = [[GAudioRecord alloc] init];
    [record recordConfigWithHandlerBlock:^(BOOL granted) {
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
