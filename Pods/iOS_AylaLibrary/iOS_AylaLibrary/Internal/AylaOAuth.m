//
//  AylaOAuth.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/5/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaOAuth.h"
#import "AylaNetworks.h"
#import "AylaErrorSupport.h"
@interface AylaOAuth (){
   __weak UIWebView *_webView;
    void (^_successBlock)(NSString *code);
    void (^_failureBlock)(AylaError *err);
    AylaOAuthAccountType _accountType;
}
@end

NSString * const aylaOAuthRedirectUriRemote = @"http%3A%2F%2Fmobile.aylanetworks.com%2F";
NSString * const aylaOAuthRedirectUriLocal = @"http%3A%2F%2Flocalhost:9000%2F";
NSString * const aylaOAuthCodeParser = @"code=";
NSString * const aylaOAuthStateParser = @"state=";
NSString * const aylaOAuthErrorParser = @"error=";

@implementation AylaOAuth

- (void)setWebView:(UIWebView *)webView
{
    _webView = webView;
}

- (id)initWithType:(AylaOAuthAccountType)type webView:(UIWebView *)webView {
    self = [super init];
    if(self) {
        _successBlock = nil;
        _failureBlock = nil;
        _webView = webView;
        _accountType = type;
    }
    return self;
}

- (void)authenticateOnWebViewWithURL:(NSURL *)url
                    success:(void (^)(NSString *code))successBlock
                    failure:(void (^)(AylaError *err))failureBlock
{
    [_webView setDelegate:self];
    [_webView setScalesPageToFit:YES];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];
    
    _successBlock = successBlock;
    _failureBlock = failureBlock;
}

- (void)dealloc
{
    _webView.delegate = nil;
    [_webView stopLoading];
    _webView = nil;
}

#pragma mark -

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = [request URL];    
    if ([[url absoluteString] rangeOfString:[NSString stringWithFormat:@"%@%@",[([_accountType isEqualToString: aylaOAuthAccountTypeGoogle]?aylaOAuthRedirectUriLocal:aylaOAuthRedirectUriRemote) stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], @"?"]].location != NSNotFound ) {
        if([[url absoluteString] rangeOfString:@"error="].location != NSNotFound) {
            NSUInteger errStart = [[url absoluteString] rangeOfString:@"error="].location;
            //NSUInteger stateStart = [[url absoluteString] rangeOfString:aylaOAuthStateParser].location;
            
            if(errStart != NSNotFound &&
               [url.absoluteString rangeOfString:@"access_denied"].location != NSNotFound) {
               dispatch_async(dispatch_get_main_queue(), ^{
                    if(_failureBlock) {
                        AylaError *err = [AylaError new]; err.httpStatusCode = 401;
                        err.errorCode = AML_USER_OAUTH_DENY;
                        err.nativeErrorInfo = nil;
                        err.errorInfo = nil;
                        _failureBlock(err);
                    }
               });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(_failureBlock) {
                        AylaError *err = [AylaError new]; err.httpStatusCode = 401;
                        err.errorCode = AML_USER_OAUTH_ERROR;
                        err.nativeErrorInfo = nil;
                        err.errorInfo = nil;
                        _failureBlock(err);
                    }
                });
            }
            saveToLog(@"%@, %@, %@:%@, %@:%@ %@", @"E", @"User",
                      @"error", @"", @"url",url.absoluteString, @"aylaAuth.webView");
        }
        else {
            NSUInteger startPoint = [[url absoluteString] rangeOfString:aylaOAuthCodeParser].location;
            NSString *code = nil;
            
            if([_accountType isEqualToString:aylaOAuthAccountTypeGoogle]) {
                code = [[url absoluteString] substringFromIndex:startPoint+[aylaOAuthCodeParser length]];
            }
            else if([_accountType isEqualToString:aylaOAuthAccountTypeFacebook]) {
                
                NSUInteger stateStart = [[url absoluteString] rangeOfString:[NSString stringWithFormat:@"&%@", aylaOAuthStateParser]].location;
                NSUInteger codeLength = stateStart - (startPoint + [aylaOAuthCodeParser length]);
                
                code = [[url absoluteString] substringWithRange:NSMakeRange(startPoint + [aylaOAuthCodeParser length], codeLength)];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if(_successBlock) {
                    _successBlock(code) ;
                }
            });
        }
    }
    return YES;
}

@end
