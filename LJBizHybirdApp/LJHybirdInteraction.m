//
//  LJHybirdInteraction.m
//  HybirdApp
//
//  Created by long on 2017/7/28.
//  Copyright © 2017年 LongLJ. All rights reserved.
//

#import "LJHybirdInteraction.h"
#import "HybirdWebVC.h"
#import "UIBarButtonItem+Auxiliary.h"
#import "UIDevice+LJAdd.h"
#import <objc/runtime.h>
#import <SDWebImage/SDWebImageManager.h>
#import "TestViewController.h"

#define JS_OC_INTERACTION_USE_WEBKIT            @"1"
#define JS_OC_INTERACTION_USE_JAVASCRIPTCORE    @"0"

@interface LJHybirdInteraction()
@end

@implementation LJHybirdInteraction

#pragma mark
#pragma mark - 泛型跳转原生页面
- (void)goToExtraNative:(NSArray *)arges
{
    if (arges != nil && [arges count] > 0) {
        NSMutableDictionary *extraParamters = [[NSMutableDictionary alloc] initWithDictionary:[arges objectAtIndex:1]
                                                                                    copyItems:YES];
        NSString *className = [extraParamters objectForKey:@"Class"];
        Class class = NSClassFromString(className);
        id classObject = [[class alloc] init];

        [extraParamters removeObjectForKey:@"Class"];
        [extraParamters removeObjectForKey:@"isHandleClose"];

        NSArray *allKeys = [extraParamters allKeys];
        for (NSString *oneKey in allKeys) {
            if (oneKey != nil && ![oneKey isEqualToString:@""]) {
                objc_property_t exitProperty = [self handlePropertyName:oneKey forClass:class];
                if (exitProperty != nil) {
                    [classObject setValue:[extraParamters objectForKey:oneKey]
                               forKeyPath:oneKey];
                }
            }
        }
        [self.currentVC.navigationController pushViewController:classObject
                                                       animated:YES];
    }
}

- (objc_property_t)handlePropertyName:(NSString *)propertyName forClass:(Class)class
{
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(class, &count);
    for (int i=0; i<count; i++) {
        NSString *attributeName = [NSString stringWithCString:property_getName(properties[i])
                                                     encoding:NSUTF8StringEncoding];
        if ([attributeName isEqualToString:propertyName]) {
            return properties[i];
        }
    }
    return nil;
}

