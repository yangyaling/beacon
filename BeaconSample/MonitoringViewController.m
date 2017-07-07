//
//  MonitoringViewController.m
//  BeaconSample
//
//  Created by totyu1 on 2015/06/23.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//  beacon页面

#import "MonitoringViewController.h"
#import "ConfigureViewController.h"
#import "AppDelegate.h"
#import "BeaconCell.h"
#import "MBProgressHUD.h"

@import CoreBluetooth;

CGFloat const NavButtonWidth=33;
CGFloat const NavButtonHeight=32;

@interface MonitoringViewController ()<CLLocationManagerDelegate,NSURLConnectionDelegate,NSURLConnectionDataDelegate,UIAlertViewDelegate,MBProgressHUDDelegate>

// 用户有效的beacon位置信息
@property (strong,nonatomic) NSMutableArray *mybeacons;
@property (assign,nonatomic) BOOL isGetBeacon;
@property (strong , nonatomic) NSMutableData *Rdata;

@end

@implementation MonitoringViewController
//@synthesize Rdata=_Rdata;
//@synthesize isGetBeacon=_isGetBeacon;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 创建导航栏按钮
    [self initNavButton];
    
    // 创建位置管理者
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = (id)self;
    // 请求授权
    [self.locationManager requestAlwaysAuthorization];
    self.locationManager.activityType = CLActivityTypeFitness;
    // 设置定位距离过滤参数
    self.locationManager.distanceFilter = kCLLocationAccuracyBest;
    // 设置定位精度(精度越高越耗电)
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    
    // 判断检索到的beacon信息本地是否存在
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    // Home目录
    NSString *homePath = NSHomeDirectory();
    // Document目录
    NSString *docPath = [homePath stringByAppendingPathComponent:@"Documents"];
    NSString *plistPath = [docPath stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"%@.plist",delegate.useruuid]];
    
    self.Locations = [NSMutableDictionary new];
    self.mybeacons = [NSMutableArray new];

    NSString *beaconpath =[docPath stringByAppendingPathComponent:[[NSString alloc]initWithFormat:  @"beaconlocation.plist"]];
    
    NSLog(@"plistpath:%@\n beaconpath:%@\n",plistPath,beaconpath);
    
    // 如果本地存在，取出本地保存的信息
    if ([[NSFileManager defaultManager] fileExistsAtPath:beaconpath]) {
        self.BeaconInfo = [[NSMutableDictionary alloc]initWithContentsOfFile:beaconpath];
        
    }
    // 如果是第二次以后登录，取出本地保存的客户端用户信息
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSMutableDictionary * userinfo = [[NSMutableDictionary alloc]initWithContentsOfFile:plistPath];
        delegate.username = [userinfo valueForKey:@"username"];
        NSString* strStatus2 = [userinfo valueForKey:@"status2"];
        
        if ([strStatus2 isEqualToString:@"1"]) {
            delegate.status2 = YES;
        }else{
            delegate.status2 = NO;
        }
        //
        [self initCLBeaconRegion];
        
        // 获取beacon信息
        [self getBeaconInfo];
    }else{
    // 如果是第一次登录，进入登录界面
        // 获取beacon信息
        [self getBeaconInfo];
        [self performSegueWithIdentifier:@"segueConfigure" sender:self];
    }
    
    self.tableView.tableFooterView = [[UIView alloc]init];
}



/**
 初始化 Beacon Regions
 */
