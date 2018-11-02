//
//  HybirdWebView.m
//  HybirdApp
//
//  Created by long on 2017/7/28.
//  Copyright © 2017年 LongLJ. All rights reserved.
//

#import "HybirdWebView.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <Masonry/Masonry.h>

#define IOS_HYBIRD_SYSTEM_WEB_VERSION ([[[UIDevice currentDevice] systemVersion] integerValue] >= 8)

static void *HybirdWebBrowserBinContenxt = &HybirdWebBrowserBinContenxt;

@interface HybirdWebView()<WKUIDelegate,
                           WKNavigationDelegate,
                           UIWebViewDelegate,
                           WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *hybirdWKWebView;
@property (nonatomic, strong) UIWebView *hybirdWebView;
@property (nonatomic, strong) NSTimer *fakeProgressTimer;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, assign) BOOL isDrawing;

//以下参数为WKWebView请求头注入Cookie时回退列表使用
@property (nonatomic, assign) BOOL isCustomBack;
@property (nonatomic, assign) BOOL isHybirdBack;
@property (nonatomic, strong) NSMutableArray *backURLList;

@end

@implementation HybirdWebView

- (void)dealloc
{
    if ([WKWebView class]) {
        self.hybirdWKWebView.UIDelegate = nil;
        self.hybirdWKWebView.navigationDelegate = nil;
        [self.hybirdWKWebView removeObserver:self
                                  forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    }else{
        self.hybirdWebView.delegate = nil;
    }
}

- (id)currentWebView
{
    if (self.isUsingUIWebView) {
        return self.hybirdWebView;
    }
    return self.hybirdWKWebView;
}

- (BOOL)isLoading
{
    if (self.isUsingUIWebView) {
        return self.hybirdWebView.isLoading;
    }
    return self.hybirdWKWebView.isLoading;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (self.isDrawing) {
        self.isDrawing = NO;
        [self initScriptMessageHandlerForWKWebView];
    }
}

#pragma mark
#pragma mark - initialize
- (instancetype)init
{
    if (self = [super init]) {
        UIView *contentView;
        if (IOS_HYBIRD_SYSTEM_WEB_VERSION) {
            //IOS8及以后系统采用WebKit
            contentView = [self createWKWebView];
            self.isUsingUIWebView = NO;
        }else{
            //IOS7采用UIWebView
            contentView = [self createUIWebView];
            self.isUsingUIWebView = YES;
        }
        
        [self addSubview:contentView];
        [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self);
            make.left.equalTo(self);
            make.size.equalTo(self);
        }];
        
        [self createProgressView];
    }
    return self;
}


- (instancetype)initWithUseUIWebView:(BOOL)usingUIWebView
{
    if (self = [super init]) {
        self.isUsingUIWebView = usingUIWebView;
        UIView *contentView;
        if (usingUIWebView) {
            contentView = [self createUIWebView];
        }else{
            contentView = [self createWKWebView];
        }
        
        [self addSubview:contentView];
        [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self);
            make.left.equalTo(self);
            make.size.equalTo(self);
        }];
        
        [self createProgressView];
    }
    return self;
}

- (UIView *)createUIWebView
{
    UIWebView *webView = [[UIWebView alloc] init];
    webView.delegate = self;
    webView.backgroundColor = [UIColor clearColor];
    webView.scalesPageToFit = NO;
    self.hybirdWebView = webView;
    
    return webView;
}

- (UIView *)createWKWebView
{
    self.isHybirdBack = NO;
    self.isDrawing = YES;
    WKWebView *webView = [[WKWebView alloc] init];
    webView.UIDelegate = self;
    webView.navigationDelegate = self;
    webView.backgroundColor = [UIColor clearColor];
    self.hybirdWKWebView = webView;
    
    //监控WKWebView的进度条
    [self.hybirdWKWebView addObserver:self
                           forKeyPath:NSStringFromSelector(@selector(estimatedProgress))
                              options:0
                              context:HybirdWebBrowserBinContenxt];
    return webView;
}

