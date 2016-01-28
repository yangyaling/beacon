//
//  ConfigureViewController.m
//  BeaconSample
//
//  Created by totyu1 on 2015/07/09.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import "ConfigureViewController.h"
#import "MBProgressHUD.h"

@interface ConfigureViewController ()<MBProgressHUDDelegate>{
    MBProgressHUD *HUD;
    long long expectedLength;
    long long currentLength;
}

@end

@implementation ConfigureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //get the device's uuid,username
    AppDelegate *delegate = [[UIApplication sharedApplication]delegate];
    self.labeluuid.text = delegate.useruuid;
    self.textUserName.text  =delegate.username;
    
    self.switchStatus.on =delegate.status2;
    
}

//------------------NSMutableURLRequest(POST)----------------------------------
-(void)startRequest{
    NSString *uuid = self.labeluuid.text;
    NSString *username = self.textUserName.text;
    
    NSString *strURL = [[NSString alloc]initWithFormat:@"http://rdbeacon.azurewebsites.net/rdinsertuser.php"];
    NSURL *url = [NSURL URLWithString:strURL];
    
    NSString* isBtnOn = @"0";
    if (_switchStatus.isOn) {
        isBtnOn = @"1";
    }else{
        isBtnOn = @"0";
    }
    
    
    NSString *post = [NSString stringWithFormat:@"uuid=%@&username=%@&status2=%@",uuid,username,isBtnOn];
    NSLog(@"post:%@",post);
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    if(connection){
        self.Rdata = [NSMutableData new];
        
        HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        HUD.delegate = self;
    }
    
}

//---------------------------didReceiveResponse(USURLConnectionDataDelegate)-----------------------------------------
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"get the response");
    [self.Rdata setLength:0];
    expectedLength = MAX([response expectedContentLength], 1);
    
    currentLength = 0;
    HUD.mode = MBProgressHUDModeDeterminate;
    
}

//----------------------------didReceiveData(USURLConnectionDataDelegate)------------------------------------------
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSLog(@"get some data");
    [self.Rdata appendData:data];//把data加到rdata最后
    
    currentLength += [data length];
    HUD.progress = currentLength / (float)expectedLength;
    
    
}


//----------------------------didFinishLoading(USURLConnectionDelegate)------------------------------------------
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:self.Rdata options:NSJSONReadingMutableLeaves error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.navigationItem.prompt = nil;
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"データ解析が失敗しました。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }else{
        
        //sava data to local
        NSString *home = NSHomeDirectory();
        NSString *docPath = [home stringByAppendingPathComponent:@"Documents"];
        AppDelegate *delegate = [[UIApplication sharedApplication]delegate];
        delegate.username = [dict valueForKey:@"username"];
        NSString* strStatus2 = [dict valueForKey:@"status2"];
        if ([strStatus2 isEqualToString:@"1"]) {
            delegate.status2 = YES;
        }else{
            delegate.status2 = NO;
        }
        
        NSString *plistPath = [docPath stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"%@.plist",delegate.useruuid]];
        [dict writeToFile:plistPath atomically:YES];
        NSLog(@"%@",plistPath);
        HUD.labelText = @"登録は完成しました";
        HUD.labelFont = [UIFont boldSystemFontOfSize:12.f];
        HUD.mode = MBProgressHUDModeCustomView;
        [HUD hide:YES afterDelay:1];
        
        [self.delegate UserInfoUpdateEvent];
        [self.navigationController popViewControllerAnimated:YES];
        
    }
    
}

//----------------------------didFailWithError(USURLConnectionDelegate)------------------------------------------
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"FailWithError");
    
    HUD.labelText = @"インターネットに接続していません";
    HUD.labelFont = [UIFont boldSystemFontOfSize:12.f];
    HUD.mode = MBProgressHUDModeCustomView;
    [HUD hide:YES afterDelay:1];
}

//return the keyboard
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)savaAction:(id)sender {
    if ([self.textUserName.text isEqualToString:@""]) {
        UIAlertView *alert2 = [[UIAlertView alloc]initWithTitle:@"Error" message:@"名前を入力してください" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert2 show];
    }else{
        [self startRequest];
        
    }
}

@end
