//
//  ViewController.m
//  XWebBase
//
//  Created by 许宇航 on 2017/10/31.
//  Copyright © 2017年 许宇航. All rights reserved.
//

#import "ViewController.h"
#import "XWebVC.h"
@interface ViewController ()
@property(nonatomic,retain)XWebVC *vc;
@end

@implementation ViewController
-(XWebVC *)vc
{
    if (!_vc) {
        _vc = [[XWebVC alloc]init];
    }
    return _vc;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:@"进入js交互" forState:UIControlStateNormal];
    btn.frame = CGRectMake(0, 0, 200, 50);
    btn.center = self.view.center;
    btn.tag = 1;
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];

    // Do any additional setup after loading the view, typically from a nib.
}
-(void)btnClick:(id)send
{
    [self.navigationController pushViewController:self.vc animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
