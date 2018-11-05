//
//  UIDevice+LJAdd.m
//  AFNetworking
//
//  Created by long on 2017/4/24.
//

#import "UIDevice+LJAdd.h"
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <AdSupport/AdSupport.h>

@implementation UIDevice(LJAdd)
//获取MAC地址
+ (NSString *)macAddress
{
    static NSString *macAddressString;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        int                 mgmtInfoBase[6];
        char                *msgBuffer = NULL;
        size_t              length;
        unsigned char       macAddress[6];
        struct if_msghdr    *interfaceMsgStruct;
        struct sockaddr_dl  *socketStruct;
        NSString            *errorFlag = NULL;
        
        
        mgmtInfoBase[0] = CTL_NET;
        mgmtInfoBase[1] = AF_ROUTE;
        mgmtInfoBase[2] = 0;
        mgmtInfoBase[3] = AF_LINK;
        mgmtInfoBase[4] = NET_RT_IFLIST;
        
        if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0){
            errorFlag = @"if_nametoindex failure";
        }else{
            if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0){
                errorFlag = @"sysctl mgmtInfoBase failure";
            }else{
                if ((msgBuffer = malloc(length)) == NULL){
                    errorFlag = @"buffer allocation failure";
                }else{
                    if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0){
                        errorFlag = @"sysctl msgBuffer failure";
                    }
                }
            }
        }
        
        if (errorFlag != NULL){
            NSLog(@"Error: %@", errorFlag);
        }else{
            interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
            socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
            
            memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
            
            macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                macAddress[0], macAddress[1], macAddress[2],
                                macAddress[3], macAddress[4], macAddress[5]];
            
            free(msgBuffer);
        }
        
    });
    return macAddressString;
}

//获取手机型号
+ (NSString *)machineModel
{
    static dispatch_once_t onceToken;
    static NSString *model;
    dispatch_once(&onceToken, ^{
        int mib[2];
        size_t len;
        mib[0] = CTL_HW;
        mib[1] = HW_MACHINE;
        sysctl(mib, 2, NULL, &len, NULL, 0);
        char *machine = malloc(len);
        sysctl(mib, 2, machine, &len, NULL, 0);
        
        model = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
        free(machine);
    });
    return model;
}

