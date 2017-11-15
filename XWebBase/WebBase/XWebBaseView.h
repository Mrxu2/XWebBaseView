//
//  XWebBaseView.h
//  XWebBase
//
//  Created by 许宇航 on 2017/10/31.
//  Copyright © 2017年 许宇航. All rights reserved.
//


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WebBaseView;

typedef NS_ENUM(NSInteger,WebViewNavigationType) {
    WebViewNavigationTypeLinkClicked,
    WebViewNavigationTypeFormSubmitted,
    WebViewNavigationTypeBackForward,
    WebViewNavigationTypeReload,
    WebViewNavigationTypeFormResubmitted,
    WebViewNavigationTypeOther
};

@protocol WebViewDelegate <NSObject>

@optional
- (BOOL) webView:(WebBaseView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(WebViewNavigationType)navigationType;
- (void) webViewDidStartLoad:(WebBaseView *)webView;
- (void) webViewDidFinishLoad:(WebBaseView *)webView;
- (void) webView:(WebBaseView *)webView didFailLoadWithError:(NSError *)error;
- (void) webViewDidFinishLoad:(WebBaseView *)webView contentViewHeight:(CGFloat)height;
- (NSArray<NSString *>*) webViewRegisterObjCMethodNameForJavaScriptInteraction;

/**
 *  8.0才支持获取进度
 *
 *  8.0之下版本可以根据回调模拟虚假进度
 */
- (void) webView:(WebBaseView *)webView loadingEstimatedProgress:(double)estimatedProgress NS_AVAILABLE_IOS(8_0);

@end

@interface XWebBaseView : UIView

@property (nonatomic, weak) id<WebViewDelegate> delegate;

@property (nullable, nonatomic, readonly, copy) NSString * title;

/**
 提供一个创建好的进度条，需要用的时候就设置frame以及加入父视图就行 或者  实现进度监听代理
 */
@property (nonatomic,strong) UIProgressView *progressView;

@property (nullable, nonatomic, copy) NSString * customAlertTitle;    //当拦截到JS中的alter方法，自定义弹出框的标题
@property (nullable, nonatomic, copy) NSString * customConfirmTitle;  //当拦截到JS中的confirm方法，自定义弹出框的标题

/**
 指定构造方法
 */
- (instancetype)initWithFrame:(CGRect)frame delegate:(nonnull id<WebViewDelegate>)delegate JSPerformer:(nonnull id)performer;

/**
 加载纯外部链接网页
 @param string URL地址
 */
- (void)loadWebURLSring:(NSString *)string;

/**
 加载本地网页
 @param string 本地HTML文件名
 */
- (void)loadWebHTMLSring:(NSString *)string;

/**
 执行JavaScript方法
 OC调用网页中的JS方法,可以取得该JS方法的返回值
 
 */
- (void)excuteJavaScript:(NSString *)javaScriptString completionHandler:(void(^)(id params, NSError * error))completionHandler;

- (id)performer;

- (void)reload;
- (void)stopLoading;
- (void)goBack;
- (void)goForward;

@end
NS_ASSUME_NONNULL_END

