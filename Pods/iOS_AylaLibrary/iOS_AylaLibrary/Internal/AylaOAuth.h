//
//  AylaOAuth.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/5/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
extern NSString * const aylaOAuthRedirectUriRemote;
extern NSString * const aylaOAuthRedirectUriLocal;

@class AylaError;
@interface AylaOAuth : NSObject<UIWebViewDelegate>
@property (nonatomic, readonly) NSString *type;

- (id)   initWithType:(NSString *)type webView:(UIWebView *)webView;
- (void) authenticateOnWebViewWithURL:(NSURL *)url
                             success:(void (^)(NSString *code))successBlock
                             failure:(void (^)(AylaError *err))failureBlock;
@end