-(void)initCLBeaconRegion{
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        if(self.BeaconInfo){
            [self.mybeacons removeAllObjects];
            NSArray *beacons = [self.BeaconInfo allKeys];
            for(int i = 0 ; i < beacons.count; i++){
                NSString *name = beacons[i];
                NSString *uuid = [[self.BeaconInfo objectForKey:name] objectForKey:@"uuid"];
                NSString *major = [[self.BeaconInfo objectForKey:name] objectForKey:@"major"];
                NSString *minor = [[self.BeaconInfo objectForKey:name] objectForKey:@"minor"];
                
                CLBeaconRegion *region = [[CLBeaconRegion alloc]initWithProximityUUID:[[NSUUID alloc]initWithUUIDString:uuid] major:[major intValue] minor:[minor intValue] identifier:name];
                
                region.notifyOnEntry = YES;
                region.notifyOnExit = YES;
                region.notifyEntryStateOnDisplay = YES;
                
                [self.locationManager startMonitoringForRegion:region];
                [self.locationManager startRangingBeaconsInRegion:region];
                [self.mybeacons addObject:region];
            }
        }
        else{
            NSLog(@"没有有效的beacon位置信息");
        }
    }

}


// 定位服务的授权状态发生改变的时候回调

-(void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        [self initCLBeaconRegion];
    }
    
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            
            if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                [self.locationManager requestAlwaysAuthorization];
            }else{
                [self initCLBeaconRegion];
            }
            break;
        case kCLAuthorizationStatusRestricted:
            break;
        case kCLAuthorizationStatusDenied:
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            [self initCLBeaconRegion];
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self initCLBeaconRegion];
            break;
        default:
            break;
    }
}


-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region{

    if (beacons.count>0) {
        NSMutableDictionary* location = [[NSMutableDictionary alloc]initWithDictionary:[self.Locations objectForKey:region.identifier]];
        if (location==nil){
            location = [NSMutableDictionary new];

        }
        [location setObject:beacons.firstObject forKey:@"beacons"];
        [location setValue:region.proximityUUID.UUIDString forKey:@"uuid"];
        [location setValue:region.major.stringValue forKey:@"major"];
        [location setValue:region.minor.stringValue forKey:@"minor"];
        [self.Locations setObject:location forKey:region.identifier];
    }else{
        NSMutableDictionary* location = [[NSMutableDictionary alloc]initWithDictionary:[self.Locations objectForKey:region.identifier]];
        if (location) {
            [self.Locations removeObjectForKey:region.identifier];
        }
    }

    [self.tableView reloadData];
    
    
}

-(void) locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error{
    //NSLog(@"%@", error);
}


-(void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error{
    //NSLog(@"%@", error);
}

//----------------------------NSURLRequest---------------------------------------------------
-(void)getBeaconInfo{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.isGetBeacon = YES;
    
    NSString *strURL = [[NSString alloc]initWithFormat:@"https://beaconapp.chinacloudsites.cn/rdgetlocation.php"];
    NSURL *url = [NSURL URLWithString:strURL];
    
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    self.Rdata = nil;
    if (connection) {
        [connection start];
        self.Rdata = [NSMutableData new];
    }
}

#pragma mark - NSURLConnectionDataDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    [self.Rdata setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.Rdata appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    NSError *error;
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:self.Rdata options:NSJSONReadingMutableLeaves error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if(self.isGetBeacon){
        NSString *home = NSHomeDirectory();
        NSString *docpath = [home stringByAppendingPathComponent:@"Documents"];
        NSString *plistpath =[docpath stringByAppendingPathComponent:[[NSString alloc]initWithFormat: @"beaconlocation.plist"]];
        NSFileManager *fileManager =[NSFileManager defaultManager];
        
        if (error) {
            
            if ([fileManager fileExistsAtPath:plistpath]) {
                self.BeaconInfo = [[NSMutableDictionary alloc]initWithContentsOfFile:plistpath];
                [self initCLBeaconRegion];
            }else{
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"データ解析が失敗しました。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
    
                }
        }
        else{
            self.BeaconInfo = [[NSMutableDictionary alloc]initWithDictionary:dict];
            [dict writeToFile:plistpath atomically:YES];
            [self initCLBeaconRegion];
        }
    }
    self.isGetBeacon = NO;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    MBProgressHUD *HUD = [[MBProgressHUD alloc]initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:HUD];
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.delegate = self;
    HUD.labelText = @"インターネットに接続していません";
    HUD.labelFont = [UIFont boldSystemFontOfSize:12.f];
    [HUD show:YES];
    [HUD hide:YES afterDelay:1];
}


