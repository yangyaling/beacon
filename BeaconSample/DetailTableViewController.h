//
//  DetailTableViewController.h
//  BeaconSample
//
//  Created by totyu1 on 2015/06/25.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailTableViewController : UITableViewController
@property (strong,nonatomic) NSMutableData *Rdata;
@property (strong,nonatomic) NSMutableDictionary *Rdict;

@property (strong,nonatomic) NSString* uuid;
@end
