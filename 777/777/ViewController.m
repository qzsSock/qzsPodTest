//
//  ViewController.m
//  777
//
//  Created by 邱子硕 on 2020/6/15.
//  Copyright © 2020 邱子硕. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic,strong) NSString*three;

@property (nonatomic,strong) NSString*nnn;
@property (nonatomic,strong) NSString*hh;
@property (nonatomic,strong) UIView*oneView;
@property (nonatomic,strong) UIView*twoView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   UIImage*img = [UIImage imageNamed:@"timg"];
      NSData*imageData  = UIImageJPEGRepresentation(img, 0.05);
     NSString*  imageFormat = @"Content-Type: image/png \r\n";
     NSMutableData *body = [NSMutableData data];
      [body appendData:[self getDataWithString:@"--BOUNDARY\r\n" ]];
      NSString *disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@.png\"\r\n",@"file",@"filenameqzs"];
      [body appendData:[self getDataWithString:disposition ]];
      [body appendData:[self getDataWithString:imageFormat]];
      [body appendData:[self getDataWithString:@"\r\n"]];
      [body appendData:imageData];
      [body appendData:[self getDataWithString:@"\r\n\r\n"]];
     [body appendData:[self getDataWithString:@"\r\n"]];
      [body appendData:[self getDataWithString:@"--BOUNDARY\r\n" ]];
      NSString *dispositions = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n",@"serviceName"];
      [body appendData:[self getDataWithString:dispositions ]];
      [body appendData:[self getDataWithString:@"\r\n"]];
      [body appendData:[self getDataWithString:@"cases"]];
      [body appendData:[self getDataWithString:@"\r\n"]];
      [body appendData:[self getDataWithString:@"--BOUNDARY--\r\n"]];
    NSString*str = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
      NSLog(@"%@",str);
    
    [body appendData:[self getDataWithString:@"dsadadasd"]];
      [self addOneView];
     [self addTwoView];
  }

  - (NSData *)getDataWithString:(NSString *)string{
      NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
      return data;
  }

- (void)add0909
{
    NSLog(@"09090reales");
}
- (void)addOneView
{
    self.oneView = [[UIView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    self.oneView.backgroundColor = [UIColor redColor];
    [self.view addSubview:self.oneView];
}
- (void)addTwoView
{
    self.twoView = [[UIView alloc] initWithFrame:CGRectMake(100, 300, 100, 100)];
    self.twoView.backgroundColor = [UIColor blueColor];
    [self.view addSubview:self.twoView];
}

@end

