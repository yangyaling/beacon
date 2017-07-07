//
//  AppDelegate.h
//  BeaconSample
//
//  Created by totyu1 on 2015/06/23.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreLocation;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CLLocationManager* locationManager;

/**
 客户端的UUID
 */
@property (strong, nonatomic) NSString *useruuid;

/**
 客户端的用户名(初期页面输入)
 */
@property (strong, nonatomic) NSString *username;

/**
 状态
 */
@property BOOL status2;


@end

