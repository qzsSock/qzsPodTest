//
//  AppDelegate.m
//  SXparent
//
//  Created by HuangSui on 16/9/18.
//  Copyright © 2016年 SuiXun. All rights reserved.
//

#import "AppDelegate.h"
#import "SystemViewController.h"     //首页
#import "GuideViewController.h"      //引导展示
#import <SystemConfiguration/CaptiveNetwork.h> //获取当前wifi的macIp

#import "YJYViewController.h"
#import "BGViewController.h"
#import "BaseNavViewController.h"
#import "JPUSHService.h"
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

#import <AMapFoundationKit/AMapFoundationKit.h>//高德地图
#import <AMapLocationKit/AMapLocationKit.h>//高德地图

#import "PaymentViewController.h"
#import "customWebViewController.h"
#import "detailAttendanceViewController.h"

@interface AppDelegate ()<JPUSHRegisterDelegate, AMapLocationManagerDelegate>
{
    NSString *msgid;
    BOOL login;
    NSTimer *_timer;
    dispatch_semaphore_t _sema;//控制发送MAC地址网络请求次数
}

@property (nonatomic, strong) AMapLocationManager *locationManager;//高德地图定位管理器
@property (nonatomic, assign) CLLocationCoordinate2D currentLocation;//当前位置;
@property (nonatomic, copy) NSString *currentMacIp;//当前wifi的mac地址

@end

@implementation AppDelegate

#pragma mark LifeCircle生命周期
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window=[[UIWindow alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    UIImageView *backgroundImg=[[UIImageView alloc]initWithFrame:self.window.frame];
    backgroundImg.image=[UIImage imageNamed:@"登录-背景.jpg"];
    [self.window addSubview:backgroundImg];
    self.currentMacIp = @"";
    self.currentLocation = CLLocationCoordinate2DMake(0, 0);
    _sema = dispatch_semaphore_create(1);
    //监控网络环境
    [self networkMonitor];
    
    //极光推送配置
    [self configJPushWithOptions:launchOptions];
    // 启动百度移动统计
    [self startBaiduMobileStat];
    //配置高德地图
    [self configLocationManager];
    //切换页面
    [self switchController];
    //验证密码
    [self loginRequest];
    
    [self.locationManager startUpdatingLocation];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [application setApplicationIconBadgeNumber:0];
    [application cancelAllLocalNotifications];
    login=NO;
    [self loginRequest];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    /// Required - 注册 DeviceToken
    [JPUSHService registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    //极光推送注册失败
    [NetworkPath showHUD:@"推送注册失败" andView:self.window];
}

#pragma mark 自定义方法

-(void)configJPushWithOptions:(NSDictionary *)launchOptions {
    //极光注册
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        JPUSHRegisterEntity * entity = [[JPUSHRegisterEntity alloc] init];
        entity.types = UNAuthorizationOptionAlert|UNAuthorizationOptionBadge|UNAuthorizationOptionSound;
        [JPUSHService registerForRemoteNotificationConfig:entity delegate:self];
    }else if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        //可以添加自定义categories
        [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                          UIUserNotificationTypeSound |
                                                          UIUserNotificationTypeAlert)
                                              categories:nil];
    }else{
        //categories 必须为nil
        [JPUSHService registerForRemoteNotificationTypes:(UNAuthorizationOptionBadge |
                                                          UNAuthorizationOptionSound |
                                                          UNAuthorizationOptionAlert)
                                              categories:nil];
    }
    //Required
    // init Push(2.1.5版本的SDK新增的注册方法，改成可上报IDFA，如果没有使用IDFA直接传nil  )
    // 如需继续使用pushConfig.plist文件声明appKey等配置内容，请依旧使用[JPUSHService setupWithOption:launchOptions]方式初始化。
    [JPUSHService setupWithOption:launchOptions appKey:appKey
                          channel:channel
                 apsForProduction:isProduction
            advertisingIdentifier:nil];
    [JPUSHService setLogOFF];
}

/**
 配置locationManager
 */
