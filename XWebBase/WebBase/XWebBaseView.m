//
//  XWebBaseView.m
//  XWebBase
//
//  Created by 许宇航 on 2017/10/31.
//  Copyright © 2017年 许宇航. All rights reserved.
//

#import "XWebBaseView.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
#import <WebKit/WebKit.h>
#endif

#define ISIOS8 [UIDevice currentDevice].systemVersion.doubleValue >= 8.0 ? YES : NO

static void *WebBrowserContext = &WebBrowserContext;

@interface XWebBaseView()

{
    NSPointerArray * _pointers;
    UIView * _webView;
}

@end

@implementation XWebBaseView

static long const WebJSContextKey  = 1000;
static long const WebJSValueKey    = 1100;

- (instancetype)initWithFrame:(CGRect)frame
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    return [self initWithFrame:frame delegate:nil JSPerformer:nil];
#pragma clang diagnostic pop
}

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<WebViewDelegate>)delegate JSPerformer:(id)performer
{
    if (self = [super initWithFrame:frame]) {
        _delegate = delegate;
        _pointers = [NSPointerArray weakObjectsPointerArray];
        [_pointers addPointer:(__bridge void * _Nullable)(performer)];
        CGRect rect = frame;
        rect.origin.y = 0;
        if (ISIOS8) {
            [self configureWKWebViewWithFrame:rect];
        }else{
            [self configureUIWebViewWithFrame:rect];
        }
    }
    return self;
}

- (void)loadWebHTMLSring:(NSString *)string{
    //获取JS所在的路径
    NSString *path = [[NSBundle mainBundle] pathForResource:string ofType:nil];
    //获得html内容
    NSString *html = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    //加载js
    if (ISIOS8) {
        [(WKWebView *)_webView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
    }else{
        [(UIWebView *)_webView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
    }
}

- (void)loadWebURLSring:(NSString *)string
{
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    //加载网页
    NSURLRequest * reqUrl = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:string]];
    if (ISIOS8) {
        [(WKWebView *)_webView loadRequest:reqUrl];
    }else{
        [(UIWebView *)_webView loadRequest:reqUrl];
    }
}

#pragma mark - __IPHONE_7_0 --> UIWebView构建
- (JSContext *)jsContext
{
    return objc_getAssociatedObject(self, &WebJSContextKey);
}

- (JSValue *)jsValue
{
    return objc_getAssociatedObject(self, &WebJSValueKey);
}

- (void)configureUIWebViewWithFrame:(CGRect)frame
{
    UIWebView * web = [[UIWebView alloc] initWithFrame:frame];
    [web sizeToFit];
    Protocol * WebUIWebViewDelegate = objc_allocateProtocol("UIWebViewDelegate");
    [self registerProtocol:WebUIWebViewDelegate];
    web.delegate = (id<UIWebViewDelegate>)self;
    _webView = web;
    [self addSubview:_webView];
}

#pragma mark - __IPHONE_7_0 --> UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        return [self.delegate webView:(WebBaseView *)_webView shouldStartLoadWithRequest:request navigationType:(WebViewNavigationType)navigationType];
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.delegate webViewDidStartLoad:(WebBaseView *)_webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    JSContext * JSCtx = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    JSValue * JSVlu = [JSCtx globalObject];
    objc_setAssociatedObject(self, &WebJSValueKey, JSVlu, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(self, &WebJSContextKey, JSCtx, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    _title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    //获取当前H5高
    CGFloat webHeight = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"] floatValue];
    if (_delegate && [_delegate respondsToSelector:@selector(webViewDidFinishLoad:contentViewHeight:)]) {
        [_delegate webViewDidFinishLoad:(WebBaseView *)_webView contentViewHeight:webHeight];
    }
    
    if([self.delegate respondsToSelector:@selector(webViewRegisterObjCMethodNameForJavaScriptInteraction)]){
        [[self.delegate webViewRegisterObjCMethodNameForJavaScriptInteraction] enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
            __weak typeof(self) weakSelf = self;
            self.jsContext[name] = ^(id body){
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [strongSelf excuteJavaScriptFunctionWithName:name parameter:body];
            };
        }];
    }
    
    if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.delegate webViewDidFinishLoad:(WebBaseView *)_webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.delegate webView:(WebBaseView *)_webView didFailLoadWithError:error];
    }
}