- (void)createProgressView
{
    UIProgressView *progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [progressBar setTrackTintColor:[UIColor colorWithWhite:1.0f alpha:0.0f]];
    [progressBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    self.progressView = progressBar;
    [self addSubview:progressBar];
    [progressBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self);
        make.top.equalTo(self);
        make.width.equalTo(self);
        make.height.equalTo(@2);
    }];
}

- (void)initScriptMessageHandlerForWKWebView
{
    if (self.isUsingUIWebView == NO) {
        if (self.hybirdWKWebView.configuration.userContentController != nil) {
            if (self.interactionDelegate != nil && [self.interactionDelegate respondsToSelector:@selector(hybirdWebViewDidRegisterWKScriptMessageName:)]) {
                NSArray *nameList = [self.interactionDelegate hybirdWebViewDidRegisterWKScriptMessageName:self];
                if (nameList != nil && nameList.count != 0) {
                    for (NSString *oneMessageName in nameList) {
                        [self.hybirdWKWebView.configuration.userContentController addScriptMessageHandler:self name:oneMessageName];
                    }
                }
            }
        }
    }
}

#pragma mark
#pragma mark - 同步Cookie
//抓取当前原生页面的cookie值
- (NSArray *)grapCurrentNativeAPPCookie
{
    if (self.activeCookieURL == nil) {
        NSLog(@"需要抓取Cookie值的地址参数activeCookieURL为空");
        return [NSArray array];
    }
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *nativeCookies = [cookieStorage cookiesForURL:self.activeCookieURL];
    return nativeCookies;
}
//同步UIWebView的Cookie
- (void)syncUIWebViewCookie:(NSURLRequest *)urlRequest
{
    NSString *hostURL = urlRequest.URL.host;
    if (hostURL != nil) {
        NSArray *nativeCookies = [self grapCurrentNativeAPPCookie];
        for (NSHTTPCookie *oneCookie in nativeCookies) {
            NSMutableDictionary *cookiePropertie = [[NSMutableDictionary alloc] initWithCapacity:0];
            [cookiePropertie setObject:[oneCookie name] forKey:NSHTTPCookieName];
            [cookiePropertie setObject:[oneCookie value] forKey:NSHTTPCookieValue];
            [cookiePropertie setObject:hostURL forKey:NSHTTPCookieDomain];
            [cookiePropertie setObject:hostURL forKey:NSHTTPCookieOriginURL];
            [cookiePropertie setObject:[oneCookie path] forKey:NSHTTPCookiePath];
            [cookiePropertie setObject:[NSString stringWithFormat:@"%lu",[oneCookie version]] forKey:NSHTTPCookieVersion];
            
            NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookiePropertie];
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
}

//同步WKWebView的Cookie 设置到Header信息中  方便PHP等动态语言调用
- (void)syncWKWebViewCookie:(NSURLRequest *)urlRequest
{
    NSArray *nativeCookies = [self grapCurrentNativeAPPCookie];
    NSMutableString *JSRequest = [[NSMutableString alloc] initWithCapacity:0];
    
    for (NSHTTPCookie *oneCookie in nativeCookies) {
        NSMutableString *oneJSCookie = [[NSMutableString alloc] initWithCapacity:0];
        [oneJSCookie appendFormat:@"%@=%@",
                                  oneCookie.name,oneCookie.value];
        if ([JSRequest length] > 0) {
            [JSRequest appendFormat:@";"];
        }
        [JSRequest appendFormat:@"%@",oneJSCookie];
        
    }
    
    NSMutableURLRequest *mutableRequest = urlRequest.mutableCopy;
    [mutableRequest addValue:JSRequest forHTTPHeaderField:@"Cookie"];
    [self.hybirdWKWebView loadRequest:mutableRequest];
}

//同步WKWebView的Cookie 设置到document.cookie信息中  方便JS等语言调用
- (void)syncWKWebViewJSCookie
{
    NSString *JSFuncString =
    @"function setCookie(name,value,expires)\
    {\
    var oDate=new Date();\
    oDate.setDate(oDate.getDate()+expires);\
    document.cookie=name+'='+value+';expires='+oDate+';path=/'\
    }\
    function getCookie(name)\
    {\
    var arr = document.cookie.match(new RegExp('(^| )'+name+'=([^;]*)(;|$)'));\
    if(arr != null) return unescape(arr[2]); return null;\
    }\
    function delCookie(name)\
    {\
    var exp = new Date();\
    exp.setTime(exp.getTime() - 1);\
    var cval=getCookie(name);\
    if(cval!=null) document.cookie= name + '='+cval+';expires='+exp.toGMTString();\
    }";
    
    NSMutableString *excuteJS = JSFuncString.mutableCopy;
    NSMutableString *JSCookieString = JSFuncString.mutableCopy;
    NSArray *nativeCookies = [self grapCurrentNativeAPPCookie];
    for (NSHTTPCookie *cookie in nativeCookies) {
        NSString *excuteJSString = [NSString stringWithFormat:@"setCookie('%@', '%@', 1);", cookie.name, cookie.value];
        [JSCookieString appendString:excuteJSString];
        
        
        NSString *excuteGetJSString = [NSString stringWithFormat:@"getCookie('%@')",cookie.name];
        [excuteJS appendString:excuteGetJSString];
    }
    
    [self.hybirdWKWebView evaluateJavaScript:JSCookieString completionHandler:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.hybirdWKWebView evaluateJavaScript:excuteJS completionHandler:^(id _Nullable value, NSError * _Nullable error) {
            NSLog(@"value = %@",value);
        }];
    });
    
}



