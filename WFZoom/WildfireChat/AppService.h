//
//  AppService.h
//  WildFireChat
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN

@class WFZConferenceInfo;
@interface AppService : NSObject
+ (AppService *)sharedAppService;

- (void)login:(NSString *)user password:(NSString *)password success:(void(^)(NSString *userId, NSString *token, BOOL newUser))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)sendCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;

- (void)pcScaned:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcConfirmLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcCancelLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)uploadLogs:(void(^)(void))successBlock error:(void(^)(NSString *errorMsg))errorBlock;

- (void)showPCSessionViewController:(UIViewController *)baseController pcClient:(WFCCPCOnlineInfo *)clientInfo;

- (void)complain:(NSString *)text success:(void(^)(void))successBlock error:(void(^)(int code, NSString *errorMsg))errorBlock;

- (void)getMyPrivateConferenceId:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)createConference:(WFZConferenceInfo *)conferenceInfo success:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)queryConferenceInfo:(NSString *)conferenceId password:(NSString *)password success:(void(^)(WFZConferenceInfo *conferenceInfo))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)destroyConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)favConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)unfavConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)isFavConference:(NSString *)conferenceId success:(void(^)(BOOL isFav))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)getFavConferences:(void(^)(NSArray<WFZConferenceInfo *> *))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (NSData *)getAppServiceCookies;
- (NSString *)getAppServiceAuthToken;

//清除应用服务认证cookies和认证token
- (void)clearAppServiceAuthInfos;
@end

NS_ASSUME_NONNULL_END
