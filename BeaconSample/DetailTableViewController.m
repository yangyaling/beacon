//
//  DetailTableViewController.m
//  BeaconSample
//
//  Created by totyu1 on 2015/06/25.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import "DetailTableViewController.h"
#import "MBProgressHUD.h"

@interface DetailTableViewController ()<MBProgressHUDDelegate>{
    MBProgressHUD *HUD;
    long long expectedLength;
    long long currentLength;
}


@end

@implementation DetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc]init];
    refresh.attributedTitle = [[NSAttributedString alloc]initWithString:@"更新中"];
    [refresh addTarget:self action:@selector(startRequestAllUsersInfo) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;
    
    [self startRequestAllUsersInfo];
    self.tableView.tableFooterView = [[UIView alloc]init];
}

//----------------------------NSURLRequest()---------------------------------------------------
-(void)startRequestAllUsersInfo{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    
    NSString *strURL = [[NSString alloc]initWithFormat:@"https://beaconapp.chinacloudsites.cn/rdgetmonitorinfo.php?uuid=%@",self.uuid];
    NSURL *url = [NSURL URLWithString:strURL];
    
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    self.Rdata = nil;
    if (connection) {
        [connection start];
        self.Rdata = [NSMutableData new];
        HUD = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        HUD.delegate = self;
    }
}
//---------------------------didReceiveResponse(USURLConnectionDataDelegate)-----------------------------------------
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
//    NSLog(@"get the response");
    [self.Rdata setLength:0];
    expectedLength = MAX([response expectedContentLength], 1);
    currentLength = 0;
    HUD.mode = MBProgressHUDModeDeterminate;
    
}


//----------------------------didReceiveData(USURLConnectionDataDelegate)------------------------------------------
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
//    NSLog(@"get some data");
    [self.Rdata appendData:data];
    currentLength += [data length];
    HUD.progress = currentLength / (float)expectedLength;
    
    
}
//----------------------------didFinishLoading(USURLConnectionDelegate)------------------------------------------
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:self.Rdata options:NSJSONReadingMutableLeaves error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.navigationItem.prompt = nil;
    [self.refreshControl endRefreshing];
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"データ解析が失敗しました。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }else{
        [self reloadTableView:dict];
//        NSLog(@"didTableViewReloaded");
       
    }
    
}
-(void)reloadTableView:(NSDictionary *)dict{
    if(dict.count>0){
        self.Rdict = [[NSMutableDictionary alloc]initWithDictionary:dict];
        [self.tableView reloadData];
//        NSLog(@"%@",self.Rdict);
        [HUD hide:YES];
    }else{
        HUD.labelText = @"出入りの記録はないです";
        HUD.labelFont = [UIFont boldSystemFontOfSize:12.f];
        HUD.mode = MBProgressHUDModeCustomView;
        [HUD show:YES];
        [HUD hide:YES afterDelay:1];
    }
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    if (self.refreshControl) {
        [self.refreshControl endRefreshing];
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSLog(@"FailWithError");
    
    HUD.labelText = @"インターネットに接続していません";
    HUD.labelFont = [UIFont boldSystemFontOfSize:12.f];
    HUD.mode = MBProgressHUDModeCustomView;
    [HUD hide:YES afterDelay:1];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

     return self.Rdict.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"celldetail";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(cell==nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        
    }
    NSUInteger row = [indexPath row];
    NSArray *listmonitortmp = [self.Rdict allKeys];
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc]initWithKey:nil ascending:NO];
    NSArray *sortArray = [NSArray arrayWithObjects:descriptor, nil];
    NSArray *listmonitor = [listmonitortmp sortedArrayUsingDescriptors:sortArray];
    NSString *monitorindex =[listmonitor objectAtIndex:row];
    NSMutableDictionary *userinfo =[self.Rdict objectForKey:monitorindex];
    NSString* status = [userinfo valueForKey:@"status"];
    NSString* updatetime =[userinfo valueForKey:@"updatetime"];
    NSString* locationname=[userinfo valueForKey:@"location"];
    UIImage *img = nil;
    
    switch ([status intValue]) {
        case 0:
            cell.imageView.image= [UIImage imageNamed:@"getout"];
            cell.textLabel.text =[[NSString alloc]initWithFormat:@"[out] %@",locationname];
            cell.detailTextLabel.text = [[NSString alloc]initWithFormat:@"更新時間:%@",updatetime];
            break;
        case 1:
            cell.imageView.image =[UIImage imageNamed:@"getin"];
            cell.textLabel.text =[[NSString alloc]initWithFormat:@"[in] %@",locationname];
            cell.detailTextLabel.text =[[NSString alloc]initWithFormat:@"更新時間:%@",updatetime];
            break;
        default:
            img= [UIImage imageNamed:@"question"];
            cell.imageView.image =img;
            
            cell.textLabel.text =[[NSString alloc]initWithFormat:@"[不明]"];
            cell.detailTextLabel.text = @"[更新無し]";
            break;
    }

    return cell;
}


@end
