//
//  HybirdWebVC.h
//  HybirdApp
//
//  Created by long on 2017/7/28.
//  Copyright © 2017年 LongLJ. All rights reserved.
//

/* 集成HybirdWebView的基础vc: WkWebView（默认）和UIWebView
 * 使用：
    1.可以直接使用
    2.也可以子类扩展
    3.也可以重新集成HybirdWebView（推荐使用）
 */

#import <UIKit/UIKit.h>
#import "HybirdWebView.h"
@class HybirdInteraction;
@protocol HybirdWebVCDelegate;

typedef NS_ENUM(NSInteger, HybirdURLEncodeType) {
    HybirdURLEncodeTypeNone,    // 对URLString不处理
    HybirdURLEncodeTypeAdd,     // 编码：转换成UTF-8
    HybirdURLEncodeTypeRemove,  // 解码
};

@interface HybirdWebVC : UIViewController
/// 进入Web的初始地址
@property (nonatomic, copy) NSString *webURL;
/// 如果interactionSubject拥有子类，可以重新设置
@property (nonatomic, strong) HybirdInteraction *interactionSubject;
/// 对外的webview请求状态接口
@property (nonatomic, weak) id<HybirdWebVCDelegate> delegate;
/// 默认为YES, YES 标示为对URL进行URL编码   NO 标示为对URL不进行URL编码
@property (nonatomic, assign) HybirdURLEncodeType URLEncodeType;
/// 进入webVC页面时是否需要重载初始URL地址  置为YES则重载地址  NO则不重载地址  默认为YES重载初始URL地址
@property (nonatomic, assign) BOOL isRefresh;
/// 进入webVC页面时是否需要重载当前页面URL地址  置为YES则重载地址  NO则不重载地址  默认为NO不重载当面页面URL地址
@property (nonatomic, assign) BOOL isRefreshCurrentURL;
/// 是否采用交互 置为YES则采用交互 置为NO则不采用交互
@property (nonatomic, assign) BOOL isUseInteraction;
/// 默认YES   置为YES则采用WkWebView    NO则采用UIWebView
@property (nonatomic, assign) BOOL usingWebKitCore;
/// 用来同步Cookie的外部接口URL地址
@property (nonatomic, copy) NSString *activeCookieURL;

/// 设置navigationBar的隐藏,默认为No 不隐藏
@property (nonatomic, assign) BOOL navigationBarHidden;
/// 设置navigationBar的返回按钮图片名
@property (nonatomic, copy) NSString *naviBarBackImageName;
/// 设置navigationBar的关闭按钮图片名
@property (nonatomic, copy) NSString *naviBarCloseImageName;

/**
 webView执行JS代码

 @param JSString 交互字符串
 */
- (void)evaluateWebJavaScript:(NSString *)JSString;
/**
 webView加载HTML静态文件

 @param string HTMLString
 @param URL baseURL
 */
- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)URL;
/**
 获取当前加载的URL地址

 @return 当前webURL
 */
- (NSString *)currentWebURL;

#pragma mark
#pragma mark - 导航栏按钮

/**
 自定义导航栏的副标题
 @param itemTitle  导航栏副标题的text,可传入的可以UIImage或NSString对象
 @param auxiliary  副标题的附加值，用来点击副标题的时候传给wap
 @return UIBarButtonItem 对象
 */
- (UIBarButtonItem *)barItemForTitle:(id)itemTitle auxiliary:(id)auxiliary;

/**
 自定义显示返回按钮和关闭按钮
 @param showBack 是否显示返回按钮
 @param showClose 是否显示关闭按钮
 @param closeAuxiliary 显示关闭按钮时点击关闭按钮的时候传给wap的附加值
 */
- (void)reloadBackBarItemShowBack:(BOOL)showBack
                        showClose:(BOOL)showClose
                   closeAuxiliary:(id)closeAuxiliary;

#pragma mark
#pragma mark - App调用Web相关
/// 返回事件    默认：WAP.trigger('goBack')
@property (nonatomic, copy) NSString *WebGoBack;
/// 返回事件    默认：WAP.trigger('loaded')
@property (nonatomic, copy) NSString *WebLoaded;
/// 返回事件    默认：WAP.trigger('closeEvent')
@property (nonatomic, copy) NSString *WebCloseEvent;
/// 返回事件    默认：WAP.trigger('closeEvent','%@')
@property (nonatomic, copy) NSString *WebCloseEventWithArge;
/// 返回事件    默认：WAP.trigger('subTitleEvent')
@property (nonatomic, copy) NSString *WebSubTitleEvent;
/// 返回事件    默认：WAP.trigger('subTitleEvent','%@')
@property (nonatomic, copy) NSString *WebSubTitleEventWithArge;

#pragma mark
#pragma mark - Web调用App主交互函数
/**
 Web调用App主交互函数的数组
 默认包含以下元素：
    getData: web从app获取数据
    putData: web向app推送数据
    doAction: web指定app的动作，比如分享
    goToNative: web跳转到app的原生页面
    goToExtraNative: 额外的多参数自适应交互行为，方便上线后临时的交互
 */
@property (nonatomic, copy) NSArray *mainInteractionArr;

#pragma mark
#pragma mark - 子类自定义方法(建议实现)
/// 基于基本的URL地址进行自定义的匹配改造
- (NSString *)packageBridgeURL:(NSString *)webURLString;
/// 显示副标题时，普通状态下副标题为文字状态的颜色，字体等特性
- (NSDictionary *)subTitleBarItemAttribute;
/// 显示副标题时，高亮状态下副标题为文字状态的颜色，字体等特性
- (NSDictionary *)subTitleBarItemAttributeHighlighted;

@end


@protocol HybirdWebVCDelegate <NSObject>
@optional
- (void)hybirdWebVC:(HybirdWebView *)webView didFinishLoadingURL:(NSURL *)URL;
- (void)hybirdWebVC:(HybirdWebView *)webView didStartLoadingURL:(NSURL *)URL;
- (void)hybirdWebVC:(HybirdWebView *)webView didFailToLoadURL:(NSURL *)URL error:(NSError *)error;
@end
