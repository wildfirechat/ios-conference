//
//  AppService.m
//  WildFireChat
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "AppService.h"
#import <WFChatClient/WFCChatClient.h>
#import "AFNetworking.h"
#import "WFCConfig.h"
#import "WFZConferenceInfo.h"

static AppService *sharedSingleton = nil;

#define WFC_APPSERVER_COOKIES @"WFC_APPSERVER_COOKIES"
#define WFC_APPSERVER_AUTH_TOKEN  @"WFC_APPSERVER_AUTH_TOKEN"

#define AUTHORIZATION_HEADER @"authToken"

@implementation AppService 
+ (AppService *)sharedAppService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[AppService alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)login:(NSString *)user password:(NSString *)password success:(void(^)(NSString *userId, NSString *token, BOOL newUser))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    
    [self post:@"/login" data:@{@"mobile":user, @"code":password, @"clientId":[[WFCCNetworkService sharedInstance] getClientId], @"platform":@(Platform_iOS)} isLogin:YES success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSString *userId = dict[@"result"][@"userId"];
            NSString *token = dict[@"result"][@"token"];
            BOOL newUser = [dict[@"result"][@"register"] boolValue];
            if(successBlock) successBlock(userId, token, newUser);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)sendCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock {
    
    [self post:@"/send_code" data:@{@"mobile":phoneNumber} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock(@"error");
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(error.localizedDescription);
    }];
}


- (void)pcScaned:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = [NSString stringWithFormat:@"/scan_pc/%@", sessionId];
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], @"Network error");
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)pcConfirmLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/confirm_pc";
    NSDictionary *param = @{@"token":sessionId, @"user_id":[WFCCNetworkService sharedInstance].userId, @"quick_login":@(1)};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], @"Network error");
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)pcCancelLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/cancel_pc";
    NSDictionary *param = @{@"token":sessionId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], @"Network error");
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)post:(NSString *)path data:(id)data isLogin:(BOOL)isLogin success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSError * _Nonnull error))errorBlock {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
    NSString *authToken = [self getAppServiceAuthToken];
    if(authToken.length) {
        [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
    } else {
        NSData *cookiesdata = [self getAppServiceCookies];//url和登陆时传的url 是同一个
        if([cookiesdata length]) {
            NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
            NSHTTPCookie *cookie;
            for (cookie in cookies) {
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            }
        }
    }
    
    [manager POST:[APP_SERVER_ADDRESS stringByAppendingPathComponent:path]
       parameters:data
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if(isLogin) { //鉴权信息
                NSString *appToken;
                if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                    appToken = [r allHeaderFields][AUTHORIZATION_HEADER];
                }

                if(appToken.length) {
                    [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:WFC_APPSERVER_AUTH_TOKEN];
                } else {
                    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:APP_SERVER_ADDRESS]];
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
                    [[NSUserDefaults standardUserDefaults] setObject:data forKey:WFC_APPSERVER_COOKIES];
                }
            }
        
            NSDictionary *dict = responseObject;
            dispatch_async(dispatch_get_main_queue(), ^{
              successBlock(dict);
            });
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock(error);
            });
          }];
}

