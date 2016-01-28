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

@property (strong, nonatomic) NSString *useruuid;
@property (strong, nonatomic) NSString *username;
@property BOOL status2;

@end