- (void)configLocationManager
{
    [AMapServices sharedServices].apiKey = @"93176e886ca64c89cb0bf5905344cd4c";
    self.locationManager = [[AMapLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 9) {
        //iOS 9（不包含iOS 9） 之前设置允许后台定位参数，保持不会被系统挂起
        [self.locationManager setPausesLocationUpdatesAutomatically:NO];
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
        //iOS 9（包含iOS 9）之后新特性：将允许出现这种场景，同一app中多个locationmanager：一些只能在前台定位，另一些可在后台定位，并可随时禁止其后台定位。
        self.locationManager.allowsBackgroundLocationUpdates = YES;
    }
}


/**
 启动百度移动统计
 */
- (void)startBaiduMobileStat{
    
    BaiduMobStat* statTracker = [BaiduMobStat defaultStat];
    // 此处(startWithAppId之前)可以设置初始化的可选参数，具体有哪些参数，可详见BaiduMobStat.h文件，例如：
    statTracker.shortAppVersion  = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    statTracker.enableExceptionLog=NO;
    if ([APPBaseUrl isEqualToString:@"http://api.17find.com"]) {
        statTracker.channelId=@"AppStore";
    }else{
        statTracker.channelId=@"Pre";
    }
    
    [statTracker startWithAppId:@"8e44321d0c"];
}

/**
 监控网络环境
 */
-(void)networkMonitor
{
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status)
     {
         if (status==0) {
             
             UIWindow *sysWindow=[[UIApplication sharedApplication].windows lastObject];
             [NetworkPath showHUD:@"请确认您的手机网络状态是否连接！" andView:sysWindow];
         }
     }];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

-(void)switchController
{
    [self dataDeault];
    
    //如果已经展示过 缓存来自GuideViewController
    if ([UDF objectForKey:@"isShowGuide"]) {
        //判断token
        //登录过直接进首页
        if (![NSString isNULLString:APPTOKEN]) {
            
            //自定义TabBarController
            //先注册推送别名
            
            [JPUSHService setTags:nil alias:ACCount fetchCompletionHandle:^(int iResCode, NSSet *iTags, NSString *iAlias) {
                
                if (iResCode!=0) {
                    [NetworkPath showHUD:@"极光设置别名失败" andView:self.window];
                }else{
                    NSLog(@"极光设置别名成功%@*****%d",ACCount,iResCode);
                }
            }];
            SystemViewController *tabVC = [[SystemViewController alloc]init];
            self.window.rootViewController = tabVC;
        }else{
            //没登录过进登录页面
            
            login=YES;
            BGViewController *vc=[[BGViewController alloc]init];
            BaseNavViewController *nav=[[BaseNavViewController alloc]initWithRootViewController:vc];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"移除弹窗" object:self userInfo:nil];
            
            if ([UIApplication sharedApplication].applicationState==UIApplicationStateActive) {
                self.window.rootViewController=nav;
            }else{
                UIViewController *appRootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
                
                if (appRootVC.presentedViewController) {
                    [appRootVC.presentedViewController dismissViewControllerAnimated:YES completion:^{
                        self.window.rootViewController=nav;
                    }];
                }else{
                    self.window.rootViewController=nav;
                }
            }
        }
        
    }else{
        GuideViewController *vc=[[GuideViewController alloc]init];
        self.window.rootViewController=vc;
        
    }
    
    [self.window makeKeyAndVisible];
    
}

/**
 模态方式获取
 
 @return 当前VC
 */
- (UIViewController *)getPresentedViewController
{
    UIViewController *appRootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *topVC = appRootVC;
    if (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    
    return topVC;
}

/**
 认证提醒
 */
-(void)dataDeault
{
    //5天提醒
    [UDF setObject:@"100" forKey:@"endAlert"];
    //认证提醒
    [UDF setObject:@"100" forKey:@"CerAlert"];
}

/**
 获取当前wifi的MAC地址
 
 @return 当前的MAC地址
 */
-(NSString *)getCurrentWifiMacIp {
    NSString *macIp = @"Not Found";
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        CFRelease(myArray);
        if (myDict != nil) {
            NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
            macIp = [dict valueForKey:@"BSSID"];
        }
    }
    
    return macIp;
}