#pragma mark
#pragma mark - 执行的具体交互动作
#pragma mark
#pragma mark - 获取Cookie数据
- (void)appCookie:(NSArray *)arges
{
    if (arges != nil && [arges count] > 0) {
        HybirdWebVC *hybirdVC = (HybirdWebVC *)self.currentVC;
        
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray *nativeCookies = [cookieStorage cookiesForURL:[NSURL URLWithString:hybirdVC.activeCookieURL]];
        
        NSMutableDictionary *callBackData = [[NSMutableDictionary alloc] initWithCapacity:0];
        for (NSHTTPCookie *oneCookie in nativeCookies) {
            [callBackData setObject:oneCookie.value forKey:oneCookie.name];
            [callBackData setObject:oneCookie.domain forKey:@"domain"];
        }
        
        NSData *callBackJSONData = [NSJSONSerialization dataWithJSONObject:callBackData
                                                                   options:NSJSONWritingPrettyPrinted
                                                                     error:nil];
        NSString *callBackJSONString = [[NSString alloc] initWithData:callBackJSONData encoding:NSUTF8StringEncoding];
        callBackJSONString = [callBackJSONString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        NSString *callBack = [arges objectAtIndex:1];
        NSString *callBackJS = [[NSString alloc] initWithFormat:@"%@('%@')",callBack,callBackJSONString];
        
        [hybirdVC evaluateWebJavaScript:callBackJS];
    }
}
#pragma mark
#pragma mark - 获取APP设备信息
- (void)appData:(NSArray *)arges
{
    if (arges != nil && [arges count] > 0) {
        if ([arges count] == 2) {
            if ([arges objectAtIndex:1] != nil) {
                HybirdWebVC *hybirdVC = (HybirdWebVC *)self.currentVC;

                NSString *device = @"1";
                NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
                NSString *brand = [UIDevice currentDevice].model;
                NSString *IDFA  = [UIDevice IDFA];
                NSString *model = [UIDevice machineModelName];
//                NSString *systemVersion = JS_OC_INTERACTION_USE_JAVASCRIPTCORE;
//                if (hybirdVC.usingWebKitCore) {
//                    systemVersion = JS_OC_INTERACTION_USE_WEBKIT;
//                }
                NSDictionary *callBackData = [[NSDictionary alloc] initWithObjectsAndKeys:
                                              device,@"device",
                                              appVersion,@"appVersion",
//                                              systemVersion,@"systemVersion",
                                              IDFA,@"deviceId",
                                              brand,@"brand",
                                              model,@"model",
                                              nil];
                NSData *callBackJSONData = [NSJSONSerialization dataWithJSONObject:callBackData
                                                                           options:NSJSONWritingPrettyPrinted
                                                                             error:nil];
                NSString *callBackJSONString = [[NSString alloc] initWithData:callBackJSONData encoding:NSUTF8StringEncoding];
                callBackJSONString = [callBackJSONString stringByReplacingOccurrencesOfString:@"\n" withString:@""];

                NSString *callBack = [arges objectAtIndex:1];
                NSString *callBackJS = [[NSString alloc] initWithFormat:@"%@('%@')",callBack,callBackJSONString];

                [hybirdVC evaluateWebJavaScript:callBackJS];
            }
        }
    }
}

#pragma mark
#pragma mark - 改变标题和副标题
- (void)title:(NSArray *)arges
{
    if (arges != nil && [arges count] > 0) {

        if ([[arges objectAtIndex:0] isKindOfClass:[NSDictionary class]] ) {
            NSDictionary *changeTitle = [arges objectAtIndex:0];
            NSString *title = [changeTitle objectForKey:@"title"];
            if (title != nil && ![title isEqualToString:@""]) {
                self.currentVC.navigationItem.title = title;
            }else{
                self.currentVC.navigationItem.title = nil;
            }

            NSString *subTitle = [changeTitle objectForKey:@"subTitle"];
            NSString *subPic = [changeTitle objectForKey:@"subPic"];
            //hideBack:true 时不显示返回按钮, 默认显示
            //showClose: true 显示关闭按钮,默认隐藏
            BOOL showBack = !([[changeTitle objectForKey:@"hideBack"] boolValue]);
            BOOL showClose = [[changeTitle objectForKey:@"showClose"] boolValue];

            HybirdWebVC *hybirdVC = (HybirdWebVC *)self.currentVC;
            [hybirdVC reloadBackBarItemShowBack:showBack
                                      showClose:showClose
                                 closeAuxiliary:[changeTitle objectForKey:@"closeExtra"]];

            if (subPic == nil || [subPic isEqualToString:@""]) {
                if (subTitle != nil && ![subTitle isEqualToString:@""]) {
                    UIBarButtonItem *barItem = [hybirdVC barItemForTitle:subTitle
                                                               auxiliary:[changeTitle objectForKey:@"extra"]];
                    self.currentVC.navigationItem.rightBarButtonItem = barItem;
                }else{
                    self.currentVC.navigationItem.rightBarButtonItem = nil;
                }
            }else{
                [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:subPic]
                                                                      options:SDWebImageDownloaderUseNSURLCache
                                                                     progress:nil
                                                                    completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                                            if (image != nil) {
                                                                                UIBarButtonItem *barItem = [hybirdVC barItemForTitle:image
                                                                                                                           auxiliary:[changeTitle objectForKey:@"extra"]];
                                                                                self.currentVC.navigationItem.rightBarButtonItem = barItem;
                                                                            }else{
                                                                                self.currentVC.navigationItem.rightBarButtonItem = nil;
                                                                            }
                                                                        });

                                                                    }];
            }
        }
    }
}

#pragma mark
#pragma mark - 复制文字
- (void)doCopy:(NSArray *)arges
{
    if (arges.count) {
        NSString *text = [[arges objectAtIndex:0] objectForKey:@"msg"];
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = text;
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:[@"已复制:" stringByAppendingString:text] preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:action];
        [self.currentVC presentViewController:alertVC animated:YES completion:nil];
    }
}

#pragma mark
#pragma mark - gotoTestVC
- (void)gotoTestVC:(NSArray *)arges
{
    if (arges.count) {
        NSString *text = [[arges objectAtIndex:0] objectForKey:@"title"];
        TestViewController *testVC = [[TestViewController alloc] init];
        testVC.testTitle = text;
        [self.currentVC.navigationController pushViewController:testVC animated:YES];
    }
}

#pragma mark - 退出WebView
- (void)close:(NSArray *)arges
{
    [self.currentVC.navigationController popViewControllerAnimated:YES];
}

#pragma mark
#pragma mark - web与活动站互跳方法(新开webView)
- (void)openWindow:(NSArray *)arges
{
    if (arges.count != 0) {
        NSDictionary *dic = arges[0];
        NSString *urlStr = [dic valueForKey:@"url"];
        if (urlStr != nil) {
            HybirdWebVC *VC = [[HybirdWebVC alloc]init];
            VC.webURL = urlStr;
            [self.currentVC.navigationController pushViewController:VC animated:YES];
        }
    }
}

@end

