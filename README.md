# XWebBaseView




-   `pod 'XWebBaseView', '~> 0.0.2`

-  可以下载并查看例子的使用

## Requirements
- iOS 8+ 
- Xcode 7+

## 例子

### 封装的`webView`和`webViewController`。

### 一个js交互的例子。（包含`html`文件 更直观的理解`js`交互）


================== js交互（js与oc）==================


*注入js方法 （把js的方法名称放进数组中进行注入）

*在提供的`html`文件中会有这么一个交互方法 window.webkit.messageHandlers.`showName`.postMessage('xiao黄')

*我们只需要知道其中的showName名称并进行注入就行。

    - (NSArray*)scriptMessageHandler
    {
        return @[@"showName"];
    }
 



*注入成功后必须实现注入字符串时的方法

*在`-(NSArray *)scriptMessageHandler` 方法中

*我们注入了（return @[@"`showName`"]）  `showName`方法名称

*那么“必须”要实现余其名称对应的 -(void)showName:(id)data；方法。


    - (void*)showName:(id)data
    {
    //在其中实现项目逻辑
    }
 

================== `js`交互（`oc与js`） ==================


1.OC调用JS方法

    - (void)WebBaseViewEvaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id item, NSError *))completionHandler
    {
        
    }

2.使用 点击按钮时注入js方法。
*无传值 - 在提供的`html`中有function alertMobile()这么一个方法。
*我们只需要把alertMobile()一样的字符串注入其中就行。

*有传值 - 在`html`中有function alertName(msg)这么一个方法。
*我们只需要把alertName(msg)一样的字符串注入其中就行。（msg）为传值字符串。

    [self WebBaseViewEvaluateJavaScript:arrJS[view.tag - 1] completionHandler:nil];
    
    
    
## WebBaseView    
====================================== webBase ======================================
WebBaseView：  

1、实现构造器方法及对应的代理方法

2、加载进度
    有提供一个可使用的对象progressView，需要用的时候就设置frame以及加入当前当前控制器里或者实现对应的IOS监听进度代理（该方式只适用IOS8以上），IOS8以下自行做假加载进度

3、提供2个方法加载本地或者网络数据
    加载网络路径：- (void)loadWebURLSring:(NSString *)string;
    加载本地路径：- (void)loadWebHTMLSring:(NSString *)string;

4、当要实现JS调OC方法的时候该方法必须重写掉
    - (NSArray<NSString *>*) webViewRegisterObjCMethodNameForJavaScriptInteraction;
    这边方法里返回的是OC这边给JS调用的方法名

    - (NSArray<NSString *>*)webViewRegisterObjCMethodNameForJavaScriptInteraction
    {
        return @[@"ChangeImg"];
    }

    这边有个注意的，不管OC这边的方法是不是带参数的，该回调里面的方法返回都只需要写上方法名就行，JS那边如果要带参数的话，参数就会返
    回一个字符串，之后OC这边再自行对该字符串进行处理

5、提供了OC执行JS方法
    - (void)excuteJavaScript:(NSString *)javaScriptString completionHandler:(void(^)(id params, NSError * error))completionHandler;
    
    


WebBaseViewController：
    该类只适用IOS8以上的，没对IOS8以下的进行适配，也不想适配

1、继承该类

2、重写JS调OC的方法声明
    - (NSArray *) scriptMessageHandler;
    这边方法里返回的是OC这边给JS调用的方法名
    
    - (NSArray *) scriptMessageHandler
    {
        return @[@"joinActivities",@"ChangeImg"];
    }

    这边有个注意的，不管OC这边的方法是不是带参数的，该回调里面的方法返回都只需要写上方法名就行，JS那边如果要带参数的话，参数就会
    回一个字符串，之后OC这边再自行对该字符串进行处理

3、加载进度
    代码内已实现，不需要再初始化

4、提供4个方法加载本地或者网络数据
    类对象调方法：
        加载网络路径：- (void)loadWebURLSring:(NSString *)string;
        加载本地路径：- (void)loadWebHTMLSring:(NSString *)string;

    子类重写将要加载的外部链接网页：
        加载网络路径：- (NSString *) loadWebURLSring;
        加载本地路径：- (NSString *) loadWebHTMLSring;

5、提供了OC执行JS方法
    - (void) WebBaseViewEvaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id item, NSError * error))completionHandler;


