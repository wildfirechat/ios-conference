//
//  WFCUPortraitCollectionViewCell.m
//  WFChatUIKit
//
//  Created by dali on 2020/1/20.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUPortraitCollectionViewCell.h"
#import <SDWebImage/SDWebImage.h>
#import "ConferenceLabelView.h"

@interface WFCUPortraitCollectionViewCell ()
@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)UILabel *nameLabel;
@property (nonatomic, strong)UIImageView *stateLabel;
@property (nonatomic, strong)ConferenceLabelView *conferenceLabelView;
@end

@implementation WFCUPortraitCollectionViewCell

- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
    self.layer.borderWidth = 1.f;
    self.layer.borderColor = [UIColor clearColor].CGColor;
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    self.nameLabel.text = userInfo.displayName;
    self.conferenceLabelView.name = userInfo.displayName;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVolumeUpdated:) name:@"wfavVolumeUpdated" object:nil];
    
}

- (void)onVolumeUpdated:(NSNotification *)notification {
    if([notification.object isEqual:self.userInfo.userId]) {
        NSInteger volume = [notification.userInfo[@"volume"] integerValue];
        if (volume > 1000) {
            self.layer.borderColor = [UIColor greenColor].CGColor;
        } else {
            self.layer.borderColor = [UIColor clearColor].CGColor;
        }
        self.conferenceLabelView.volume = volume;
    }
}

-(void)setProfile:(WFAVParticipantProfile *)profile {
    _profile = profile;
    if (profile.state == kWFAVEngineStateConnected || profile.state == kWFAVEngineStateIdle) {
        [self.stateLabel stopAnimating];
        self.stateLabel.hidden = YES;
    } else {
        [self.stateLabel startAnimating];
        self.stateLabel.hidden = NO;
    }
    BOOL isVideoMuted = YES;
    BOOL isAudioMuted = YES;
    if(!profile.audience) {
        isVideoMuted = profile.videoMuted;
        isAudioMuted = profile.audioMuted;
    }
    self.conferenceLabelView.isMuteVideo = isVideoMuted;
    self.conferenceLabelView.isMuteAudio = isAudioMuted;
}

- (void)addSubview:(UIView *)view {
    [super addSubview:view];
    [self bringSubviewToFront:self.conferenceLabelView];
}

- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.itemSize, self.itemSize)];

        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 2.f;
        [self addSubview:_portraitView];
    }
    return _portraitView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.itemSize, self.itemSize, self.labelSize)];
        _nameLabel.font = [UIFont systemFontOfSize:self.labelSize - 4];
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (UIImageView *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.itemSize, self.itemSize)];
        
        _stateLabel.animationImages = @[[UIImage imageNamed:@"connect_ani1"],[UIImage imageNamed:@"connect_ani2"],[UIImage imageNamed:@"connect_ani3"]];
        _stateLabel.animationDuration = 1.f;
        _stateLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        [self addSubview:_stateLabel];
    }
    return _stateLabel;
}

- (ConferenceLabelView *)conferenceLabelView {
    if(!_conferenceLabelView) {
        CGSize size = [ConferenceLabelView sizeOffView];
        _conferenceLabelView = [[ConferenceLabelView alloc] initWithFrame:CGRectMake(4, self.bounds.size.height - size.height - 4, size.width, size.height)];
        [self addSubview:_conferenceLabelView];
    }
    return _conferenceLabelView;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
