//
//  WFCUParticipantCollectionViewCell.m
//  WFChatUIKit
//
//  Created by dali on 2020/1/20.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUParticipantCollectionViewCell.h"
#import <SDWebImage/SDWebImage.h>
#import "WFCUWaitingAnimationView.h"
#import "ConferenceLabelView.h"

@interface WFCUParticipantCollectionViewCell ()
@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)WFCUWaitingAnimationView *stateLabel;
@property(nonatomic, strong)NSString *userId;
@property (nonatomic, strong)ConferenceLabelView *conferenceLabelView;
@end

@implementation WFCUParticipantCollectionViewCell
- (void)setUserInfo:(WFCCUserInfo *)userInfo callProfile:(WFAVParticipantProfile *)profile {
    self.userId = userInfo.userId;
    self.layer.borderWidth = 1.f;
    self.layer.borderColor = [UIColor clearColor].CGColor;
    
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];

    if (profile.state == kWFAVEngineStateIncomming
        || profile.state == kWFAVEngineStateOutgoing
        || profile.state == kWFAVEngineStateConnecting) {
        [self.stateLabel start];
        self.stateLabel.hidden = NO;
    } else {
        [self.stateLabel stop];
        if (profile.videoMuted || profile.audience) {
            self.stateLabel.hidden = NO;
            self.stateLabel.image = [UIImage imageNamed:@"disable_video"];
        } else {
            self.stateLabel.hidden = YES;
        }
    }

    self.conferenceLabelView.name = userInfo.displayName;
    
    BOOL isVideoMuted = YES;
    BOOL isAudioMuted = YES;
    if(!profile.audience) {
        isVideoMuted = profile.videoMuted;
        isAudioMuted = profile.audioMuted;
    }
    self.conferenceLabelView.isMuteVideo = isVideoMuted;
    self.conferenceLabelView.isMuteAudio = isAudioMuted;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVolumeUpdated:) name:@"wfavVolumeUpdated" object:nil];
    
}

- (void)addSubview:(UIView *)view {
    [super addSubview:view];
    [self bringSubviewToFront:self.conferenceLabelView];
}

- (void)onVolumeUpdated:(NSNotification *)notification {
    if([notification.object isEqual:self.userId]) {
        NSInteger volume = [notification.userInfo[@"volume"] integerValue];
        if (volume > 1000) {
            self.layer.borderColor = [UIColor greenColor].CGColor;
        } else {
            self.layer.borderColor = [UIColor clearColor].CGColor;
        }
        self.conferenceLabelView.volume = volume;
    }
}

- (ConferenceLabelView *)conferenceLabelView {
    if(!_conferenceLabelView) {
        CGSize size = [ConferenceLabelView sizeOffView];
        _conferenceLabelView = [[ConferenceLabelView alloc] initWithFrame:CGRectMake(4, self.bounds.size.height - size.height - 4, size.width, size.height)];
        [self addSubview:_conferenceLabelView];
    }
    return _conferenceLabelView;
}

- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:self.bounds];

        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 2.f;
        [self addSubview:_portraitView];
    }
    return _portraitView;
}

- (WFCUWaitingAnimationView *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[WFCUWaitingAnimationView alloc] initWithFrame:self.bounds];

        _stateLabel.animationImages = @[[UIImage imageNamed:@"connect_ani1"],[UIImage imageNamed:@"connect_ani2"],[UIImage imageNamed:@"connect_ani3"]];
        _stateLabel.animationDuration = 1;
        _stateLabel.animationRepeatCount = 200;
        _stateLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        _stateLabel.hidden = YES;
        [self addSubview:_stateLabel];
    }
    return _stateLabel;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
