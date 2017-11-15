//
//  WeakScriptMessageDelegate.h
//  XWebBase
//
//  Created by 许宇航 on 2017/10/31.
//  Copyright © 2017年 许宇航. All rights reserved.
//
//  消除WKScriptMessageHandler 不释放问题   http://www.jianshu.com/p/1f2dc3d3090a

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface WeakScriptMessageDelegate : NSObject
@property (nonatomic, weak) id<WKScriptMessageHandler> scriptDelegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate;


@end
