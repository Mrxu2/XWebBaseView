//
//  XWebBaseViewController.m
//  XWebBase
//
//  Created by 许宇航 on 2017/10/31.
//  Copyright © 2017年 许宇航. All rights reserved.
//

#import "XWebBaseViewController.h"
#import "WeakScriptMessageDelegate.h"

#import <objc/runtime.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
#import <WebKit/WebKit.h>
#import <WebKit/WKWebView.h>
#endif

typedef NS_ENUM(NSInteger,WebBaseLoadType) {
    loadWebBaseURLString = 0,
    loadWebBaseHTMLString
};

static void *WebBrowserContext = &WebBrowserContext;

#define KScreen_Width [UIScreen mainScreen].bounds.size.width
#define KScreen_Height [UIScreen mainScreen].bounds.size.height
#define mainBounds     [[UIScreen mainScreen] bounds]
#define mainHeight     [[UIScreen mainScreen] bounds].size.height
#define mainWidth      [[UIScreen mainScreen] bounds].size.width
#define mainStatusBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height
#define mainNavBarHeight   44
#define mainNavHeight (mainNavBarHeight +mainStatusBarHeight)
#define mainTabBarSurplusHeight ([[UIApplication sharedApplication] statusBarFrame].size.height>20?20:0)
#define MyViewHeight(height)                height / 375.0 * KScreen_Width
// NSlog替代宏
#ifdef DEBUG

#define DMLog(...) NSLog(@"%@",[NSString stringWithFormat:__VA_ARGS__])
#define ERRORLog(...) NSLog(@"\n\n Error: \n meth od: %s \n file:   %s \n line:   %d \n %@ \n\n", __PRETTY_FUNCTION__,__FILE__, __LINE__, [NSString stringWithFormat:__VA_ARGS__])
#else
#define DMLog(...) do { } while (0)
//#define ERRORLog(...) do { } while (0)
#define ERRORLog(...) NSLog(@"\n\n Error: \n method: %s \n file:   %s \n line:   %d \n %@ \n\n", __PRETTY_FUNCTION__,__FILE__, __LINE__, [NSString stringWithFormat:__VA_ARGS__])
#endif

@interface XWebBaseViewController ()<WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler,UINavigationControllerDelegate,UINavigationBarDelegate,UIWebViewDelegate>
{
    //记录控制器
    NSPointerArray * _pointers;
    WKUserContentController * userContentController;
}

@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) UIWebView *uiWebView;
//设置加载进度条
@property (nonatomic,strong) UIProgressView *progressView;
//网页加载的类型
@property(nonatomic,assign) WebBaseLoadType loadType;
//链接
@property (nonatomic, copy) NSString *URLString;

//返回按钮
@property (nonatomic)UIBarButtonItem* customBackBarItem;
//关闭按钮
@property (nonatomic)UIBarButtonItem* closeButtonItem;
@end

@implementation XWebBaseViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //在包含UINavigationBar和UITabbar的UIViewController跳转至包含WKWebView的UIViewController时，会因为导航栏／工具栏的高度导致加载WebView的ContentView尺寸出现异常,http://www.jianshu.com/p/e8612669015d
    self.hidesBottomBarWhenPushed = YES;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    
    _pointers = [NSPointerArray weakObjectsPointerArray];
    [_pointers addPointer:(__bridge void * _Nullable)(self)];
    
    if ([UIDevice currentDevice].systemVersion.doubleValue >= 8.0) {
        [self.view addSubview:self.wkWebView];
    }else{
        [self.view addSubview:self.uiWebView];
    }
    
    //加载方式
    if (self.URLString.length > 0) {
        [self webViewloadURLType];
    }else{
        if (self.loadWebURLSring.length > 0) {
            self.URLString = self.loadWebURLSring;
            self.loadType = loadWebBaseURLString;
            [self webViewloadURLType];
        }else if(self.loadWebHTMLSring.length > 0){
            self.URLString = self.loadWebHTMLSring;
            self.loadType = loadWebBaseHTMLString;
            [self webViewloadURLType];
        }else{
            
        }
    }
    
    
    //添加进度条
    [self.view addSubview:self.progressView];
    
}