#pragma mark
#pragma mark - 外部接口
- (void)refreshCurrentURLString:(NSString *)URLString
{
    NSMutableString *currentURLString = [[NSMutableString alloc] initWithCapacity:0];
    if ([URLString hasPrefix:@"http://"] || [URLString hasPrefix:@"https://"] ) {
        [currentURLString appendFormat:@"%@", URLString];
    } else {
        [currentURLString appendFormat:@"https://%@", URLString];
    }
    NSURL *URL = [NSURL URLWithString:currentURLString];
    [self refreshCurrentURL:URL];
}

- (void)refreshCurrentURL:(NSURL *)URL
{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:URL];
    [self refreshCurrentURLRequest:urlRequest];
}

- (void)refreshHTMLString:(NSString *)htmlString baseURL:(NSURL *)baseURL
{
    if (self.isUsingUIWebView) {
        [self.hybirdWebView loadHTMLString:htmlString baseURL:baseURL];
    }else{
        [self.hybirdWKWebView loadHTMLString:htmlString baseURL:baseURL];
    }
}

- (BOOL)goWebBack
{
    BOOL canGoBack = NO;
    if (self.isUsingUIWebView) {
        canGoBack = [self.hybirdWebView canGoBack];
        if (canGoBack) {
            [self.hybirdWebView goBack];
        }
    }else{
        if (self.isCustomBack) {
            canGoBack = [self goHybirdWKBack];
        }else{
            if (canGoBack == NO) {
                canGoBack = [self.hybirdWKWebView canGoBack];
                if (canGoBack) {
                    [self.hybirdWKWebView goBack];
                }
            }
        }
    }
    return canGoBack;
}

- (void)reload
{
    if (self.isUsingUIWebView) {
        [self.hybirdWebView reload];
    }else{
        [self.hybirdWKWebView reload];
    }
}

- (void)clear
{
    if(self.fakeProgressTimer) {
        [self.fakeProgressTimer invalidate];
        self.fakeProgressTimer = nil;
    }
    
    if (self.isUsingUIWebView == NO) {
        if (self.hybirdWKWebView.configuration.userContentController != nil) {
            if (self.interactionDelegate != nil && [self.interactionDelegate respondsToSelector:@selector(hybirdWebViewDidRegisterWKScriptMessageName:)]) {
                NSArray *nameList = [self.interactionDelegate hybirdWebViewDidRegisterWKScriptMessageName:self];
                if (nameList != nil) {
                    for (NSString *oneMessageName in nameList) {
                        [self.hybirdWKWebView.configuration.userContentController removeScriptMessageHandlerForName:oneMessageName];
                    }
                }
            }
        }
        
        if ([self.hybirdWKWebView isLoading]) {
            [self.hybirdWKWebView stopLoading];
        }
    
    }else{
        if ([self.hybirdWebView isLoading]) {
            [self.hybirdWebView stopLoading];
        }
    }
}

