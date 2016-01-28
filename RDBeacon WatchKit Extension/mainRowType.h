//
//  mainRowType.h
//  BeaconSample
//
//  Created by totyu1 on 2015/07/08.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import <Foundation/Foundation.h>
@import WatchKit;

@interface mainRowType : NSObject
@property (weak, nonatomic) IBOutlet WKInterfaceImage *image;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *members;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *location;


@end