#pragma mark ================ 加载方式 ================
- (void)webViewloadURLType{
    
    switch (self.loadType) {
        case loadWebBaseURLString:
        {
            //创建一个NSURLRequest 的对象
            //            NSMutableURLRequest * Request_fz = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.URLString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
            //            [Request_fz setHTTPMethod:@"POST"];
            //            AccountManager * manager = [AccountManager sharedInstance];
            //            LoginUserModel * model = manager.selecetUserInfo;
            //            [Request_fz setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            //            [Request_fz setValue:model.random forHTTPHeaderField:@"random"];
            //加载网页
            self.URLString = [self.URLString stringByReplacingOccurrencesOfString:@" " withString:@""];
            if (self.wkWebView) {
                [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.URLString]]];
            }else{
                [self.uiWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.URLString]]];
            }
        }
            break;
        case loadWebBaseHTMLString:
        {
            [self loadHostPathURL:self.URLString];
        }
            break;
        default:
            break;
    }
}

- (void)loadHostPathURL:(NSString *)url{
    //获取JS所在的路径
    NSString *path = [[NSBundle mainBundle] pathForResource:url ofType:nil];
    //获得html内容
    NSString *html = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    //加载js
    if (html) {
        if (self.wkWebView) {
            [self.wkWebView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
        }else{
            [self.uiWebView loadHTMLString:html baseURL:[[NSBundle mainBundle] bundleURL]];
        }
    }else
    {
        NSURL *baseURL = [[NSBundle mainBundle] bundleURL];
        if (self.wkWebView) {
            [self.wkWebView loadHTMLString:[NSString stringWithContentsOfFile:url encoding:NSUTF8StringEncoding error:nil] baseURL:baseURL];
        }else{
            [self.uiWebView loadHTMLString:[NSString stringWithContentsOfFile:url encoding:NSUTF8StringEncoding error:nil] baseURL:baseURL];
        }
    }
   
}

- (NSString *)loadWebURLSring
{
    return @"";
}

- (NSString *)loadWebHTMLSring
{
    return @"";
}

- (void)loadWebURLSring:(NSString *)string{
    self.URLString = string;
    self.loadType = loadWebBaseURLString;
}

- (void)loadWebHTMLSring:(NSString *)string{
    self.URLString = string;
    self.loadType = loadWebBaseHTMLString;
}

-(void)customBackItemClicked{
    if (self.wkWebView.canGoBack && self.wkWebView) {
        [self.wkWebView goBack];
    }else if (self.uiWebView.canGoBack && self.uiWebView){
        [self.uiWebView goBack];
    }else{
        if (self.navigationController.childViewControllers.count == 1) {
            if (self.presentingViewController) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }else{
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}
-(void)closeItemClicked{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark ================ 懒加载 ================
- (WKWebView *)wkWebView{
    if (!_wkWebView) {
        //设置网页的配置文件
        WKWebViewConfiguration * Configuration = [[WKWebViewConfiguration alloc]init];
        //允许视频播放
        //        Configuration.allowsAirPlayForMediaPlayback = YES;
        // 允许在线播放
        Configuration.allowsInlineMediaPlayback = YES;
        // 允许可以与网页交互，选择视图
        Configuration.selectionGranularity = YES;
        // web内容处理池
        Configuration.processPool = [[WKProcessPool alloc] init];
        
        WeakScriptMessageDelegate * weakDelegate = [[WeakScriptMessageDelegate alloc]initWithDelegate:self];
        
        //自定义配置,一般用于 js调用oc方法(OC拦截URL中的数据做自定义操作)
        userContentController = [[WKUserContentController alloc]init];
        // 添加消息处理，注意：self指代的对象需要遵守WKScriptMessageHandler协议
        for (NSString * handelKey in self.scriptMessageHandler) {
            [userContentController addScriptMessageHandler:weakDelegate name:handelKey];
        }
        
        
        // 是否支持记忆读取
        Configuration.suppressesIncrementalRendering = YES;
        // 允许用户更改网页的设置
        Configuration.userContentController = userContentController;
        
        _wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, KScreen_Width, KScreen_Height-mainNavHeight) configuration:Configuration];
        _wkWebView.backgroundColor = [UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0];
        // 设置代理
        _wkWebView.navigationDelegate = self;
        _wkWebView.UIDelegate = self;
        //kvo 添加进度监控
        [_wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:WebBrowserContext];
        //开启手势触摸
        _wkWebView.allowsBackForwardNavigationGestures = YES;
        // 设置 可以前进 和 后退
        //适应你设定的尺寸
        _wkWebView.tag = 111;
        [_wkWebView sizeToFit];
    }
    return _wkWebView;
}

- (UIWebView *) uiWebView
{
    if (!_uiWebView) {
        _uiWebView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, KScreen_Width, self.view.frame.size.height)];
        _uiWebView.scalesPageToFit = YES;
        _uiWebView.delegate = self;
    }
    return _uiWebView;
}