- (void)uploadLogs:(void(^)(void))successBlock error:(void(^)(NSString *errorMsg))errorBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray<NSString *> *logFiles = [[WFCCNetworkService getLogFilesPath]  mutableCopy];
        
        NSMutableArray *uploadedFiles = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"mars_uploaded_files"] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 compare:obj2];
        }] mutableCopy];
        
        //日志文件列表需要删除掉已上传记录，避免重复上传。
        //但需要上传最后一条已经上传日志，因为那个日志文件可能在上传之后继续写入了，所以需要继续上传
        if (uploadedFiles.count) {
            [uploadedFiles removeLastObject];
        } else {
            uploadedFiles = [[NSMutableArray alloc] init];
        }
        for (NSString *file in [logFiles copy]) {
            NSString *name = [file componentsSeparatedByString:@"/"].lastObject;
            if ([uploadedFiles containsObject:name]) {
                [logFiles removeObject:file];
            }
        }
        
        
        __block NSString *errorMsg = nil;
        
        for (NSString *logFile in logFiles) {
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
            
            NSString *url = [APP_SERVER_ADDRESS stringByAppendingFormat:@"/logs/%@/upload", [WFCCNetworkService sharedInstance].userId];
            
             dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            __block BOOL success = NO;

            [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                NSData *logData = [NSData dataWithContentsOfFile:logFile];
                if (!logData.length) {
                    logData = [@"empty" dataUsingEncoding:NSUTF8StringEncoding];
                }
                
                NSString *fileName = [[NSURL URLWithString:logFile] lastPathComponent];
                [formData appendPartWithFileData:logData name:@"file" fileName:fileName mimeType:@"application/octet-stream"];
            } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *dict = (NSDictionary *)responseObject;
                    if([dict[@"code"] intValue] == 0) {
                        NSLog(@"上传成功");
                        success = YES;
                        NSString *name = [logFile componentsSeparatedByString:@"/"].lastObject;
                        [uploadedFiles removeObject:name];
                        [uploadedFiles addObject:name];
                        [[NSUserDefaults standardUserDefaults] setObject:uploadedFiles forKey:@"mars_uploaded_files"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                }
                if (!success) {
                    errorMsg = @"服务器响应错误";
                }
                dispatch_semaphore_signal(sema);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"上传失败：%@", error);
                dispatch_semaphore_signal(sema);
                errorMsg = error.localizedFailureReason;
            }];
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
            if (!success) {
                errorBlock(errorMsg);
                return;
            }
        }
        
        successBlock();
    });
    
}

- (void)changeName:(NSString *)newName success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/change_name" data:@{@"newName":newName} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errmsg;
            if ([dict[@"code"] intValue] == 17) {
                errmsg = @"用户名已经存在";
            } else {
                errmsg = @"网络错误";
            }
            if(errorBlock) errorBlock([dict[@"code"] intValue], errmsg);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)complain:(NSString *)text success:(void(^)(void))successBlock error:(void(^)(int code, NSString *errorMsg))errorBlock {
    [self post:@"/complain" data:@{@"text":text} isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getMyPrivateConferenceId:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/get_my_id" data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            NSString *conferenceId = dict[@"result"];
            successBlock(conferenceId);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)createConference:(WFZConferenceInfo *)conferenceInfo success:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/create" data:[conferenceInfo toDictionary] isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            NSString *conferenceId = dict[@"result"];
            conferenceInfo.conferenceId = conferenceId;
            successBlock(conferenceId);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)queryConferenceInfo:(NSString *)conferenceId password:(NSString *)password success:(void(^)(WFZConferenceInfo *conferenceInfo))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSDictionary *data;
    if(password.length) {
        data = @{@"conferenceId":conferenceId, @"password":password};
    } else {
        data = @{@"conferenceId":conferenceId};
    }
    
    [self post:@"/conference/info" data:data isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            WFZConferenceInfo *info = [WFZConferenceInfo fromDictionary:dict[@"result"]];
            successBlock(info);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)destroyConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/destroy/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)favConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/fav/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)unfavConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/unfav/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)isFavConference:(NSString *)conferenceId success:(void(^)(BOOL isFav))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/is_fav/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock(YES);
        } else if(code == 16) {
            successBlock(NO);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getFavConferences:(void(^)(NSArray<WFZConferenceInfo *> *))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/fav_conferences" data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            NSArray<NSDictionary *> *ls = dict[@"result"];
            NSMutableArray *output = [[NSMutableArray alloc] init];
            [ls enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [output addObject:[WFZConferenceInfo fromDictionary:obj]];
            }];
            successBlock(output);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (NSData *)getAppServiceCookies {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WFC_APPSERVER_COOKIES];
}

- (NSString *)getAppServiceAuthToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WFC_APPSERVER_AUTH_TOKEN];
}

- (void)clearAppServiceAuthInfos {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WFC_APPSERVER_COOKIES];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WFC_APPSERVER_AUTH_TOKEN];
//
//    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];//此处id要与开发者中心创建时一致
//
//    //1. 保存app cookies
//
//        [sharedDefaults removeObjectForKey:WFC_SHARE_APPSERVICE_AUTH_TOKEN];
//    NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] cookies];
//    [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] deleteCookie:obj];
//    }];
}

@end