- (void)evaluateWebJavaScript:(NSString *)JSString
                 evaluateType:(HybirdWebEvaluateType)evaluateType
                   completion:(completionHander) completion
{
    if (JSString != nil) {
        if (self.isUsingUIWebView) {
            //UIWebView两种途径注入js代码
            if (evaluateType == HybirdWebEvaluateTypeTradition) {
                //传统注入方式
                [self.hybirdWebView stringByEvaluatingJavaScriptFromString:JSString];
                if (completion != nil) {
                    completion([NSNull null]);
                }
            }else{
                //JSContext注入方式
                JSContext *hybirdContext = [self.hybirdWebView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
                if (hybirdContext != nil) {
                    JSValue *JSResult = [hybirdContext evaluateScript:JSString];
                    if (JSResult != nil && ![JSResult isUndefined]) {
                        if (completion != nil) {
                            completion([JSResult toObject]);
                        }
                    }else{
                        if (completion != nil) {
                            completion([NSNull null]);
                        }
                    }
                }
            }
            
        }else{
            //WKWebView注入js代码
            [self.hybirdWKWebView evaluateJavaScript:JSString
                                   completionHandler:^(id result, NSError *  error) {
                                       if (result != nil && completion != nil) {
                                           completion(result);
                                       }else{
                                           if (completion != nil) {
                                               completion([NSNull null]);
                                           }
                                       }
                                   }];
        }
    }
}


#pragma mark
#pragma mark - 内部接口
//自定义回退到上一历史URL
- (BOOL)goHybirdWKBack
{
    if (self.backURLList != nil && [self.backURLList count] > 0) {
        self.isHybirdBack = YES;
        WKBackForwardListItem *backItem = [self.backURLList lastObject];
        [self.hybirdWKWebView goToBackForwardListItem:backItem];
        [self.backURLList removeLastObject];
        return YES;
    }
    return NO;
}

//维护自定义回退列表
- (void)addinCustomBackList:(WKWebView *)webView
{
    //自定义回退列表
    if (self.backURLList == nil) {
        NSMutableArray *URLList = [[NSMutableArray alloc] initWithCapacity:0];
        self.backURLList = URLList;
    }
    
    if (self.isHybirdBack == NO) {
        if (webView.backForwardList.currentItem != nil) {
            if ([self.backURLList count] > 0) {
                BOOL isExistURL = NO;
                for (WKBackForwardListItem *oneItem in self.backURLList) {
                    if ([[oneItem.URL absoluteString] isEqualToString:[webView.backForwardList.currentItem.URL absoluteString]]) {
                        isExistURL = YES;
                        break;
                    }
                }
                if (isExistURL == NO) {
                    [self.backURLList addObject:webView.backForwardList.currentItem];
                }
            }else{
                [self.backURLList addObject:webView.backForwardList.currentItem];
            }
        }
    }else{
        self.isHybirdBack = NO;
    }
}

- (void)refreshCurrentURLRequest:(NSURLRequest *)URLRequest
{
    if (self.isUsingUIWebView) {
        //清除缓存
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        //同步Cookie
        [self syncUIWebViewCookie:URLRequest];
        [self.hybirdWebView loadRequest:URLRequest];
    }else{
        [self.hybirdWKWebView loadRequest:URLRequest];
    }
    
}


#pragma mark
#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (webView == self.hybirdWebView) {
        NSString *requestURL = [request.URL absoluteString];
        self.currentURL = request.URL;
        BOOL isContinue = YES;
        if (self.interactionType == HybirdWebInteractionTypeURL) {
            //如果UIWebView采用的是拦截URL请求的交互方式，则在这里面进行处理
            if (self.interactionDelegate != nil && [self.interactionDelegate respondsToSelector:@selector(hybirdWebView:didInvacationURL:)]) {
                isContinue = [self.interactionDelegate hybirdWebView:self
                                                    didInvacationURL:requestURL];
            }
        }
        
        if (isContinue) {
            [self fakeProgressViewStartLoading];
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(hybirdWebView:didStartLoadingURL:)]) {
                [self.delegate hybirdWebView:self
                          didStartLoadingURL:request.URL];
            }
        }
        
        return isContinue;
    }
    
    return NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (webView == self.hybirdWebView) {
        [self fakeProgressBarStopLoading];
        if (self.interactionType == HybirdWebInteractionTypeJavaScript) {
            //如果UIWebView采用的JS调用的交互方式，则在这里进行处理
            if (self.interactionDelegate != nil && [self.interactionDelegate respondsToSelector:@selector(hybirdWebViewDidRegisterJSCallAction:)]) {
                [self.interactionDelegate hybirdWebViewDidRegisterJSCallAction:self];
            }
        }
        
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(hybirdWebView:didFinishLoadingURL:)]) {
            [self.delegate hybirdWebView:self didFinishLoadingURL:webView.request.URL];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (webView == self.hybirdWebView) {
        [self fakeProgressBarStopLoading];
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(hybirdWebView:didFailToLoadURL:error:)]) {
            [self.delegate hybirdWebView:self
                        didFailToLoadURL:webView.request.URL
                                   error:error];
        }
    }
}

