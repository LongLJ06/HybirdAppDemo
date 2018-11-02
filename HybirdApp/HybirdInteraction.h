//
//  HybirdInteraction.h
//  HybirdApp
//
//  Created by long on 2017/7/28.
//  Copyright © 2017年 LongLJ. All rights reserved.
//
//  此类用来归档Web和OC的交互动作，集中处理方便查看

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <UIKit/UIKit.h>

@interface HybirdInteraction : NSObject

//当前Web所在的视图控制器
@property (nonatomic, weak) UIViewController *currentVC;

/**
 执行交互动作
 
 @param selName    执行动作的方法
 @param parameters 参数
 */
- (void)executeInteractionForSELName:(NSString *)selName parameters:(NSObject *)parameters;

/**
 给JSContext 注入新的JS交互动作

 @param selName         JS交互动作的动作名
 @param hybirdJSContext 需要注入JS交互动作的JSContext实体
 */
- (void)executeInteractionForSELName:(NSString *)selName toJSContext:(JSContext *)hybirdJSContext;


/**
 批量给JSContext 注入新的JS交互动作

 @param selList JS交互动作的动作名列表
 @param hybirdJSContext 需要注入JS交互动作的JSContext实体
 */
- (void)executeInteractionForSELList:(NSArray *)selList toJSContext:(JSContext *)hybirdJSContext;

@end