-(void)showAlterView:(NSString *)title andContent:(NSString *)content isEnter:(BOOL)_enter {
    
    if ([title isEqualToString:@"套餐提醒"]) {
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *noAction=[UIAlertAction actionWithTitle:@"下次提醒" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        UIAlertAction *someAction=[UIAlertAction actionWithTitle:@"我要缴费" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            
            PaymentViewController *vc=[[PaymentViewController alloc]init];
            UIViewController *baseVC=[self topViewControllerWithRootViewController:self.window.rootViewController];
            
            [baseVC.navigationController pushViewController:vc animated:YES];
            
        }];
        
        [alertController addAction:noAction];
        [alertController addAction:someAction];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        
    }else if ([title isEqualToString:@"到校提醒"]||[title isEqualToString:@"到家提醒"]||[title isEqualToString:@"离校提醒"]||[title isEqualToString:@"考勤提醒"]) {
        
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *noAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        UIAlertAction *someAction=[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertController addAction:noAction];
        [alertController addAction:someAction];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
    }else if ([title isEqualToString:@"cancelbaby"]) {
        
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:@"温馨提示" message:content preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *noAction=[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertController addAction:noAction];
        
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
    }else if ([title isEqualToString:@"定位成功"] ||[title isEqualToString:@"定位失败"]) {
        //首页主动定位
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:content delegate:self cancelButtonTitle:@"我知道了" otherButtonTitles:nil, nil];
        [alertView show];
        //通过通知中心发送通知
        NSDictionary *packDic=[NSDictionary dictionaryWithObjectsAndKeys:title,@"title",content,@"content", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"定位通知" object:self userInfo:packDic];
        
    }else if ([title isEqualToString:@"防火墙设置失败"] ||[title isEqualToString:@"蓝牙设置失败"]||[title isEqualToString:@"静音同步失败"]||[title isEqualToString:@"定位模式同步失败"]||[title isEqualToString:@"闹钟同步失败"]||[title isEqualToString:@"监护成员同步失败"]) {
        //找设备
        //失败后复位通知
        
        UIViewController *vc=[self topViewControllerWithRootViewController:self.window.rootViewController];
        [NetworkPath showHUD:title andView:vc.view];
        
        NSDictionary *packDic=[NSDictionary dictionaryWithObjectsAndKeys:title,@"title",content,@"content", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"失败通知" object:self userInfo:packDic];
        
    }else if ([title isEqualToString:@"防火墙设置成功"] ||[title isEqualToString:@"蓝牙设置成功"]||[title isEqualToString:@"静音同步成功"]||[title isEqualToString:@"定位模式同步成功"]||[title isEqualToString:@"闹钟同步成功"]||[title isEqualToString:@"监护成员同步成功"]) {
        
        UIViewController *vc=[self topViewControllerWithRootViewController:self.window.rootViewController];
        [NetworkPath showHUD:title andView:vc.view];
        NSDictionary *packDic=[NSDictionary dictionaryWithObjectsAndKeys:title,@"title",content,@"content", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"失败通知" object:self userInfo:packDic];
        
    }else if ([title isEqualToString:@"添加提醒"]) {
        
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *noAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        UIAlertAction *someAction=[UIAlertAction actionWithTitle:@"前往查看" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertController addAction:noAction];
        [alertController addAction:someAction];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
    }else if ([title isEqualToString:@"SOS报警"]||[title isEqualToString:@"低电量报警"]||[title isEqualToString:@"达到安全区域"]||[title isEqualToString:@"离开安全区域"]||[title isEqualToString:@"续费提醒"]||[title isEqualToString:@"学校通知"]||[title isEqualToString:@"关爱提醒"]){
        
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *noAction=[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertController addAction:noAction];
        
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        
    }else if ([title isEqualToString:@"yijiaoyunmsg"]) {
        
        NSArray *_yjyArray = [content componentsSeparatedByString:@"$$"];
        if (_yjyArray.count<3) {
            return;
        }
        if (_enter==YES) {
            UIAlertController *alertController=[UIAlertController alertControllerWithTitle:_yjyArray[0] message:_yjyArray[1] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *noAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            UIAlertAction *someAction=[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                customWebViewController *yjyVC = [[customWebViewController alloc]init];
                yjyVC.urlStr=_yjyArray[2];
                
                
                UIViewController *vc=[self topViewControllerWithRootViewController:self.window.rootViewController];
                [vc.navigationController pushViewController:yjyVC animated:YES];
            }];
            
            [alertController addAction:noAction];
            [alertController addAction:someAction];
            
            [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
            
        }else{
            customWebViewController *yjyVC = [[customWebViewController alloc]init];
            yjyVC.urlStr=_yjyArray[2];
            
            UIViewController *vc=[self topViewControllerWithRootViewController:self.window.rootViewController];
            [vc.navigationController pushViewController:yjyVC animated:YES];
        }
        
    }else{
        
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *noAction=[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertController addAction:noAction];
        
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
    }
    
}

//获取当前屏幕显示的viewcontroller
- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
    
}

#pragma mark 网络请求