-(UIBarButtonItem*)customBackBarItem{
    if (!_customBackBarItem) {
        
        UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [backButton setImage:[UIImage imageNamed:@"btn_nav_back_n"] forState:UIControlStateNormal];
        [backButton setImage:[UIImage imageNamed:@"btn_nav_back_n"] forState:UIControlStateHighlighted];
        [backButton setFrame: CGRectMake(0,0, 20,44)];
        [backButton setContentEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 10)];
        
        [backButton addTarget:self action:@selector(customBackItemClicked) forControlEvents:UIControlEventTouchUpInside];
        _customBackBarItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        
    }
    return _customBackBarItem;
}

- (UIProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 2);
        // 设置进度条的色彩
        [_progressView setTrackTintColor:[UIColor colorWithRed:240.0/255 green:240.0/255 blue:240.0/255 alpha:1.0]];
        _progressView.progressTintColor = [UIColor greenColor];
    }
    return _progressView;
}

-(UIBarButtonItem*)closeButtonItem{
    if (!_closeButtonItem) {
        _closeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeItemClicked)];
        
    }
    return _closeButtonItem;
}

//KVO监听进度条
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView) {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        
        // Once complete, fade out UIProgressView
        if(self.wkWebView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark ================ 自定义返回/关闭按钮 ================

-(void)updateNavigationItems{
    UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spaceButtonItem.width = -8;
    if (self.wkWebView.canGoBack || self.uiWebView.canGoBack) {
        [self.navigationItem setLeftBarButtonItems:@[self.customBackBarItem,self.closeButtonItem] animated:NO];
    }else{
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:@[self.customBackBarItem]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark ================ WKNavigationDelegate ================

//这个是网页加载完成，导航的变化
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    /*
     主意：这个方法是当网页的内容全部显示（网页内的所有图片必须都正常显示）的时候调用（不是出现的时候就调用），，否则不显示，或则部分显示时这个方法就不调用。
     */
    // 获取加载网页的标题
    self.title = self.wkWebView.title;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateNavigationItems];
    
    if (_delegate && [_delegate respondsToSelector:@selector(webBaseViewDidFinishLoad)]) {
        [_delegate webBaseViewDidFinishLoad];
    }
    
    /*
     主意：禁掉H5自带的选中弹出框
     */
    [_wkWebView evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none';" completionHandler:nil];
    [_wkWebView evaluateJavaScript:@"document.documentElement.style.webkitTouchCallout='none';" completionHandler:nil];
}

//开始加载
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    //开始加载的时候，让加载进度条显示
    self.progressView.hidden = NO;
    if (_delegate && [_delegate respondsToSelector:@selector(webBaseViewDidStartLoad)]) {
        [_delegate webBaseViewDidStartLoad];
    }
}

//内容返回时调用
-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{}

//服务器请求跳转的时候调用
-(void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{}

//服务器开始请求的时候调用
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    switch (navigationAction.navigationType) {
        case WKNavigationTypeLinkActivated: {
            break;
        }
        case WKNavigationTypeFormSubmitted: {
            break;
        }
        case WKNavigationTypeBackForward: {
            break;
        }
        case WKNavigationTypeReload: {
            break;
        }
        case WKNavigationTypeFormResubmitted: {
            break;
        }
        case WKNavigationTypeOther: {
            break;
        }
        default: {
            break;
        }
    }
    if (_delegate && [_delegate respondsToSelector:@selector(webBaseViewShouldStartLoadWithRequest:navigationType:)]) {
        [_delegate webBaseViewShouldStartLoadWithRequest:navigationAction.request navigationType:(WebBaseViewNavigationType)navigationAction.navigationType];
    }
    [self updateNavigationItems];
    decisionHandler(WKNavigationActionPolicyAllow);
}

// 内容加载失败时候调用
-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    DMLog(@"页面加载超时");
}

//跳转失败的时候调用
-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(webBaseViewDidFailLoadWithError:)]) {
        [self.delegate webBaseViewDidFailLoadWithError:error];
    }
}

