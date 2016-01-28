//
//  InterfaceController.m
//  RDBeacon WatchKit Extension
//
//  Created by totyu1 on 2015/07/07.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import "InterfaceController.h"
#import "mainRowType.h"

@interface InterfaceController()
@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    NSLog(@"awakeWithContext");
    
}

//----------------------------NSURLRequest(异部请求)访问服务器---------------------------------------------------
-(void)startRequestAllUsersInfo{

    NSString *strURL = [[NSString alloc]initWithFormat:@"http://rdbeacon.azurewebsites.net/rdgetalluserinfo.php"];
    NSURL *url = [NSURL URLWithString:strURL];//设置请求路径
    
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];//创建请求对象
    
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    self.Rdata = nil; //创建一个rdata做数据的接收
    if (connection) {
        [connection start];
        self.Rdata = [NSMutableData new];
    }
}
//---------------------------didReceiveResponse(USURLConnectionDataDelegate委托函数)-----------------------------------------
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"get the response");
    [self.Rdata setLength:0];
    
}


//----------------------------didReceiveData(USURLConnectionDataDelegate协议的方法)------------------------------------------
//每次收到一条数据，就会调用此函数
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSLog(@"get some data");
    [self.Rdata appendData:data];//把data加到rdata最后
    
    
}
//----------------------------didFinishLoading(USURLConnectionDelegate协议的方法)------------------------------------------
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    NSError *error;
    //将JSON数据转换为foundation对象(一般是NSDictionary 或 NSArray)
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:self.Rdata options:NSJSONReadingMutableLeaves error:&error];

    if (error) {
        NSLog(@"error");
    }else{
        self.Rdict = [[NSMutableDictionary alloc]initWithDictionary:dict];
        [self configureTableWithData:self.Rdict];
        NSLog(@"didTableViewReloaded");
    }
}


-(void)configureTableWithData:(NSMutableDictionary *)Rdict{
    
    static NSString *rowType = @"memberRow";
    NSArray *members = [self.Rdict allKeys];
    [self.table setNumberOfRows:members.count withRowType:rowType];
    NSLog(@"%@",members);
    
    for (NSInteger i=0; i<self.table.numberOfRows; i++) {
        NSString *useruuid = [members objectAtIndex:i];
        NSMutableDictionary *userinfo = [self.Rdict objectForKey:useruuid];
        NSString *username = [userinfo valueForKey:@"username"];
        NSString *status = [userinfo valueForKey:@"status"];
        NSString *locationname = [userinfo valueForKey:@"locationname"];
        mainRowType *theRow = [self.table rowControllerAtIndex:i];
        [theRow.members setText:username];
        
        
        switch ([status intValue]) {
            case 0:
                [theRow.image setImageNamed:@"outline"];
                [theRow.location setText:@""];
                break;
            case 1:
                [theRow.image setImageNamed:@"online"];
                [theRow.location setText:locationname];
                break;
            default:
                
                break;
        }
    }

}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    

    [super willActivate];
    [self startRequestAllUsersInfo];
    NSLog(@"willActivate");
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



