//
//  XWebBaseViewController.h
//  XWebBase
//
//  Created by 许宇航 on 2017/10/31.
//  Copyright © 2017年 许宇航. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WebBaseViewController;

typedef NS_ENUM(NSInteger,WebBaseViewNavigationType) {
    WebBaseViewNavigationTypeLinkActivated,
    WebBaseViewNavigationTypeFormSubmitted,
    WebBaseViewNavigationTypeBackForward,
    WebBaseViewNavigationTypeReload,
    WebBaseViewNavigationTypeFormResubmitted,
    WebBaseViewNavigationTypeOther
};

@protocol WebBaseViewControllerDelegate <NSObject>

@optional
- (BOOL) webBaseViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(WebBaseViewNavigationType)navigationType;
- (void) webBaseViewDidStartLoad;
- (void) webBaseViewDidFinishLoad;
- (void) webBaseViewDidFailLoadWithError:(NSError *)error;

@end
@interface XWebBaseViewController : UIViewController
//tag = 111 wkwebView

//当拦截到JS中的alter方法，自定义弹出框的标题
@property (nonatomic, copy) NSString * customAlertTitle;
//当拦截到JS中的confirm方法，自定义弹出框的标题
@property (nonatomic, copy) NSString * customConfirmTitle;

@property (nonatomic, weak) id<WebBaseViewControllerDelegate>delegate;

/**
 JS调用OC方法，配置UserContentController消息
 网页中的Script标签中有此JS方法名称，但未具体实现，将参数传给Objective-C,OC将获取到的参数做下一步处理
 必须在OC中具体实现该方法，方法参数可用id(或明确知晓JS传来的参数类型).
 返回一个从保存OC方法名的数组
 */
- (NSArray *) scriptMessageHandler;

/**
 OC调用JS方法
 @param javaScriptString JS方法
 */
- (void) WebBaseViewEvaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id item, NSError * error))completionHandler;

/**
 加载纯外部链接网页 (类对象调方法)
 @param string URL地址
 */
- (void)loadWebURLSring:(NSString *)string;

/**
 加载本地网页  (类对象调方法)
 @param string 本地HTML文件名
 */
- (void)loadWebHTMLSring:(NSString *)string;

/**
 加载纯外部链接网页  (子类重写将要加载的外部链接网页)
 */
- (NSString *) loadWebURLSring;

/**
 加载本地网页  (子类重写将要加载的本地网页)
 */
- (NSString *) loadWebHTMLSring;

/**
 重新加载
 */
- (void) web_Reload;
/**
 停止加载
 */
- (void) web_StopLoading;
/**
 返回上一层
 */
- (void) web_GoBack;
/**
 前进之前的一层
 */
- (void) web_GoForward;
@end
