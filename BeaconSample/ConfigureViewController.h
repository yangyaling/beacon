//
//  ConfigureViewController.h
//  BeaconSample
//
//  Created by totyu1 on 2015/07/09.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@protocol UserInfoUpdateDelegate <NSObject>
-(void)UserInfoUpdateEvent;
@end
//--------------------------------------NSURLConnectionDelegate-------------------------------
@interface ConfigureViewController : UIViewController<UITextFieldDelegate,NSURLConnectionDelegate,NSURLConnectionDataDelegate>
@property (weak, nonatomic) IBOutlet UILabel *labeluuid;
@property (weak, nonatomic) IBOutlet UITextField *textUserName;
@property (weak, nonatomic) IBOutlet UISwitch *switchStatus;
- (IBAction)savaAction:(id)sender;

@property (strong, nonatomic) NSMutableData *Rdata;
@property (strong, nonatomic) NSMutableDictionary *Rdict;

@property (nonatomic, assign) id<UserInfoUpdateDelegate>delegate;

@end
