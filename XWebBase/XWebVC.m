//
//  XWebVC.m
//  XWebBase
//
//  Created by 许宇航 on 2017/10/31.
//  Copyright © 2017年 许宇航. All rights reserved.
//

#import "XWebVC.h"

@interface XWebVC ()

@end

@implementation XWebVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *arr = @[@"小黄的手机号（原生按钮）",@"打电话给小红（原生按钮）",@"给小红发短信（原生按钮）"];
    CGFloat height = CGRectGetHeight(self.view.frame) - self.view.safeAreaInsets.bottom;
    NSInteger y =height - (34 *5);
    for (int i = 0; i<3; i++) {
        NSString *title = arr[i];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:title forState:UIControlStateNormal];
        btn.frame = CGRectMake(0, 0, 200, 30);
        btn.center = CGPointMake(self.view.center.x, y+(i *24));
        btn.tag = i+1;
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
    // Do any additional setup after loading the view.
}
/**
 *
 @return 加载本地html
 */
-(NSString *)loadWebHTMLSring
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    return filePath;
}
#pragma mark - oc调用js
/**
 点击按钮时注入js方法。
 *无传值 - 在html中有function alertMobile()这么一个方法。
        - 我们只需要把alertMobile()一样的字符串注入其中就行。
 
 *有传值 - 在html中有function alertName(msg)这么一个方法。
        - 我们只需要把alertName(msg)一样的字符串注入其中就行。（msg）为传值字符串。

 @param send <#send description#>
 */
-(void)btnClick:(id)send
{
    NSArray *arrJS = @[@"alertMobile()",@"alertName('小红')",@"alertSendMsg('18870707070','周末爬山真是件愉快的事情')"];
    UIView *view = send;
    [self WebBaseViewEvaluateJavaScript:arrJS[view.tag - 1] completionHandler:^(id item, NSError *error) {
        
    }];

}
#pragma mark - js调用oc
/**
 
 *注入js方法 （把js的方法名称放进数组中进行注入）
 
 *在html中会有这么一个交互方法 window.webkit.messageHandlers.showName.postMessage('xiao黄')
 
 *我们只需要知道其中的showName名称并进行注入就行。
 
 @return js注入方法
 */
-(NSArray *)scriptMessageHandler
{
    return @[@"showName",@"showSendMsg",@"showMobile"];
}
/**
 *注入成功后必须实现注入字符串时的方法
 
 *！必须！！必须！！必须！！必须！！必须！！必须！！必须！必须！
 
 *在-(NSArray *)scriptMessageHandler 方法中
 *我们注入了（return @[@"showName"]）  showName方法名称
 *那么“必须”要实现余其名称对应的 -(void)showName:(id)data；方法。
 
 *！必须！！必须！！必须！！必须！！必须！！必须！！必须！！必须！

 @param data js实现
 */
-(void)showName:(id)data
{
    NSString *info = [NSString stringWithFormat:@"你好 %@, 很高兴见到你",data];
    [self showMsg:info];
}
-(void)showSendMsg:(id)data
{
    NSArray *array = data;
    NSString *info = [NSString stringWithFormat:@"这是我的手机号: %@, %@ !!",array.firstObject,array.lastObject];
    [self showMsg:info];
    
}
-(void)showMobile:(id)data
{
    [self showMsg:@"我是下面的小红 手机号是:18870707070"];
}
- (void)showMsg:(NSString *)msg {
    [[[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
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
