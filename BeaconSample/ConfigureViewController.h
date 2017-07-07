//
//  ConfigureViewController.h
//  BeaconSample
//
//  Created by totyu1 on 2015/07/09.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@protocol ConfigureVCDelegate <NSObject>
-(void)UserInfoUpdateEvent;
@end

@interface ConfigureViewController : UIViewController



@property (nonatomic, assign) id<ConfigureVCDelegate>delegate;

@end