#pragma mark
#pragma mark - WKUIDelegate
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

#pragma mark
#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    if (self.hybirdWKWebView == webView) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(hybirdWebView:didStartLoadingURL:)]) {
            [self.delegate hybirdWebView:self didStartLoadingURL:webView.URL];
        }
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (self.hybirdWKWebView == webView) {
        //防止AJAX发送cookie被篡改，重新注入Cookie
        if (self.interactionDelegate != nil && [self.interactionDelegate respondsToSelector:@selector(hybirdWebViewSyncWKWebView:didLoadURL:)]) {
            BOOL WKDcoumentCookieSync = [self.interactionDelegate hybirdWebViewSyncDcoumentCookie:self
                                                                                       didLoadURL:[webView.URL absoluteString]];
            if (WKDcoumentCookieSync) {
                [self syncWKWebViewJSCookie];
            }
        }
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(hybirdWebView:didFinishLoadingURL:)]) {
            [self.delegate hybirdWebView:self didFinishLoadingURL:webView.URL];
        }
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(hybirdWebView:didFailToLoadURL:error:)]) {
        [self.delegate hybirdWebView:self didFailToLoadURL:webView.URL error:error];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(hybirdWebView:didFailToLoadURL:error:)]) {
        [self.delegate hybirdWebView:self didFailToLoadURL:webView.URL error:error];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *actionRequestURL = [navigationAction.request.URL absoluteString];
    NSLog(@"URL==%@",actionRequestURL);

    self.currentURL = navigationAction.request.URL;
    self.isCustomBack = NO;
    if (self.interactionDelegate != nil && [self.interactionDelegate respondsToSelector:@selector(hybirdWebViewSyncWKWebView:didLoadURL:)]) {
        BOOL WKWebViewCookieSync = [self.interactionDelegate hybirdWebViewSyncWKWebView:self
                                                                             didLoadURL:actionRequestURL];
        if (WKWebViewCookieSync) {
            self.isCustomBack = YES;
            //同步请求头的Cookie
            NSDictionary *headerFields = navigationAction.request.allHTTPHeaderFields;
            for (NSString *oneHeaderFieldKey in [headerFields allKeys]) {
                if ([oneHeaderFieldKey isEqualToString:@"Cookie"]) {
                    decisionHandler(WKNavigationActionPolicyAllow);
                    return;
                }
            }
            
            [self addinCustomBackList:webView];
            [self syncWKWebViewCookie:navigationAction.request];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }else{
            //同步document的cookie
            [self syncWKWebViewJSCookie];
            self.isHybirdBack = NO;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(nonnull WKNavigationResponse *)navigationResponse decisionHandler:(nonnull void (^)(WKNavigationResponsePolicy))decisionHandler
{
    if (webView == self.hybirdWKWebView) {
        NSString *requestURL = [navigationResponse.response.URL absoluteString];
        BOOL isContinue = YES;
        //如果WKWebView采用的是拦截URL请求的交互方式，则在这里面进行处理
        if (self.interactionType == HybirdWebInteractionTypeURL) {
            if (self.interactionDelegate != nil && [self.interactionDelegate respondsToSelector:@selector(hybirdWebView:didInvacationURL:)]) {
                isContinue = [self.interactionDelegate hybirdWebView:self
                                                    didInvacationURL:requestURL];
            }
        }
        
        if (isContinue) {
            decisionHandler(WKNavigationResponsePolicyAllow);
            return;
        }
    }
    decisionHandler(WKNavigationResponsePolicyCancel);
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    //警示框代理
    if (message != nil && ![message isEqualToString:@""]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           completionHandler();
                                                       }];
        [alert addAction:action];
        
        UIViewController *mainVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [mainVC presentViewController:alert
                             animated:YES
                           completion:nil];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
    //输入框代理
    if ((prompt != nil && ![prompt isEqualToString:@""]) ||
        (defaultText != nil && ![defaultText isEqualToString:@""])) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:prompt
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            if (defaultText != nil) {
                textField.text = defaultText;
            }
        }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction *action) {
            completionHandler(nil);
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            NSString *input = ((UITextField *)alert.textFields.firstObject).text;
            completionHandler(input);
        }]];
        
        UIViewController *mainVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [mainVC presentViewController:alert
                             animated:YES
                           completion:nil];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
{
    //确认框代理
    if (message != nil && ![message isEqualToString:@""]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           completionHandler(NO);
                                                       }];
        [alert addAction:cancelAction];
        
        UIAlertAction *commitAction = [UIAlertAction actionWithTitle:@"确定"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           completionHandler(YES);
                                                       }];
        [alert addAction:commitAction];
        
        UIViewController *mainVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [mainVC presentViewController:alert
                             animated:YES
                           completion:nil];
    }
}