#pragma mark - __IPHONE_8_0 --> WKWebView构建
- (void)configureWKWebViewWithFrame:(CGRect)frame
{
    //设置网页的配置文件
    WKWebViewConfiguration * Configuration = [[WKWebViewConfiguration alloc]init];
    Configuration.allowsInlineMediaPlayback = YES;
    Configuration.selectionGranularity = YES;
    Configuration.processPool = [[WKProcessPool alloc] init];
    Configuration.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    Configuration.suppressesIncrementalRendering = YES;
    Configuration.userContentController = [[WKUserContentController alloc]init];
    
    WKWebView * web = [[WKWebView alloc] initWithFrame:frame configuration:Configuration];
    //开启手势触摸
    web.allowsBackForwardNavigationGestures = YES;
    //kvo 添加进度监控
    [web addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:WebBrowserContext];
    
    Protocol * WebWKUIDelegate = objc_allocateProtocol("WKUIDelegate");
    [self registerProtocol:WebWKUIDelegate];
    Protocol * WebWKNavigationDelegate = objc_allocateProtocol("WKNavigationDelegate");
    [self registerProtocol:WebWKNavigationDelegate];
    Protocol * WebWKScriptMessageHandler = objc_allocateProtocol("WKScriptMessageHandler");
    [self registerProtocol:WebWKScriptMessageHandler];
    
    web.UIDelegate = (id<WKUIDelegate>)self;
    web.navigationDelegate = (id<WKNavigationDelegate>)self;
    web.allowsBackForwardNavigationGestures = YES;
    [web sizeToFit];
    _webView = web;
    [self addSubview:_webView];
}

#pragma mark IOS8以上WKWebView加载进度 estimatedProgress
//KVO监听进度条
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == (WKWebView *)_webView) {
        
        WKWebView * wkWebV = (WKWebView *)_webView;
        
        [self.progressView setAlpha:1.0f];
        BOOL animated = wkWebV.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:wkWebV.estimatedProgress animated:animated];
        
        if (_delegate && [_delegate respondsToSelector:@selector(webView:loadingEstimatedProgress:)]) {
            [_delegate webView:(WebBaseView *)_webView loadingEstimatedProgress:wkWebV.estimatedProgress];
        }
        
        // Once complete, fade out UIProgressView
        if(wkWebV.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (UIProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        // 设置进度条的色彩
        [_progressView setTrackTintColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0]];
        _progressView.progressTintColor = [UIColor greenColor];
    }
    return _progressView;
}

#pragma mark - __IPHONE_8_0 --> WKNavigationDelegate
//这个是网页加载完成，导航的变化
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    _title = webView.title;
    
    //获取当前H5高
    [webView evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(id _Nullable param, NSError * _Nullable error) {
        if (_delegate && [_delegate respondsToSelector:@selector(webViewDidFinishLoad:contentViewHeight:)]) {
            [_delegate webViewDidFinishLoad:(WebBaseView *)_webView contentViewHeight:[param doubleValue]];
        }
    }];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewRegisterObjCMethodNameForJavaScriptInteraction)]) {
        [[self.delegate webViewRegisterObjCMethodNameForJavaScriptInteraction] enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
            [webView.configuration.userContentController removeScriptMessageHandlerForName:name];
            [webView.configuration.userContentController addScriptMessageHandler:(id<WKScriptMessageHandler>)self name:name];
        }];
    }
    if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]){
        [self.delegate webViewDidFinishLoad:(WebBaseView *)_webView];
    }
}

//开始加载
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    if (_delegate && [_delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_delegate webViewDidStartLoad:(WebBaseView *)_webView];
    }
}

//内容返回时调用
-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{}

