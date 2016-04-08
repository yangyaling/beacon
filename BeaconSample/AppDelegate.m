//
//  AppDelegate.m
//  BeaconSample
//
//  Created by totyu1 on 2015/06/23.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import "AppDelegate.h"
#import "BGTask.h"

@interface AppDelegate (){
    NSString * urlstr;
    BOOL isCollect;
    NSTimer * timer;
    NSMutableData* Rdata;
    NSData *postData ;
    
}
@property (strong , nonatomic) BGTask *bgTask;
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
    
    
    [NSTimer scheduledTimerWithTimeInterval:150.0
                                     target:self
                                   selector:@selector(restartBkTask)
                                   userInfo:nil
                                    repeats:YES];
    
    return YES;
}

-(void)restartBkTask{
    
    [_bgTask beginNewBackgroundTask];
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
    NSDateFormatter * format = [[NSDateFormatter alloc]init];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *updatetime = [format stringFromDate:[NSDate date]];
    
    
    
    
    NSString *strURL= [[NSString alloc] initWithFormat:@"http://rdbeacon.azurewebsites.net/rdreupdatestatus.php"];
    
    NSString *post = [NSString stringWithFormat:@"useruuid=%@&status=%@&uuid=%@&major=%@&minor=%@&updatetime=%@",suuid,status,uuid,major,minor,updatetime];
    
    postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    
    urlstr = [NSString stringWithString:strURL];
    NSURL *url=[NSURL URLWithString:strURL];
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    
    [request setHTTPBody:postData];
    
    NSURLConnection *connect = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connect start];
    
    if (connect) {
        Rdata = [NSMutableData new];
    }
}

//----------------------------NSURLRequest(POST) update the states to server---------------------------------
-(void)ReupdateWithURL{
    if(![urlstr isEqualToString:@""]){
        NSURL *url=[NSURL URLWithString:urlstr];
//        NSURLRequest *request=[[NSURLRequest alloc]initWithURL:url];
        NSMutableURLRequest *request=[[NSMutableURLRequest alloc]initWithURL:url];
        
        [request setHTTPMethod:@"POST"];
        
        [request setHTTPBody:postData];
        
        NSURLConnection *connect = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [connect start];
        
        if (connect) {
        }
    }
    
}

-(instancetype)init{
    if(self == [super init])
    {
        _bgTask = [BGTask shareBGTask];
        isCollect = NO;
        [_bgTask beginNewBackgroundTask];
    }
    return self;
}

//每次收到一条数据，就会调用此函数
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [Rdata appendData:data];//把data加到rdata最后
}

//----------------------------didFinishLoading(USURLConnectionDelegate协议的方法)------------------------------------------
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:Rdata options:NSJSONReadingMutableLeaves error:&error];
    
    urlstr = @"";
    NSLog(@"%@",dict);
}
//----------------------------didFailWithError(USURLConnectionDelegate)------------------------------------------
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
//    [self ReupdateWithURL];
    [self performSelector:@selector(ReupdateWithURL) withObject:nil afterDelay:1.0];
    NSLog(@"再度更新を請求する");
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
