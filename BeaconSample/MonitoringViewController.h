//
//  MonitoringViewController.h
//  BeaconSample
//
//  Created by totyu1 on 2015/06/23.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreLocation;

@interface MonitoringViewController : UITableViewController

@property (nonatomic,strong) CLLocationManager *locationManager;

@property (strong,nonatomic) NSMutableDictionary *Rdict;
@property (strong,nonatomic) NSMutableDictionary *BeaconInfo;
@property (strong,nonatomic) NSMutableDictionary *Locations;


@end
