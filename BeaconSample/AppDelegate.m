//
//  AppDelegate.m
//  BeaconSample
//
//  Created by totyu1 on 2015/06/23.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import "AppDelegate.h"
#import "BGTask.h"

@interface AppDelegate ()

@property (strong , nonatomic) BGTask *bgTask;
@property (strong , nonatomic) NSMutableArray *updatelist;
@property (strong , nonatomic) NSMutableData* Rdata;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [NSThread sleepForTimeInterval:1];
    
    // [self redirectNSlogToDocumentFolder];
    
    // 创建定位管理
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
    
    // 定期将进出beacon范围的信息 更新上传到服务器
    [NSTimer scheduledTimerWithTimeInterval:30.0
                                     target:self
                                   selector:@selector(updateUserstatusList)
                                   userInfo:nil
                                    repeats:YES];
    
    return YES;
}


/**
 定期将进出beacon范围的信息 更新上传到服务器
 */
-(void)updateUserstatusList{
    NSLog(@"有更新内容：%lu",(unsigned long)self.updatelist.count);
    if(self.updatelist.count> 0){
        // 请求参数
        NSMutableDictionary * postdic = [[NSMutableDictionary alloc]init];
        [postdic setObject:self.updatelist forKey:@"updatedata"];
        NSData* jsondata = [NSJSONSerialization dataWithJSONObject:postdic options:NSJSONWritingPrettyPrinted error:nil];
        // 请求地址
        NSString *strURL= [[NSString alloc] initWithFormat:@"https://beaconapp2.chinacloudsites.cn/rdupdateall.php"];
        NSURL* url =[NSURL URLWithString:strURL];
        // 发送请求
        NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:jsondata];
        NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if (connection) {
            self.Rdata = [NSMutableData new];
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
    
    [self.updatelist addObject:dataitem];
    
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
    
    // 将log输入到文件
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
}


-(instancetype)init{
    if(self == [super init])
    {
        _bgTask = [BGTask shareBGTask];
        [_bgTask beginNewBackgroundTask];
    }
    return self;
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.Rdata appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:self.Rdata options:NSJSONReadingMutableLeaves error:&error];
    
    [self.updatelist removeAllObjects];

    NSLog(@"更新成功");
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"更新失敗");
}


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
