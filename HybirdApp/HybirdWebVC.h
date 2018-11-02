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
    2.也可以子类扩展（推荐使用）
    3.也可以重新集成HybirdWebView
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, HybirdURLEncodeType) {
    HybirdURLEncodeTypeNone,    // 对URLString不处理
    HybirdURLEncodeTypeAdd,     // 编码：转换成UTF-8
    HybirdURLEncodeTypeRemove,  // 解码
};

@interface HybirdWebVC : UIViewController
/// 进入Web的初始地址
@property (nonatomic, strong) NSString *webURL;
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
@property (nonatomic, strong) NSString *activeCookieURL;
/// 设置navigationBar的隐藏,默认为No 不隐藏
@property (nonatomic, assign) BOOL navigationBarHidden;

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
#pragma mark - 子类自定义方法(必须实现)
//基于基本的URL地址进行自定义的匹配改造
- (NSString *)packageBridgeURL:(NSString *)webURLString;
//显示副标题时，副标题为文字状态的颜色，字体等特性
- (NSDictionary *)subTitleBarItemAttribute;

@end


