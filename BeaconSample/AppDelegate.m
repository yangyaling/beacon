//
//  AppDelegate.m
//  BeaconSample
//
//  Created by totyu1 on 2015/06/23.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
@synthesize useruuid;
@synthesize username;
@synthesize status2;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [NSThread sleepForTimeInterval:1];
    
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = (id)self;
    
    //get device's uuid for useruuid
    NSString *identifierForVendor=[[[UIDevice currentDevice] identifierForVendor]UUIDString];//UUID
    self.useruuid= identifierForVendor;
    
    //setting for notification
    UIMutableUserNotificationCategory *categorys=[[UIMutableUserNotificationCategory alloc]init];
    UIUserNotificationSettings *settings=[UIUserNotificationSettings  settingsForTypes:(UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound) categories:[NSSet setWithObject:categorys]];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [UIApplication sharedApplication].applicationIconBadgeNumber =0;
    [[NSNotificationCenter defaultCenter]postNotificationName:@"applicationWillEnterForeground" object:self];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {

}

-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings{
    //    NSLog(@"－－－－－－－－%@",notificationSettings);
}

-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler{
    //NSLog(@"－－－－－－－－%@",identifier);
    completionHandler();
}

//location magenager delegate
-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    NSString *notificationMessage = [[NSString alloc]initWithFormat:@"%@に入った",region.identifier];
    NSString *status = @"1";
    [self updateUserStatus:status beaconRegion:(CLBeaconRegion *)region];
    [self sendNotification:notificationMessage];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    NSString *notificationMessage = [[NSString alloc]initWithFormat:@"%@から出た",region.identifier];
    NSString *status = @"0";
    [self updateUserStatus:status beaconRegion:(CLBeaconRegion *)region];
    [self sendNotification:notificationMessage];
    
    
}

//----------------------------NSURLRequest(POST) update the states to server---------------------------------
-(void)updateUserStatus:(NSString*)status beaconRegion:(CLBeaconRegion*)beaconregion{
    
    AppDelegate *appdg= (AppDelegate*)[[UIApplication sharedApplication]delegate];
    NSString * suuid =appdg.useruuid;
    NSString * uuid = (NSString*)beaconregion.proximityUUID.UUIDString;
    NSString * major = [beaconregion.major stringValue];
    NSString * minor = [beaconregion.minor stringValue];
    
    NSString *strURL= [[NSString alloc] initWithFormat:@"http://rdbeacon.azurewebsites.net/rdupdatestatus.php?useruuid=%@&status=%@&uuid=%@&major=%@&minor=%@",suuid,status,uuid,major,minor];
    NSURL *url=[NSURL URLWithString:strURL];
    NSURLRequest *request=[[NSURLRequest alloc]initWithURL:url];
    
    
    NSURLConnection *connect = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connect start];
    
    if (connect) {
    }
}

//scheduling notifications
-(void)sendNotification:(NSString *)message{
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.fireDate = [[NSDate date]init];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertBody = message;
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.alertAction =@"Open";
    notification.repeatInterval = 0;
    notification.applicationIconBadgeNumber=[UIApplication sharedApplication].applicationIconBadgeNumber+1;
    notification.category = @"notification";

    [[UIApplication sharedApplication]scheduleLocalNotification:notification];
}
@end
