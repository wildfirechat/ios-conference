//
//  ConferenceLabelView.m
//  WFZoom
//
//  Created by Tom Lee on 2021/9/22.
//

#import "ConferenceLabelView.h"
#import "WFCUUtilities.h"


@interface ConferenceLabelView ()
@property(nonatomic, strong)UIImageView *audioView;
@property(nonatomic, strong)UILabel *nameLabel;
@end

@implementation ConferenceLabelView

//size 100*28
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
    }
    return self;
}

- (void)setIsMuteAudio:(BOOL)isMuteAudio {
    _isMuteAudio = isMuteAudio;
    if(isMuteAudio) {
        self.audioView.image = [UIImage imageNamed:@"mic_mute"];
    } else {
        self.volume = _volume;
    }
}

- (void)setVolume:(NSInteger)volume {
    _volume = volume;
    if(self.isMuteAudio)
        return;
    
    int v = (int)(volume/1000);
    if(v < 0) {
        v = 0;
    }
    if(v > 10) {
        v = 10;
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.audioView.image = [UIImage imageNamed:[NSString stringWithFormat:@"mic_%d", v]];
    }];
}

- (void)setName:(NSString *)name {
    _name = name;
    self.nameLabel.text = name;
    CGSize size = [WFCUUtilities getTextDrawingSize:name font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(1000, 20)];
    NSLog(@"size is %d", size.width);
    CGRect frame = self.nameLabel.frame;
    frame.size.width = size.width;
    self.nameLabel.frame = frame;
    frame = self.frame;
    frame.size.width = 28 + size.width + 8;
    self.frame = frame;
}

- (UIImageView *)audioView {
    if (!_audioView) {
        _audioView = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 20, 20)];
        [self addSubview:_audioView];
    }
    return _audioView;
}

- (UILabel *)nameLabel {
    if(!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(28, 4, 48, 20)];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        [self addSubview:_nameLabel];
    }
    return _nameLabel;
}
+ (CGSize)sizeOffView {
    return CGSizeMake(100, 28);
}
@end
