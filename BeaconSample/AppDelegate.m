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
    BOOL isCollect;
    NSMutableData* Rdata;
    NSData *postData ;
    
}
@property (strong , nonatomic) BGTask *bgTask;
@end

@implementation AppDelegate
@synthesize useruuid;
@synthesize username;
@synthesize status2;
@synthesize updatelist;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [NSThread sleepForTimeInterval:1];
    
    // [self redirectNSlogToDocumentFolder];
    
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = (id)self;
    self.updatelist = [[NSMutableArray alloc]initWithCapacity:0];
    
    // 获取设备UUID
    NSString *identifierForVendor=[[[UIDevice currentDevice] identifierForVendor]UUIDString];
    self.useruuid= identifierForVendor;
    
    //setting for notification
    UIMutableUserNotificationCategory *categorys=[[UIMutableUserNotificationCategory alloc]init];
    UIUserNotificationSettings *settings=[UIUserNotificationSettings  settingsForTypes:(UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound) categories:[NSSet setWithObject:categorys]];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    
    
    [NSTimer scheduledTimerWithTimeInterval:30.0
                                     target:self
                                   selector:@selector(updateUserstatusList)
                                   userInfo:nil
                                    repeats:YES];
    
    return YES;
}

-(void)updateUserstatusList{
    NSLog(@"定期更新：%lu",(unsigned long)self.updatelist.count);
    if(self.updatelist.count> 0){
        
        NSMutableDictionary * postdic = [[NSMutableDictionary alloc]init];
        [postdic setObject:updatelist forKey:@"updatedata"];
        
        NSString *strURL= [[NSString alloc] initWithFormat:@"https://beaconapp.chinacloudsites.cn/rdupdateall.php"];
        
        
        NSURL* url =[NSURL URLWithString:strURL];

        NSData* jsondata = [NSJSONSerialization dataWithJSONObject:postdic options:NSJSONWritingPrettyPrinted error:nil];
        
        NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:jsondata];
        NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if (connection) {
            Rdata = [NSMutableData new];
        }

    }
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
    NSString *notificationMessage = [[NSString alloc]initWithFormat:@"进入[%@]",region.identifier];
    NSString *status = @"1";
    [self updateUserStatus:status beaconRegion:(CLBeaconRegion *)region];
    [self sendNotification:notificationMessage];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    NSString *notificationMessage = [[NSString alloc]initWithFormat:@"离开[%@]",region.identifier];
    NSString *status = @"0";
    [self updateUserStatus:status beaconRegion:(CLBeaconRegion *)region];
    [self sendNotification:notificationMessage];
    
    
}


// 进／出beacon范围时，将记录上传

-(void)updateUserStatus:(NSString*)status beaconRegion:(CLBeaconRegion*)beaconregion{
    
    AppDelegate *appdg= (AppDelegate*)[[UIApplication sharedApplication]delegate];
    NSString * suuid =appdg.useruuid;
    NSString * uuid = (NSString*)beaconregion.proximityUUID.UUIDString;
    NSString * major = [beaconregion.major stringValue];
    NSString * minor = [beaconregion.minor stringValue];
    NSDateFormatter * format = [[NSDateFormatter alloc]init];
    [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *updatetime = [format stringFromDate:[NSDate date]];
    
    NSMutableDictionary *dataitem = [[NSMutableDictionary alloc]init];
    [dataitem setValue:suuid forKey:@"useruuid"];
    [dataitem setValue:uuid forKey:@"uuid"];
    [dataitem setValue:major forKey:@"major"];
    [dataitem setValue:minor forKey:@"minor"];
    [dataitem setValue:status forKey:@"status"];
    [dataitem setValue:updatetime forKey:@"updatetime"];
    
    [updatelist addObject:dataitem];
    
    [self updateUserstatusList];
    
    //NSLog(@"即時更新：[%@] %@",status,updatetime);
    
}



// 将NSlog打印信息保存到Document目录下的文件中
- (void)redirectNSlogToDocumentFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *fileName = [NSString stringWithFormat:@"dr.log"];// 注意不是NSData!
    NSString *logFilePath = [documentDirectory stringByAppendingPathComponent:fileName];
    // 先删除已经存在的文件
    NSLog(@"%@",logFilePath);
    //    NSFileManager *defaultManager = [NSFileManager defaultManager];
    //    [defaultManager removeItemAtPath:logFilePath error:nil];
    
    // 将log输入到文件
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
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
    
    [updatelist removeAllObjects];

    NSLog(@"更新成功");
}
//----------------------------didFailWithError(USURLConnectionDelegate)------------------------------------------
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"更新失敗");
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
