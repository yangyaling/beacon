//
//  ConfigureViewController.m
//  BeaconSample
//
//  Created by totyu1 on 2015/07/09.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import "ConfigureViewController.h"
#import "MBProgressHUD.h"

@interface ConfigureViewController ()<UITextFieldDelegate,NSURLConnectionDelegate,NSURLConnectionDataDelegate,MBProgressHUDDelegate>{
    MBProgressHUD *HUD;
    long long expectedLength;
    long long currentLength;
}

@property (weak, nonatomic) IBOutlet UILabel *labeluuid;
@property (weak, nonatomic) IBOutlet UITextField *textUserName;
@property (weak, nonatomic) IBOutlet UISwitch *switchStatus;
- (IBAction)savaAction:(id)sender;

@property (strong, nonatomic) NSMutableData *Rdata;
@property (strong, nonatomic) NSMutableDictionary *Rdict;

@end

@implementation ConfigureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 取得用户名，UUID，状态（保存在全局变量）
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    self.labeluuid.text = delegate.useruuid;
    self.textUserName.text  =delegate.username;
    self.switchStatus.on =delegate.status2;
    
}

/**
 保存／更新用户设置信息
 */
-(void)startRequest{
    NSString *uuid = self.labeluuid.text;
    NSString *username = self.textUserName.text;

    
    NSString *isBtnOn = @"0";
    if (_switchStatus.isOn) {
        isBtnOn = @"1";
    }else{
        isBtnOn = @"0";
    }
    
    // 参数
    NSString *post = [NSString stringWithFormat:@"uuid=%@&username=%@&status2=%@",uuid,username,isBtnOn];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    
    // 请求地址
    NSURL *url = [NSURL URLWithString:[[NSString alloc]initWithFormat:@"https://beaconapp2.chinacloudsites.cn/rdinsertuser.php"]];
    // 创建请求
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

#pragma mark - USURLConnectionDataDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    [self.Rdata setLength:0];
    expectedLength = MAX([response expectedContentLength], 1);
    
    currentLength = 0;
    HUD.mode = MBProgressHUDModeDeterminate;
    
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.Rdata appendData:data];//把data加到rdata最后
    
    currentLength += [data length];
    HUD.progress = currentLength / (float)expectedLength;
    
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:self.Rdata options:NSJSONReadingMutableLeaves error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.navigationItem.prompt = nil;
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"请稍后再试" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }else{
        //sava data to local
        NSString *home = NSHomeDirectory();
        NSString *docPath = [home stringByAppendingPathComponent:@"Documents"];
        
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        delegate.username = [dict valueForKey:@"username"];
        NSString* strStatus2 = [dict valueForKey:@"status2"];
        if ([strStatus2 isEqualToString:@"1"]) {
            delegate.status2 = YES;
        }else{
            delegate.status2 = NO;
        }
        
        NSString *plistPath = [docPath stringByAppendingPathComponent:[[NSString alloc]initWithFormat:@"%@.plist",delegate.useruuid]];
        [dict writeToFile:plistPath atomically:YES];

        HUD.labelText = @"更新成功";
        HUD.labelFont = [UIFont boldSystemFontOfSize:12.f];
        HUD.mode = MBProgressHUDModeCustomView;
        [HUD hide:YES afterDelay:1];
        
        [self.delegate UserInfoUpdateEvent];
        [self.navigationController popViewControllerAnimated:YES];
        
    }
    
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"FailWithError");
    
    HUD.labelText = @"インターネットに接続していません";
    HUD.labelFont = [UIFont boldSystemFontOfSize:12.f];
    HUD.mode = MBProgressHUDModeCustomView;
    [HUD hide:YES afterDelay:1];
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}


- (IBAction)savaAction:(id)sender {
    if ([self.textUserName.text isEqualToString:@""]) {
        UIAlertView *alert2 = [[UIAlertView alloc]initWithTitle:@"Error" message:@"请输入用户名" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert2 show];
    }else{
        [self startRequest];
        
    }
}

@end