#pragma mark
#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (message != nil) {
        if (self.interactionDelegate != nil && [self.interactionDelegate respondsToSelector:@selector(hybirdWebView:didReceiveJSMessage:)]) {
            [self.interactionDelegate hybirdWebView:self didReceiveJSMessage:message];
        }
    }
}

#pragma mark
#pragma mark - KVO监控WKWebView的进度属性estimatedProgress
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.hybirdWKWebView) {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.hybirdWKWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.hybirdWKWebView.estimatedProgress animated:animated];
        
        if(self.hybirdWKWebView.estimatedProgress >= 1.0f) {
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


#pragma mark
#pragma mark - 加载时的进度条控制(UIWebView)
- (void)fakeProgressViewStartLoading
{
    [self.progressView setProgress:0.0f animated:NO];
    [self.progressView setAlpha:1.0f];
    
    if(!self.fakeProgressTimer) {
        self.fakeProgressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f
                                                                  target:self
                                                                selector:@selector(fakeProgressTimerDidFire:)
                                                                userInfo:nil
                                                                 repeats:YES];
    }
}

- (void)fakeProgressBarStopLoading
{
    if(self.fakeProgressTimer) {
        [self.fakeProgressTimer invalidate];
        self.fakeProgressTimer = nil;
    }
    
    if(self.progressView) {
        [self.progressView setProgress:1.0f animated:YES];
        [UIView animateWithDuration:0.3f
                              delay:0.3f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            [self.progressView setAlpha:0.0f];
        } completion:^(BOOL finished) {
            [self.progressView setProgress:0.0f animated:NO];
        }];
    }
}

- (void)fakeProgressTimerDidFire:(id)sender
{
    CGFloat increment = 0.005/(self.progressView.progress + 0.2);
    if([self.hybirdWebView isLoading]) {
        CGFloat progress = (self.progressView.progress < 0.75f) ? self.progressView.progress + increment : self.progressView.progress + 0.0005;
        if(self.progressView.progress < 0.95) {
            [self.progressView setProgress:progress animated:YES];
        }
    }
}


@end
