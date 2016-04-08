//
//  AppDelegate.h
//  mimamorarerugawaApp
//
//  Created by totyu2 on 2016/01/07.
//  Copyright © 2016年 totyu2. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface BGTask : NSObject
+(instancetype)shareBGTask;
-(UIBackgroundTaskIdentifier)beginNewBackgroundTask; //开启后台任务
@end
