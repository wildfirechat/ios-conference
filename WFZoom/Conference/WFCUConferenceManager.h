//
//  WFCUConferenceManager.h
//  WFChatUIKit
//
//  Created by WF Chat on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kMuteStateChanged;

@protocol WFCUConferenceManagerDelegate <NSObject>
-(void)onChangeModeRequest:(BOOL)isAudience;
@end

@interface WFCUConferenceManager : NSObject
+ (WFCUConferenceManager *)sharedInstance;
@property (nonatomic, weak) id<WFCUConferenceManagerDelegate> delegate;

- (void)muteAudio:(BOOL)mute;
- (void)muteVideo:(BOOL)mute;
- (void)muteAudioVideo:(BOOL)mute;
- (void)enableAudioDisableVideo;


- (void)request:(NSString *)userId changeModel:(BOOL)isAudience inConference:(NSString *)conferenceId;
- (void)kickoff:(NSString *)userId inConference:(NSString *)conferenceId;

- (NSString *)linkFromConferenceId:(NSString *)conferenceId password:(NSString *)password;
@end
