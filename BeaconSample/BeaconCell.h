//
//  BeaconCell.h
//  BeaconSample
//
//  Created by totyu1 on 2015/06/29.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BeaconCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *locationName;
@property (weak, nonatomic) IBOutlet UILabel *proximity;
@property (weak, nonatomic) IBOutlet UILabel *uuidLabel;
@property (weak, nonatomic) IBOutlet UILabel *majorLabel;
@property (weak, nonatomic) IBOutlet UILabel *minorLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusImage;
@property (weak, nonatomic) IBOutlet UILabel *accuracyLabel;



@end
