//
//  MemberTableViewController.m
//  BeaconSample
//
//  Created by totyu1 on 2015/06/24.
//  Copyright (c) 2015年 totyu1. All rights reserved.
//

#import "MemberTableViewController.h"
#import "DetailTableViewController.h"

@interface MemberTableViewController (){
    long long expectedLength;
    long long currentLength;
}

@end

@implementation MemberTableViewController
@synthesize Rdata;

- (void)viewDidLoad {
    [super viewDidLoad];
    //pull to refresh
    UIRefreshControl *refresh = [[UIRefreshControl alloc]init];
    refresh.attributedTitle = [[NSAttributedString alloc]initWithString:@"更新中"];
    [refresh addTarget:self action:@selector(startRequestAllUsersInfo) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refresh;
    
    [self startRequestAllUsersInfo];
    self.tableView.tableFooterView = [[UIView alloc]init];
}

//----------------------------NSURLRequest--------------------------------------------------
-(void)startRequestAllUsersInfo{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSString *strURL = [[NSString alloc]initWithFormat:@"https://beaconapp2.chinacloudsites.cn/rdgetalluserinfo.php"];
    NSURL *url = [NSURL URLWithString:strURL];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    self.Rdata = nil;
    if (connection) {
        [connection start];
        self.Rdata = [NSMutableData new];
    }
}
//---------------------------didReceiveResponse(USURLConnectionDataDelegate)-----------------------------------------
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    [self.Rdata setLength:0];
    expectedLength = MAX([response expectedContentLength], 1);
    currentLength = 0;
}


//----------------------------didReceiveData(USURLConnectionDataDelegate协议的方法)------------------------------------------
//每次收到一条数据，就会调用此函数
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.Rdata appendData:data];//把data加到rdata最后
    currentLength += [data length];
}
//----------------------------didFinishLoading(USURLConnectionDelegate协议的方法)------------------------------------------
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
    }
    
}
-(void)reloadTableView:(NSDictionary *)dict{
    self.Rdict = [[NSMutableDictionary alloc]initWithDictionary:dict];
    [self.tableView reloadData];
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (self.refreshControl) {
        [self.refreshControl endRefreshing];

    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.Rdict.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"mycell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(cell==nil){
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        
    }
    NSUInteger row = [indexPath row];
    NSArray *members = [self.Rdict allKeys];
    NSString *useruuid = [members objectAtIndex:row];

    NSMutableDictionary *userinfo = [self.Rdict objectForKey:useruuid];
    NSString *username = [userinfo valueForKey:@"username"];
    NSString *status = [userinfo valueForKey:@"status"];
    NSString *lasttime = [userinfo valueForKey:@"lasttime"];
    NSString *locationname =[userinfo valueForKey:@"locationname"];
    NSString *status2 = [userinfo valueForKey:@"status2"];
    UIImage *img = nil;
    
    if ((NSNull *)status ==[NSNull null]) {
        status =@"2";
    }
    switch ([status intValue]) {
        case 0:
            cell.imageView.image= [UIImage imageNamed:@"outline"];
            cell.textLabel.text =[[NSString alloc]initWithFormat:@"%@",username];
            cell.detailTextLabel.text = [[NSString alloc]initWithFormat:@"[不在] %@",lasttime];
            break;
        case 1:
            if ([status2  isEqual: @"1"]) {
                cell.imageView.image =[UIImage imageNamed:@"busy"];
                cell.textLabel.text =[[NSString alloc]initWithFormat:@"%@ %@",username,locationname];
                cell.detailTextLabel.text =[[NSString alloc]initWithFormat:@"[忙しい] %@",lasttime];
            }else{
                cell.imageView.image =[UIImage imageNamed:@"online"];
                cell.textLabel.text =[[NSString alloc]initWithFormat:@"%@ %@",username,locationname];
                cell.detailTextLabel.text =[[NSString alloc]initWithFormat:@"[在] %@",lasttime];
            }
            break;
        default:
            img= [UIImage imageNamed:@"outline"];
            cell.imageView.image =img;
            
            cell.textLabel.text =[[NSString alloc]initWithFormat:@"%@",username];
            cell.detailTextLabel.text = @"[不明]";
            break;
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;{
    [self performSegueWithIdentifier:@"segueDetail" sender:self];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSArray *members = [self.Rdict allKeys];
    NSString *uuid = [members objectAtIndex:[[self.tableView indexPathForSelectedRow]row]];
    NSString *username = [[self.Rdict objectForKey:uuid] valueForKey:@"username"];
    
    DetailTableViewController *detailview = segue.destinationViewController;
    
    detailview.title = username;
    detailview.uuid = uuid;
    
}

@end
