//
//  UIDevice+LJAdd.h
//  AFNetworking
//
//  Created by long on 2017/4/24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIDevice(SPComponent)
//获取MAC地址
+ (NSString *)macAddress;

//获取手机型号
+ (NSString *)machineModel;

//获取手机型号名称
+ (NSString *)machineModelName;

//系统型号数字化
+ (double)systemVersion;

//获取App版本号
+ (NSString *)bundleVersion;

//获取手机的语言(en:英文  zh-Hans:简体中文   zh-Hant:繁体中文    ja:日本  ......)
+ (NSString *)preferredLanguage;

//广告标示符IDFA
+ (NSString *)IDFA;

//Vindor标示符IDFV
+ (NSString *)IDFV;

@end
