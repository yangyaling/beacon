//
//  MonitoringViewController.m
//  BeaconSample
//
//  Created by totyu1 on 2015/06/23.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import "MonitoringViewController.h"
#import "ConfigureViewController.h"
#import "AppDelegate.h"
#import "BeaconCell.h"
#import "MBProgressHUD.h"

@import CoreBluetooth;
//define the navigation bar button's width,height
CGFloat const NavButtonWidth=33;
CGFloat const NavButtonHeight=32;

@interface MonitoringViewController ()<CLLocationManagerDelegate,UserInfoUpdateDelegate,NSURLConnectionDelegate,NSURLConnectionDataDelegate,CBCentralManagerDelegate,UIAlertViewDelegate,MBProgressHUDDelegate>

@property(nonatomic,strong)CBCentralManager *centralManager;

@property NSString *name;
@property NSUUID *uuid;
@property NSNumber *major;
@property NSNumber *minor;

@end

@implementation MonitoringViewController
@synthesize Rdata=_Rdata;
@synthesize isGetBeacon=_isGetBeacon;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initNavButton];
    //register with a notification center to request the state for beacon region(in/out)
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBeaconState) name:@"applicationWillEnterForeground" object:nil];
    self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    
    //Initializing the Location Manager
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = (id)self;
    [self.locationManager requestAlwaysAuthorization];//requesting authorization for location service
    self.locationManager.activityType = CLActivityTypeFitness;
    self.locationManager.distanceFilter = kCLLocationAccuracyBest;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    //検索されたビーコン情報は既にローカリに存在しているかどうかをチェック
    AppDelegate *delegate = [[UIApplication sharedApplication]delegate];

    NSString *home = NSHomeDirectory();
    NSString *docPath = [home stringByAppendingPathComponent:@"Documents"];
    NSString *plistPath = [docPath stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"%@.plist",delegate.useruuid]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    self.Locations = [NSMutableDictionary new];
    self.mybeacons = [NSMutableArray new];

    NSString *beaconpath =[docPath stringByAppendingPathComponent:[[NSString alloc]initWithFormat:  @"beaconlocation.plist"]];
    //NSLog(@"%@",beaconpath);
    
    if ([fileManager fileExistsAtPath:beaconpath]) {
        self.BeaconInfo = [[NSMutableDictionary alloc]initWithContentsOfFile:beaconpath];
        
    }
    
    if ([fileManager fileExistsAtPath:plistPath]) {
        NSMutableDictionary * userinfo = [[NSMutableDictionary alloc]initWithContentsOfFile:plistPath];
        delegate.username = [userinfo valueForKey:@"username"];
        NSString* strStatus2 = [userinfo valueForKey:@"status2"];
        
        if ([strStatus2 isEqualToString:@"1"]) {
            delegate.status2 = YES;
        }else{
            delegate.status2 = NO;
        }
        [self initCLBeaconRegion];
        [self startRequest];
    }else{
        [self startRequest];
        [self performSegueWithIdentifier:@"segueConfigure" sender:self];
    }
    
    self.tableView.tableFooterView = [[UIView alloc]init];
}


-(void)UserInfoUpdateEvent{
    [self initCLBeaconRegion];
}

//Initializing the Beacon Region
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
            NSLog(@"error");
        }
    }

}
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
            break;
            
        default:
            //NSLog(@"central manager did change state");
            break;
    }
}

//whether the app is authorized to use location services
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
            //NSLog(@"CASE kCLAuthorizationStatusNotDetermined");
            break;
        case kCLAuthorizationStatusRestricted:
            //NSLog(@"CASE kCLAuthorizationStatusRestricted");
            break;
        case kCLAuthorizationStatusDenied:
            //NSLog(@"CASE kCLAuthorizationStatusDenied");
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            //NSLog(@"CASE kCLAuthorizationStatusAuthorizedAlways");
            [self initCLBeaconRegion];
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            //NSLog(@"CASE kCLAuthorizationStatusAuthorizedWhenInUse");
            [self initCLBeaconRegion];
            break;
        default:
            break;
    }
}

//-(void)updateBeaconState{
//    for (int i=0; i<self.mybeacons.count; i++) {
//        CLBeaconRegion* reg = [self.mybeacons objectAtIndex:i];
//        [self.locationManager requestStateForRegion:reg];
//    }
//}

//Invoked when there's a state transition for a monitored region or in response to a request for state via a call to requestStateForRegion:.
//-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
//    
//    switch (state) {
//        case CLRegionStateInside:
//            [self updateUserStatus:@"1" beaconRegion:(CLBeaconRegion *)region];
//            NSLog(@"Inside %@",region.identifier);
//            break;
//        case CLRegionStateOutside:
//            [self updateUserStatus:@"0" beaconRegion:(CLBeaconRegion *)region];
//            NSLog(@"Outside %@",region.identifier);
//            break;
//        case CLRegionStateUnknown:
//            break;
//        default:
//            
//            break;
//    }
//    [self.tableView reloadData];
//}


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

//ーーーーーーーーーーーーーーーーーーーーー失敗した時、ログ情報を出力ーーーーーーーーーーーーーーーーーーーーーー
-(void) locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error{
    //NSLog(@"%@", error);
}

-(void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    //NSLog(@"%@", error);
    
}

-(void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error{
    //NSLog(@"%@", error);
}

//----------------------------NSURLRequest---------------------------------------------------
-(void)startRequest{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.isGetBeacon = YES;
    
    NSString *strURL = [[NSString alloc]initWithFormat:@"http://rdbeacon.azurewebsites.net/rdgetlocation.php"];
    NSURL *url = [NSURL URLWithString:strURL];
    
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    self.Rdata = nil;
    if (connection) {
        [connection start];
        self.Rdata = [NSMutableData new];
    }
}


//---------------------------didReceiveResponse(USURLConnectionDataDelegate)-----------------------------------------
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    [self.Rdata setLength:0];
    
}


//----------------------------didReceiveData(USURLConnectionDataDelegate)------------------------------------------
//每次收到一条数据，就会调用此函数
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{

    [self.Rdata appendData:data];
    
    
}
//----------------------------didFinishLoading(USURLConnectionDelegate协议的方法)------------------------------------------
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
//----------------------------didFailWithError(USURLConnectionDelegate)------------------------------------------
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

//----------------------------NSURLRequest update the states to server when enter/quit the beacon region器-------------------------------------
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

//create two navigation bar buttons
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
-(void)editAction{
    [self performSegueWithIdentifier:@"segueConfigure" sender:self];
}
-(void)membersAction{
    [self performSegueWithIdentifier:@"segueMember" sender:self];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"segueConfigure"]){
        ConfigureViewController *editVC= segue.destinationViewController;
        editVC.delegate = self;
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