//获取手机型号名称
+ (NSString *)machineModelName
{
    static dispatch_once_t onceToken;
    static NSString *name;
    dispatch_once(&onceToken, ^{
        NSString *model = [UIDevice machineModel];
        if (!model) return;
        NSDictionary *dic = @{
                              @"Watch1,1" : @"Apple Watch 38mm",
                              @"Watch1,2" : @"Apple Watch 42mm",
                              @"Watch2,3" : @"Apple Watch Series 2 38mm",
                              @"Watch2,4" : @"Apple Watch Series 2 42mm",
                              @"Watch2,6" : @"Apple Watch Series 1 38mm",
                              @"Watch1,7" : @"Apple Watch Series 1 42mm",
                              
                              @"iPod1,1" : @"iPod touch 1",
                              @"iPod2,1" : @"iPod touch 2",
                              @"iPod3,1" : @"iPod touch 3",
                              @"iPod4,1" : @"iPod touch 4",
                              @"iPod5,1" : @"iPod touch 5",
                              @"iPod7,1" : @"iPod touch 6",
                              
                              @"iPhone1,1" : @"iPhone 1G",
                              @"iPhone1,2" : @"iPhone 3G",
                              @"iPhone2,1" : @"iPhone 3GS",
                              @"iPhone3,1" : @"iPhone 4 (GSM)",
                              @"iPhone3,2" : @"iPhone 4",
                              @"iPhone3,3" : @"iPhone 4 (CDMA)",
                              @"iPhone4,1" : @"iPhone 4S",
                              @"iPhone5,1" : @"iPhone 5",
                              @"iPhone5,2" : @"iPhone 5",
                              @"iPhone5,3" : @"iPhone 5c",
                              @"iPhone5,4" : @"iPhone 5c",
                              @"iPhone6,1" : @"iPhone 5s",
                              @"iPhone6,2" : @"iPhone 5s",
                              @"iPhone7,1" : @"iPhone 6 Plus",
                              @"iPhone7,2" : @"iPhone 6",
                              @"iPhone8,1" : @"iPhone 6s",
                              @"iPhone8,2" : @"iPhone 6s Plus",
                              @"iPhone8,4" : @"iPhone SE",
                              @"iPhone9,1" : @"iPhone 7",
                              @"iPhone9,2" : @"iPhone 7 Plus",
                              @"iPhone9,3" : @"iPhone 7",
                              @"iPhone9,4" : @"iPhone 7 Plus",
                              @"iPhone10,1" : @"iPhone 8",//国行(A1863)、日行(A1906)
                              @"iPhone10,4" : @"iPhone 8",//美版(Global/A1905)
                              @"iPhone10,2" : @"iPhone 8 Plus",//国行(A1864)、日行(A1898)
                              @"iPhone10,5" : @"iPhone 8 Plus",//美版(Global/A1897)
                              @"iPhone10,3" : @"iPhone X",//国行(A1865)、日行(A1902)
                              @"iPhone10,6" : @"iPhone X",//美版(Global/A1901)
                              
                              @"iPad1,1" : @"iPad 1",
                              @"iPad2,1" : @"iPad 2 (WiFi)",
                              @"iPad2,2" : @"iPad 2 (GSM)",
                              @"iPad2,3" : @"iPad 2 (CDMA)",
                              @"iPad2,4" : @"iPad 2",
                              @"iPad2,5" : @"iPad mini 1",
                              @"iPad2,6" : @"iPad mini 1",
                              @"iPad2,7" : @"iPad mini 1",
                              @"iPad3,1" : @"iPad 3 (WiFi)",
                              @"iPad3,2" : @"iPad 3 (4G)",
                              @"iPad3,3" : @"iPad 3 (4G)",
                              @"iPad3,4" : @"iPad 4",
                              @"iPad3,5" : @"iPad 4",
                              @"iPad3,6" : @"iPad 4",
                              @"iPad4,1" : @"iPad Air",
                              @"iPad4,2" : @"iPad Air",
                              @"iPad4,3" : @"iPad Air",
                              @"iPad4,4" : @"iPad mini 2",
                              @"iPad4,5" : @"iPad mini 2",
                              @"iPad4,6" : @"iPad mini 2",
                              @"iPad4,7" : @"iPad mini 3",
                              @"iPad4,8" : @"iPad mini 3",
                              @"iPad4,9" : @"iPad mini 3",
                              @"iPad5,1" : @"iPad mini 4",
                              @"iPad5,2" : @"iPad mini 4",
                              @"iPad5,3" : @"iPad Air 2",
                              @"iPad5,4" : @"iPad Air 2",
                              @"iPad6,3" : @"iPad Pro (9.7 inch)",
                              @"iPad6,4" : @"iPad Pro (9.7 inch)",
                              @"iPad6,7" : @"iPad Pro (12.9 inch)",
                              @"iPad6,8" : @"iPad Pro (12.9 inch)",
                              @"iPad6,11" : @"iPad 5 (WiFi)",
                              @"iPad6,12" : @"iPad 5 (Cellular)",
                              @"iPad7,1" : @"iPad Pro 12.9 inch 2nd gen (WiFi)",
                              @"iPad7,2" : @"iPad Pro 12.9 inch 2nd gen (Cellular)",
                              @"iPad7,3" : @"iPad Pro 10.5 inch (WiFi)",
                              @"iPad7,4" : @"iPad Pro 10.5 inch (Cellular)",
                              
                              @"AppleTV2,1" : @"Apple TV 2",
                              @"AppleTV3,1" : @"Apple TV 3",
                              @"AppleTV3,2" : @"Apple TV 3",
                              @"AppleTV5,3" : @"Apple TV 4",
                              
                              @"i386" : @"Simulator x86",
                              @"x86_64" : @"Simulator x64",
                              };
        name = dic[model];
        if (!name) name = model;
    });
    return name;
}

//系统型号数字化
+ (double)systemVersion
{
    static double version;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        version = [UIDevice currentDevice].systemVersion.doubleValue;
    });
    return version;
}

//获取App版本号
+ (NSString *)bundleVersion
{
    static NSString *bundleVersion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    });
    return bundleVersion;
}

//获取手机的语言(en:英文  zh-Hans:简体中文   zh-Hant:繁体中文    ja:日本  ......)
+ (NSString *)preferredLanguage
{
    static NSString *preferredLanguage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
        NSArray* languages = [defs objectForKey:@"AppleLanguages"];
        preferredLanguage = [languages objectAtIndex:0];
    });
    return preferredLanguage;
}

//广告标示符IDFA
+ (NSString *)IDFA
{
    static NSString *IDFA;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IDFA = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    });
    return IDFA;
}

//Vindor标示符IDFV
+ (NSString *)IDFV
{
    static NSString *IDFV;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IDFV = [[UIDevice currentDevice].identifierForVendor UUIDString];
    });
    return IDFV;
}

@end