//服务器请求跳转的时候调用
-(void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{}

//服务器开始请求的时候调用
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    if (_delegate && [self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        [self.delegate webView:(WebBaseView *)_webView shouldStartLoadWithRequest:navigationAction.request navigationType:(WebViewNavigationType)navigationAction.navigationType];
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

// 内容加载失败时候调用
-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"页面加载超时");
}

//跳转失败的时候调用
-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.delegate webView:(WebBaseView *)_webView didFailLoadWithError:error];
    }
}

//进度条
-(void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{}

#pragma mark - __IPHONE_8_0 --> WKScriptMessageHandler
//拦截执行网页中的JS方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    [self excuteJavaScriptFunctionWithName:message.name parameter:message.body];
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.customAlertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [[self currentViewController] presentViewController:alert animated:YES completion:NULL];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.customConfirmTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [[self currentViewController] presentViewController:alert animated:YES completion:NULL];
}


#pragma mark 相关配置
- (void)registerProtocol:(Protocol *)protocol
{
    if (protocol) {
        objc_registerProtocol(protocol);
        class_addProtocol([XWebBaseView class], protocol)?:NSLog(@"动态绑定协议失败");
    }
}

- (id)performer
{
    return [_pointers pointerAtIndex:0];
}

- (BOOL)isLoading
{
    return (BOOL)[self excuteFuncWithName:@"isLoading"];
}

- (void)reload
{
    [self excuteFuncWithName:@"reload"];
}

- (void)stopLoading
{
    [self excuteFuncWithName:@"stopLoading"];
}

- (void)goBack
{
    [self excuteFuncWithName:@"goBack"];
}

- (void)goForward
{
    [self excuteFuncWithName:@"goForward"];
}

+ (void)removeAllGSWebViewCache
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

/**
 *  动态执行对应的UIWebView或WKWebView的内部方法
 */
- (id)excuteFuncWithName:(NSString *)name
{
    SEL selector = NSSelectorFromString(name);
    if ([_webView respondsToSelector:selector]) {
        IMP imp = [_webView methodForSelector:selector];
        id (*func)(id, SEL) = (void *)imp;
        return (id)func(_webView, selector);
    }
    return nil;
}

/**
 *  JS调用OC
 */
- (void)excuteJavaScriptFunctionWithName:(NSString *)name parameter:(id)param
{
    if (self.performer) {
        SEL selector;
        if ([param isKindOfClass:[NSString class]] && [param isEqualToString:@""])
            selector = NSSelectorFromString(name);
        else
            selector = NSSelectorFromString([name stringByAppendingString:@":"]);
        
        if ([self.performer respondsToSelector:selector]){
            IMP imp = [self.performer methodForSelector:selector];
            if (param){
                void (*func)(id, SEL, id) = (void *)imp;
                func(self.performer, selector,param);
            }
            else{
                void (*func)(id, SEL) = (void *)imp;
                func(self.performer, selector);
            }
        }
    }
}

/**
 *  OC调JS  执行JS并且有回调
 */
- (void)excuteJavaScript:(NSString *)javaScriptString completionHandler:(void(^)(id params, NSError * error))completionHandler
{
    if ([_webView isKindOfClass:[WKWebView class]]) {
        [(WKWebView *)_webView evaluateJavaScript:javaScriptString completionHandler:^(id param, NSError * error){
            if (completionHandler) {
                completionHandler(param,error);
            }
        }];
    }else{
        JSValue * value = [self.jsContext evaluateScript:javaScriptString];
        if (value && completionHandler) {
            completionHandler([value toObject],NULL);
        }
    }
}

/**
 *  获取当前视图的父控制器
 */
- (UIViewController *)currentViewController{
    UIViewController *vc = nil;
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * win in windows) {
            if (win.windowLevel == UIWindowLevelNormal) {
                window = win;
                break;
            }
        }
    }
    UIView *frontView = [[window subviews] firstObject];
    id nextResponder = [frontView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]])
        vc = nextResponder;
    else
        vc = window.rootViewController;
    return vc;
}

/**
 *  注意，观察的移除
 */
- (void) dealloc
{
    if (ISIOS8) {
        [(XWebBaseView *)_webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
