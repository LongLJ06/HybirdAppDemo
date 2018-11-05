//
//  ViewController.m
//  HybirdAppDemo
//
//  Created by long on 2018/11/1.
//  Copyright © 2018年 LongLJ. All rights reserved.
//

#import "ViewController.h"
#import "LJHybirdWebViewController.h"
#import "LJHybirdInteraction.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"HybirdAppDemo";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"jump" style:UIBarButtonItemStylePlain target:self action:@selector(jumpClick)];
}

- (void)jumpClick {
    LJHybirdWebViewController *VC = [[LJHybirdWebViewController alloc] init];
    LJHybirdInteraction *interaction = [[LJHybirdInteraction alloc] init];
    interaction.currentVC = VC;
    VC.interactionSubject = interaction;
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"test.html" withExtension:nil];
    NSString *str = [NSString stringWithContentsOfURL:fileUrl encoding:NSUTF8StringEncoding error:nil];
    [VC loadHTMLString:str baseURL:nil];
    [self.navigationController pushViewController:VC animated:YES];
}


@end