/**
 创建导航栏按钮
 */
-(void)initNavButton{
    UIButton *leftBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *rightBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    leftBtn.frame=CGRectMake(0, 0, NavButtonWidth, NavButtonHeight);
    rightBtn.frame=CGRectMake(0, 0, NavButtonWidth, NavButtonHeight);
    [leftBtn setBackgroundImage:[UIImage imageNamed:@"config"] forState:UIControlStateNormal];
    [rightBtn setBackgroundImage:[UIImage imageNamed:@"members"] forState:UIControlStateNormal];
    [leftBtn addTarget:self action:@selector(editAction) forControlEvents:UIControlEventTouchUpInside];
    [rightBtn addTarget:self action:@selector(membersAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *itemleft=[[UIBarButtonItem alloc]initWithCustomView:leftBtn];
    UIBarButtonItem *itemright=[[UIBarButtonItem alloc]initWithCustomView:rightBtn];
    self.navigationItem.leftBarButtonItem = itemleft;
    self.navigationItem.rightBarButtonItem= itemright;
    
}


/**
 点击设置按钮触发
 */
-(void)editAction{
    [self performSegueWithIdentifier:@"segueConfigure" sender:self];
}


/**
 点击用户一览按钮触发
 */
-(void)membersAction{
    [self performSegueWithIdentifier:@"segueMember" sender:self];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.Locations) {
        return self.Locations.count;
    }else{
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    BeaconCell *cell = [tableView dequeueReusableCellWithIdentifier:@"beaconCell" forIndexPath:indexPath];
    NSInteger row = [indexPath row];
    NSArray * keys = [self.Locations allKeys];
    NSMutableDictionary* location = [self.Locations objectForKey:keys[row]];
    CLBeacon * beaconinfo = [location objectForKey:@"beacons"];

    cell.locationName.text=keys[row];//eacon.identifier;
    cell.proximity.text = beaconinfo.proximityUUID.UUIDString;
    cell.uuidLabel.text = [location valueForKey:@"uuid"];
    cell.majorLabel.text = [location valueForKey:@"major"];
    cell.minorLabel.text = [location valueForKey:@"minor"];
    
    NSString* strValue  =[NSString stringWithFormat:@"Acc:%.2fm Rssi:%ld",beaconinfo.accuracy,(long)beaconinfo.rssi ];
    cell.accuracyLabel.text = strValue  ;

            UIImage *img =nil;
    
            switch (beaconinfo.proximity) {
                case CLProximityUnknown:
                    img= [UIImage imageNamed:@"on1"];
                    cell.proximity.text = @"不明";
                    cell.statusImage.image = img;
                    break;
                case CLProximityImmediate:
                    img= [UIImage imageNamed:@"on4"];
                    cell.proximity.text = @"1M以内";
                    cell.statusImage.image = img;
                    break;
                case CLProximityNear:
                    img= [UIImage imageNamed:@"on3"];
                    cell.proximity.text = @"3M以内";
                    cell.statusImage.image = img;
                    break;
                case CLProximityFar:
                    img= [UIImage imageNamed:@"on2"];
                    cell.proximity.text = @"3M以外";
                    cell.statusImage.image = img;
                    break;
                default:
                    img= [UIImage imageNamed:@"off"];
                    cell.proximity.text = @"None";
                    cell.statusImage.image = img;
                    break;
            }
        return cell;
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"segueConfigure"]){
        ConfigureViewController *editVC= segue.destinationViewController;
        editVC.delegate = (id)self;
    }
}

-(void)UserInfoUpdateEvent{
    [self initCLBeaconRegion];
}

@end
