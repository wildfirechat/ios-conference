//
//  AppDelegate.m
//  WFZoom
//
//  Created by WF Chat on 2021/9/3.
//  Copyright © 2021年 WildFireChat. All rights reserved.
//

#import "AppDelegate.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCConfig.h"
#import "WFCLoginViewController.h"
#import "WFZHomeViewController.h"
#import "AppService.h"
#import "WFZConferenceInfoViewController.h"

@interface AppDelegate () <ConnectionStatusDelegate, ReceiveMessageDelegate, WFAVEngineDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [WFCCNetworkService startLog];
    [WFCCNetworkService sharedInstance].connectionStatusDelegate = self;
    [WFCCNetworkService sharedInstance].receiveMessageDelegate = self;
    [[WFCCNetworkService sharedInstance] setServerAddress:IM_SERVER_HOST];
    [[WFAVEngineKit sharedEngineKit] setVideoProfile:kWFAVVideoProfile360P swapWidthHeight:YES];
    [WFAVEngineKit sharedEngineKit].delegate = self;

    
    NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedToken"];
    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    
    
    UIViewController *vc;
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    if (savedToken.length > 0 && savedUserId.length > 0) {
        //需要注意token跟clientId是强依赖的，一定要调用getClientId获取到clientId，然后用这个clientId获取token，这样connect才能成功，如果随便使用一个clientId获取到的token将无法链接成功。另外不能多次connect，如果需要切换用户请先disconnect，然后3秒钟之后再connect（如果是用户手动登录可以不用等，因为用户操作很难3秒完成，如果程序自动切换请等3秒）。
        [[WFCCNetworkService sharedInstance] connect:savedUserId token:savedToken];
        vc = [[WFZHomeViewController alloc] init];
        self.window.rootViewController = vc;
        [[AppService sharedAppService] getMyPrivateConferenceId:^(NSString * _Nonnull conferenceId) {
            [[NSUserDefaults standardUserDefaults] setValue:conferenceId forKey:WFZOOM_PRIVATE_CONFERENCE_ID];
        } error:^(int errorCode, NSString * _Nonnull message) {
            NSLog(@"error");
        }];
    } else {
        vc = [[WFCLoginViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        self.window.rootViewController = nav;
    }
    
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([url.scheme isEqualToString:@"wfzoom"]) {
        NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];
        NSString *conferenceId;
        NSString *password;
        for (NSURLQueryItem *item in components.queryItems) {
            if([@"id" isEqualToString:item.name]) {
                conferenceId = item.value;
            } else if([@"pwd" isEqualToString:item.name]) {
                password = item.value;
            }
        }
        if(conferenceId.length && [WFCCNetworkService sharedInstance].isLogined) {
            WFZConferenceInfoViewController *vc = [[WFZConferenceInfoViewController alloc] init];
            vc.conferenceId = conferenceId;
            vc.password = password;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            [self.window.rootViewController presentViewController:nav animated:YES completion:nil];
        }
        
        return YES;
    }
    return NO;
}

- (void)onConnectionStatusChanged:(ConnectionStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (status == kConnectionStatusRejected || status == kConnectionStatusTokenIncorrect || status == kConnectionStatusSecretKeyMismatch) {
            [[WFCCNetworkService sharedInstance] disconnect:YES clearSession:NO];
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
            [[AppService sharedAppService] clearAppServiceAuthInfos];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else if (status == kConnectionStatusLogout) {
            UIViewController *loginVC = [[WFCLoginViewController alloc] init];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
            self.window.rootViewController = nav;
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
            [[AppService sharedAppService] clearAppServiceAuthInfos];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    });
}

- (void)onReceiveMessage:(NSArray<WFCCMessage *> *)messages hasMore:(BOOL)hasMore {
    
}

- (void)didCallEnded:(WFAVCallEndReason)reason duration:(int)callDuration {
    
}

- (void)didReceiveCall:(WFAVCallSession * _Nonnull)session {
    
}

- (void)shouldStartRing:(BOOL)isIncoming {
    
}

- (void)shouldStopRing {
    
}

@end