//进度条
-(void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{}

#pragma mark ================ WKScriptMessageHandler ================
//拦截执行网页中的JS方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    /*** H5界面写法
     *
     *        var u = navigator.userAgent;
     *       var isAndroid = u.indexOf('Android') > -1 || u.indexOf('Adr') > -1; //android终端
     *       var isiOS = !!u.match(/\(i[^;]+;( U;)? CPU.+Mac OS X/); //ios终端
     *       if(isAndroid){
     *         window.control.toastMessage(message);
     *       }else{
     *         window.webKit.messageHandlers.joinActivities.postMessage(val);
     *       }
     ***/
    
    //    服务器固定格式写法 window.webkit.messageHandlers.名字.postMessage(内容);
    //    客户端写法 message.name isEqualToString:@"名字"]
    //    if ([message.name isEqualToString:@""]) {
    //        NSLog(@"%@", message.body);
    //    }
    
    [self excuteJavaScriptFunctionWithName:message.name parameter:message.body];
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:self.customAlertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
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
    [self presentViewController:alert animated:YES completion:NULL];
}

//注意，观察的移除
-(void)dealloc{
    [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    
    //WKWebView用户配置的移除
    if (self.scriptMessageHandler.count > 0) {
        for (NSString * handelKey in self.scriptMessageHandler) {
            [userContentController removeScriptMessageHandlerForName:handelKey];
        }
    }
    
    DMLog(@"销毁了");
}

- (id)performer
{
    return [_pointers pointerAtIndex:0];
}

#pragma mark 执行控制器、子控制器方法
- (void)excuteJavaScriptFunctionWithName:(NSString *)name parameter:(id)param
{
    if (self.performer) {
        SEL selector;
        if ([param isKindOfClass:[NSString class]] && [param isEqualToString:@""]){
            selector = NSSelectorFromString(name);
        }else{
            selector = NSSelectorFromString([name stringByAppendingString:@":"]);
        }
        
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
 JS调用OC方法，配置UserContentController消息
 网页中的Script标签中有此JS方法名称，但未具体实现，将参数传给Objective-C,OC将获取到的参数做下一步处理
 必须在OC中具体实现该方法，方法参数可用id(或明确知晓JS传来的参数类型).
 返回一个从保存OC方法名册数组
 */
- (NSArray *) scriptMessageHandler
{
    return nil;
}

/**
 OC调用JS方法
 @param javaScriptString JS方法
 */
- (void) WebBaseViewEvaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id item, NSError *))completionHandler
{
    [_wkWebView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}

//重新加载
- (void) web_Reload
{
    [_wkWebView reload];
}
//停止加载
- (void) web_StopLoading
{
    [_wkWebView stopLoading];
}
//返回上一层
- (void) web_GoBack
{
    if ([_wkWebView canGoBack]) {
        [_wkWebView  goBack];
    }
}
//前进之前的一层
- (void) web_GoForward
{
    if ([_wkWebView canGoForward]) {
        [_wkWebView goForward];
    }
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
