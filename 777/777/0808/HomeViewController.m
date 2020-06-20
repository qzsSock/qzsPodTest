//
//  HomeViewController.m
//  777
//
//  Created by 邱子硕 on 2020/6/20.
//  Copyright © 2020 邱子硕. All rights reserved.
//

#import "HomeViewController.h"

@interface HomeViewController ()
@property (nonatomic,strong) UITableView*table;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
}
/*

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
