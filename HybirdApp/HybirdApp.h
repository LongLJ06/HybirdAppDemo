//
//  HybirdApp.h
//  HybirdApp
//
//  Created by long on 2017/7/28.
//  Copyright © 2016年 LongLJ. All rights reserved.
//

/*  HybirdApp 架构的使用方法
 *  目前HybirdApp中混合集成了4种前端和iOS端交互的方法,分别适时采用UIWebView和WKWebView,依次是UIWebView+URL拦截方式(A方式),
 *  WKWebView+URL拦截方式(B方式),UIWebView+JavaScriptCore(C方式),WKWebView+MessageHandle(D方式)。本架构中采用HybirdWebView
 *  是主体，用来处理webview的工作；HybirdInteraction是交互实体，用来处理响应JS的实体交互方法；HybirdWebVC是个壳，用来处理一些细节，
 *  HybirdWebView和HybirdInteraction之间的联合的关系，大体的方式选择和逻辑修改都在HybirdWebVC类实现,相应的业务修改可以在HybirdWebVC里实现,
 *  如果对webView进行业务处理,可以重写或者继承HybirdWebVC类
 *  交互的实体动作在HybirdInteraction类或者子类中实现.
 *  1.采用A和B方法
 *  此时交互回调方法必须实现- (BOOL)hybirdWebView:(HybirdWebView *)webView didInvacationURL:(NSString *)invacatinActionURL
 *  2.采用C方法
 *  此时交互回调方法必须实现- (void)hybirdWebViewDidRegisterJSCallAction:(HybirdWebView *)webView
 *  3.采用D方法
 *  此时交互回调方法必须实现- (void)hybirdWebView:(HybirdWebView *)webView didReceiveJSMessage:(WKScriptMessage *)message
 *                     - (NSArray *)hybirdWebViewDidRegisterWKScriptMessageName:(HybirdWebView *)webView
*/


#ifndef HybirdApp_h
#define HybirdApp_h

#import "HybirdWebVC.h"
#import "HybirdWebView.h"
#import "HybirdInteraction.h"

#endif /* HybirdApp_h */
