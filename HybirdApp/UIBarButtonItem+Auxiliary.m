//
//  UIBarButtonItem+Auxiliary.m
//  HybirdApp
//
//  Created by long on 2017/7/28.
//  Copyright © 2017年 LongLJ. All rights reserved.
//

#import "UIBarButtonItem+Auxiliary.h"
#import <objc/runtime.h>

@implementation UIBarButtonItem (Auxiliary)

static char const *auxiliaryObjectKey = "auxiliaryObjectKey";

- (void)setAuxiliaryObject:(NSObject *)auxiliaryObject
{
    objc_setAssociatedObject(self, auxiliaryObjectKey, auxiliaryObject, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSObject *)auxiliaryObject
{
    return objc_getAssociatedObject(self, auxiliaryObjectKey);
}


@end

