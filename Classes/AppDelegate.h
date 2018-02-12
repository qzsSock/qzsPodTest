//
//  AppDelegate.h
//  SXparent
//
//  Created by HuangSui on 16/9/18.
//  Copyright © 2016年 SuiXun. All rights reserved.
//

#import <UIKit/UIKit.h>
static NSString *appKey = @"beccc651f7d0cdb713228d17";
//并不重要
static NSString *channel = @"Publish channel";
static BOOL isProduction = FALSE;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
-(void)switchController;

@end

