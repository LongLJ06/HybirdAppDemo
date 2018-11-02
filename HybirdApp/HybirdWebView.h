//
//  HybirdWebView.h
//  HybirdApp
//
//  Created by long on 2017/7/28.
//  Copyright © 2017年 LongLJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@protocol HybirdWebViewDelegate;
@protocol HybirdWebViewInteractionDelegate;

/**
 交互方式

 - HybirdWebInteractionTypeURL: 拦截URL交互模式
 - HybirdWebInteractionTypeJavaScript: JS交互模式
 - HybirdWebInteractionTypeNone: 不进行交互
 */
typedef NS_ENUM(NSInteger, HybirdWebInteractionType) {
    HybirdWebInteractionTypeURL,
    HybirdWebInteractionTypeJavaScript,
    HybirdWebInteractionTypeNone,
};

/**
 Native调用JS的方式

 - HybirdWebEvaluateTypeJSContext: 使用JSContext方式注入，UIWebView可用
 - HybirdWebEvaluateTypeTradition: 使用webView默认的js方式注入代码
 */
typedef NS_ENUM(NSInteger, HybirdWebEvaluateType) {
    HybirdWebEvaluateTypeJSContext,
    HybirdWebEvaluateTypeTradition,
};

typedef void (^completionHander)(id JSResult);

@interface HybirdWebView : UIView

/// 交互方式
@property (nonatomic, assign) HybirdWebInteractionType interactionType;
/// 交互代理
@property (nonatomic, assign) id<HybirdWebViewInteractionDelegate> interactionDelegate;
/// webView运行代理
@property (nonatomic, assign) id<HybirdWebViewDelegate> delegate;

/// 当前加载好的URL
@property (nonatomic, strong) NSURL *currentURL;
/// 当前使用的webView实例
@property (nonatomic, strong) id currentWebView;
/// 是否使用UIWebView
@property (nonatomic, assign) BOOL isUsingUIWebView;
/// 是否正在loading
@property (nonatomic, assign, readonly) BOOL isLoading;
/// 用来同步Cookie的外部接口URL地址
@property (nonatomic, strong) NSURL *activeCookieURL;

#pragma mark
#pragma mark - 初始化
- (instancetype)init;
- (instancetype)initWithUseUIWebView:(BOOL)usingUIWebView;

#pragma mark
#pragma mark - 加载URL
- (void)refreshCurrentURLString:(NSString *)URLString;
- (void)refreshCurrentURL:(NSURL *)URL;
- (void)refreshHTMLString:(NSString *)htmlString baseURL:(NSURL *)baseURL;

#pragma mark
#pragma mark - 常用方法
/// webView 回退,可以回退的情况下进行回退操作，并返回是否可以回退的标识
- (BOOL)goWebBack;
/// 重载当前页面
- (void)reload;
/// webView停止加载
- (void)clear;

#pragma mark
#pragma mark - JS和OC交互实现方法，OC调用JS代码
- (void)evaluateWebJavaScript:(NSString *)JSString
                 evaluateType:(HybirdWebEvaluateType)evaluateType
                   completion:(completionHander) completion;

@end


@protocol HybirdWebViewDelegate <NSObject>
@optional
- (void)hybirdWebView:(HybirdWebView *)webView didFinishLoadingURL:(NSURL *)URL;
- (void)hybirdWebView:(HybirdWebView *)webView didFailToLoadURL:(NSURL *)URL error:(NSError *)error;
- (void)hybirdWebView:(HybirdWebView *)webView didStartLoadingURL:(NSURL *)URL;
@end



@protocol HybirdWebViewInteractionDelegate <NSObject>
@optional
/**
 *  拦截URL的交互方式的回调方法(采用拦截自定义URL这样的"曲线救国"模式)
 *
 *  @param webView              当前回到的HybirdWebView 对象
 *  @param invacatinActionURL   拦截到的当前URL
 */
- (BOOL)hybirdWebView:(HybirdWebView *)webView
     didInvacationURL:(NSString *)invacatinActionURL;

/**
 *  JS调用OC代码的交互方式的回调方法(采用JavaScriptCore+UIWebView方式)
 *
 *  @param webView 当前回到的HybirdWebView 对象
 */
- (void)hybirdWebViewDidRegisterJSCallAction:(HybirdWebView *)webView;

/**
 *  MessageHandle调用OC代码的交互方式的回调方法(采用WKWebView+MessageHandle方式)
 *
 *  @param webView 当前回到的HybirdWebView 对象
 *  @param message 当前获取到的JS动作脚本
 */
- (void)hybirdWebView:(HybirdWebView *)webView didReceiveJSMessage:(WKScriptMessage *)message;

/**
 *  MessageHandle注入OC脚本的回调方式，采用MessageHandle调用OC代码的交互方式时必须实现该方法
 *
 *  @param webView 当前回到的HybirdWebView 对象
 *  @return 动作名称的字符串数组
 */
- (NSArray *)hybirdWebViewDidRegisterWKScriptMessageName:(HybirdWebView *)webView;

/**
 *  判别WKWebView 是否需要同步请求头里的Cookie，会重新加载一次URL
 *
 *  @param webView 当前回到的HybirdWebView 对象
 *  @param requestURL  请求的URL
 *  @return 是否需要同步Cookie的标识
 */
- (BOOL)hybirdWebViewSyncWKWebView:(HybirdWebView *)webView didLoadURL:(NSString *)requestURL;

/**
 *  判别WKWebView 是否需要同步document.cookie，不会重新加载一次URL
 *
 *  @param webView 当前回到的HybirdWebView 对象
 *  @param requestURL  请求的URL
 *  @return 是否需要同步Cookie的标识
 */
- (BOOL)hybirdWebViewSyncDcoumentCookie:(HybirdWebView *)webView didLoadURL:(NSString *)requestURL;

@end

