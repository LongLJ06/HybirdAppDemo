//
//  HybirdInteraction.m
//  HybirdApp
//
//  Created by long on 2017/7/28.
//  Copyright © 2017年 LongLJ. All rights reserved.
//

#import "HybirdInteraction.h"
#import "HybirdWebVC.h"

@implementation HybirdInteraction

- (void)handleJSAction:(NSArray *)arges
{
    if (arges != nil && [arges count] > 0) {
        NSString *selName = [arges objectAtIndex:0];
        NSMutableArray *paramters = [[NSMutableArray alloc] initWithCapacity:0];
        if ([arges count] > 1) {
            NSInteger cnt = [arges count];
            for (int i=1; i<cnt; i++) {
                [paramters addObject:[arges objectAtIndex:i]];
            }
            selName = [NSString stringWithFormat:@"%@:",selName];
        }else{
            paramters = nil;
        }
        [self executeInteractionForSELName:selName parameters:paramters];
    }
}

#pragma mark
#pragma mark - 混合交互的基本方法
- (void)executeInteractionForSELName:(NSString *)selName parameters:(NSObject *)parameters
{
    if (!selName.length) {
        return;
    }
    
    BOOL (^executeBlock)(NSString *, NSObject *) = ^BOOL(NSString *selName, NSObject *parameters) {
        SEL sel = NSSelectorFromString(selName);
        NSMethodSignature *methodSignature = [self methodSignatureForSelector:sel];
        if (methodSignature) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
            //设置方法调用者
            invocation.target = self;
            //注意：这里的方法名一定要与方法签名类中的方法一致
            invocation.selector = sel;
            if (parameters != nil && ![parameters isKindOfClass:[NSNull class]]) {
                //参数赋值 通过numberOfArguments方法获取的参数个数,是包含self和_cmd的,真正的参数是从第二个开始的
                NSUInteger methodArgsCount = methodSignature.numberOfArguments;
                if (methodArgsCount > 2) {
                    [invocation setArgument:&parameters atIndex:2];
                }
            }
            [invocation invoke];
        }
        return methodSignature;
    };
    
    NSString *mainInteraction = [selName substringToIndex:selName.length-1];
    if ([self.currentVC.mainInteractionArr containsObject:mainInteraction]) {
        if (!executeBlock(selName, parameters)) {
            [self handleJSAction:(NSArray *)parameters];
        }
    }else {
        executeBlock(selName, parameters);
    }
}

- (void)executeInteractionForSELName:(NSString *)selName toJSContext:(JSContext *)hybirdJSContext
{
    if (hybirdJSContext != nil && (selName != nil && ![selName isEqualToString:@""])) {
        //向WebView注入JS代码
        __weak typeof(self) weakSelf = self;
        __strong typeof(selName) strongSelName = selName;
        hybirdJSContext[selName] = ^(){
            NSMutableArray *parameters = [[NSMutableArray alloc] initWithCapacity:0];
            NSArray *args = [JSContext currentArguments];
            for (JSValue *oneJSValue in args) {
                if ([oneJSValue isObject]) {
                    [parameters addObject:[oneJSValue toDictionary]];
                }else if ([oneJSValue isNull] || [oneJSValue isUndefined]){
                    [parameters addObject:[NSNull null]];
                }else{
                    [parameters addObject:[oneJSValue toString]];
                }
            }
            NSLog(@"parameters === %@",parameters);
            if (weakSelf != nil && strongSelName != nil) {
                NSString *interactionSelName;
                if ([parameters count] > 0) {
                    interactionSelName = [[NSString alloc] initWithFormat:@"%@:",strongSelName];
                }else{
                    interactionSelName = [[NSString alloc] initWithFormat:@"%@",strongSelName];
                }
                
                //回到主线程 进行交互动作的操作
                __strong typeof(interactionSelName) strongInteractionSelName = interactionSelName;
                __strong typeof(parameters) strongParameters = parameters;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf executeInteractionForSELName:strongInteractionSelName
                                                parameters:strongParameters];
                });
            }
        };
    }
}

- (void)executeInteractionForSELList:(NSArray *)selList toJSContext:(JSContext *)hybirdJSContext
{
    if (selList != nil && [selList count] > 0) {
        for (NSString *selName in selList) {
            if ([selName isKindOfClass:[NSString class]]) {
                [self executeInteractionForSELName:selName toJSContext:hybirdJSContext];
            }
        }
    }
}

@end
