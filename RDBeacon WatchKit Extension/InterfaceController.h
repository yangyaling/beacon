//
//  InterfaceController.h
//  RDBeacon WatchKit Extension
//
//  Created by totyu1 on 2015/07/07.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController
@property (strong, nonatomic) NSMutableData *Rdata;
@property (strong, nonatomic) NSMutableDictionary *Rdict;
@end
