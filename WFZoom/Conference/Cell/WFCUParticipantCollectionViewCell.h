//
//  WFCUParticipantCollectionViewCell.h
//  WFChatUIKit
//
//  Created by dali on 2020/1/20.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>
#import <WFAVEngineKit/WFAVEngineKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUParticipantCollectionViewCell : UICollectionViewCell
- (void)setUserInfo:(WFCCUserInfo *)userInfo callProfile:(WFAVParticipantProfile *)profile;
@end

NS_ASSUME_NONNULL_END