-(void)loginRequest
{
    if ([NSString isNULLString:ACCount] ||[NSString isNULLString:PWD]) {
        return;
    }
    
    NSString *url=[NSString stringWithFormat:@"%@/app/user/login",APPBaseUrl];
    NSString *appversion=[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *devicemodel=[NetworkPath iphoneType];
    NSString *os=[[UIDevice currentDevice] systemVersion];
    NSDictionary *postDic = @{@"account": ACCount,@"password":PWD,@"appversion":appversion,@"devicemodel":devicemodel,@"os":os};
    
    [NetworkPath requestWithMethod:0 andURLString:url andParameters:postDic andView:self.window RequestSuccess:^(NSURLResponse *response, id responseObject)
     {
        LRLog(@"responseObject\n%@",responseObject);
         NSString *code = responseObject[@"code"];
         if([code isEqualToString:@"10008"]){
             
         }else{
             //清除token，重新登录
             //这里是分线程操作，在当前Appdelegate进行的话会出现多个界面
             [UDF removeObjectForKey:@"token"];
             [UDF removeObjectForKey:@"PassWord"];
             //启动时不会走，切换到前台会走这里，但是登录页面被替换，不会出现两个
             if (login==YES) {
                 
             }else{
                 [self switchController];
             }
             
         }
         
     } RequestFailed:^(NSError *error) {
         //清除token，重新登录
         //         [UDF removeObjectForKey:@"token"];
         //         [self switchController];
     }];
}


/**
 向服务端发送当前的MAC地址和定位
 */
-(void)sendMacIdAndCurrentLocationToServer {
    NSString *mac = _currentMacIp;
    NSString *lat = [NSString stringWithFormat:@"%f", _currentLocation.latitude];
    NSString *lng = [NSString stringWithFormat:@"%f", _currentLocation.longitude];
    NSString *url=[NSString stringWithFormat:@"%@/poi/wifi",APPBaseUrl];
    NSDictionary *postDic = @{@"mac":mac,@"lng":lng,@"lat":lat,@"type":@"baidu",@"os":@"ios"};
    
    [NetworkPath requestWithMethod:1 andURLString:url andParameters:postDic andView:self.window RequestSuccess:^(NSURLResponse *response, id responseObject) {
    } RequestFailed:^(NSError *error) {
    }];
}

#pragma mark - AMapLocationManagerDelegate
- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode
{
    [_locationManager stopUpdatingLocation];
    //获取到定位信息，发送经纬度给后端
    CLLocationCoordinate2D currentLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
    NSString *currentMacIp = [self getCurrentWifiMacIp];
    
    __weak typeof(self) weakSelf = self;
    __strong typeof(self) strongSelf = weakSelf;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
        LRLog(@"当前Wifi的MAC地址:%@, 经纬度：%f,%f", currentMacIp, currentLocation.latitude, currentLocation.longitude);
        // 每隔五分钟给服务端发送一次当前Wifi的Mac地址，以及当前的用户位置。如果两者都没有变则不向服务端发送
        if (![_currentMacIp isEqualToString:currentMacIp] ||
            _currentLocation.latitude != currentLocation.latitude  ||
            _currentLocation.longitude != currentLocation.longitude ) {
            if (![currentMacIp isEqualToString:@"Not Found"]) {
                _currentLocation = currentLocation;
                _currentMacIp = currentMacIp;
                [strongSelf sendMacIdAndCurrentLocationToServer];
            }
        }
        // 每隔五分钟进行一次定位
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, SendLocationTimerInterval * NSEC_PER_SEC);
        dispatch_after(delayTime, dispatch_get_main_queue(), ^(void){
            [strongSelf.locationManager startUpdatingLocation];
            dispatch_semaphore_signal(_sema);
        });
        
    });
    
    return;
}



