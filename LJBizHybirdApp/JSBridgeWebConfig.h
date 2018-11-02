//
//  JSBridgeWebConfig.h
//  HybirdApp
//
//  Created by long on 2017/7/28.
//  Copyright © 2017年 LongLJ. All rights reserved.
//

#ifndef JSBridgeWebConfig_h
#define JSBridgeWebConfig_h

#pragma mark
#pragma mark - 视觉相关
//返回按钮的图片名称
#define JSBridgeNavBackBarImage                      @"nav_bar_back"
//关闭按钮的图片名称
#define JSBridgeNavCloseBarImage                     @"nav_bar_close"

#pragma mark
#pragma mark - App调用WAP相关
//返回事件
#define JSBridgeTriggerGoBack                        @"WAP.trigger('goBack')"
//加载完成通知WAP事件
#define JSBridgeTriggerLoaded                        @"WAP.trigger('loaded')"
//双按钮时无参数关闭web事件
#define JSBridgeTriggerCloseEvent                    @"WAP.trigger('closeEvent')"
//双按钮时带参数关闭web事件
#define JSBridgeTriggerCloseEventWithArge            @"WAP.trigger('closeEvent','%@')"
//无参数副标题点击事件
#define JSBridgeTriggerSubTitleEvent                 @"WAP.trigger('subTitleEvent')"
//带参数副标题点击事件
#define JSBridgeTriggerSubTitleEventWithArge         @"WAP.trigger('subTitleEvent','%@')"

#pragma mark
#pragma mark - WAP调用APP主交互相关
//wap从app获取数据
#define JSBridgeInteractionGetData                  @"getData"
//wap从app推送数据
#define JSBridgeInteractionPutData                  @"putData"
//wap跳转到app的原生页面
#define JSBridgeInteractionGoToNative               @"goToNative"
//wap指定app的动作，比如分享
#define JSBridgeInteractionDoAction                 @"doAction"
//额外的多参数自适应交互行为，方便上线后临时的交互
#define JSBridgeInteractionGoToExtraNative          @"goToExtraNative"


#endif /* JSBridgeWebConfig_h */