#pragma mark- JPUSHRegisterDelegate

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler {
    LRLog(@"前台");
    // Required
    NSDictionary * userInfo = notification.request.content.userInfo;
    
    
    NSString *msgidStr=[NSString stringWithFormat:@"%@",[userInfo valueForKey:@"_j_msgid"]];
    NSString *title = [userInfo valueForKey:@"title"];
    NSString *content = [userInfo valueForKey:@"content"];
    
    
    NSString *timingpic=[userInfo valueForKey:@"timingpic"];
    if ([NSString isNULLString:timingpic]) {
        
    }else{
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *noAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        
        UIAlertAction *someAction=[UIAlertAction actionWithTitle:@"查看详情" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            detailAttendanceViewController *vc=[[detailAttendanceViewController alloc]init];
            vc.content=[NSString stringWithFormat:@"%@",content];
            vc.queryid=[NSString stringWithFormat:@"%@",timingpic];
            UIViewController *baseVC=[self topViewControllerWithRootViewController:self.window.rootViewController];
            
            [baseVC.navigationController pushViewController:vc animated:YES];
            
            
        }];
        
        [alertController addAction:noAction];
        [alertController addAction:someAction];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    [NetworkPath replaceNullData:msgid];
    if ([msgid isEqualToString:msgidStr]) {
        return;
    }else{
        msgid=msgidStr;
        //判断是不是在App内
        BOOL _enter;
        
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive){
            _enter=YES;
        }else{
            _enter=NO;
        }
        
        //把bool 值带过去
        [self showAlterView:title andContent:content isEnter:_enter];
    }
    
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    }
    completionHandler(UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
}

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    
    LRLog(@"未开启或后台");
    // Required
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    LRLog(@"find%@",userInfo);
    NSString *msgidStr=[NSString stringWithFormat:@"%@",[userInfo valueForKey:@"_j_msgid"]];
    NSString *title = [userInfo valueForKey:@"title"];
    NSString *content = [userInfo valueForKey:@"content"];
    
    
    NSString *timingpic=[userInfo valueForKey:@"timingpic"];
    if ([NSString isNULLString:timingpic]) {
        
    }else{
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *noAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        
        UIAlertAction *someAction=[UIAlertAction actionWithTitle:@"查看详情" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            detailAttendanceViewController *vc=[[detailAttendanceViewController alloc]init];
            vc.content=[NSString stringWithFormat:@"%@",content];
            vc.queryid=[NSString stringWithFormat:@"%@",timingpic];
            UIViewController *baseVC=[self topViewControllerWithRootViewController:self.window.rootViewController];
            
            [baseVC.navigationController pushViewController:vc animated:YES];
            
            
        }];
        
        [alertController addAction:noAction];
        [alertController addAction:someAction];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    [NetworkPath replaceNullData:msgid];
    if ([msgid isEqualToString:msgidStr]) {
        return;
    }else{
        msgid=msgidStr;
        //判断是不是在App内
        BOOL _enter;
        
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive){
            _enter=YES;
        }else{
            _enter=NO;
        }
        
        //把bool 值带过去
        [self showAlterView:title andContent:content isEnter:_enter];
    }
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    }
    completionHandler();  // 系统要求执行这个方法
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    LRLog(@"777777");
    // Required, iOS 7 Support
    [JPUSHService handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
    LRLog(@"收到通知Remote%@",userInfo);
    
    NSString *msgidStr=[NSString stringWithFormat:@"%@",[userInfo valueForKey:@"_j_msgid"]];
    NSString *title = [userInfo valueForKey:@"title"];
    NSString *content = [userInfo valueForKey:@"content"];
    NSString *timingpic=[userInfo valueForKey:@"timingpic"];
    
    if ([NSString isNULLString:timingpic]) {
        
    }else{
        
        UIAlertController *alertController=[UIAlertController alertControllerWithTitle:title message:content preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *noAction=[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        
        UIAlertAction *someAction=[UIAlertAction actionWithTitle:@"查看详情" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            detailAttendanceViewController *vc=[[detailAttendanceViewController alloc]init];
            vc.content=[NSString stringWithFormat:@"%@",content];
            vc.queryid=[NSString stringWithFormat:@"%@",timingpic];
            UIViewController *baseVC=[self topViewControllerWithRootViewController:self.window.rootViewController];
            
            [baseVC.navigationController pushViewController:vc animated:YES];
            
            
        }];
        
        [alertController addAction:noAction];
        [alertController addAction:someAction];
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    [NetworkPath replaceNullData:msgid];
    
    if ([msgid isEqualToString:msgidStr]) {
        return;
    }else{
        msgid=msgidStr;
        //判断是不是在App内
        BOOL _enter;
        if (application.applicationState == UIApplicationStateActive){
            _enter=YES;
        }else{
            _enter=NO;
        }
        
        //把bool 值带过去
        [self showAlterView:title andContent:content isEnter:_enter];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // Required,For systems with less than or equal to iOS6
    [JPUSHService handleRemoteNotification:userInfo];
    LRLog(@"收到通知Remote%@",userInfo);
}


@end

