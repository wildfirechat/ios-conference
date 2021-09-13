//
//  JoinConferenceViewController.m
//  WFZoom
//
//  Created by WF Chat on 2021/9/3.
//  Copyright © 2021年 WildFireChat. All rights reserved.
//

#import "WFZConferenceInfoViewController.h"
#import "WFCUGeneralSwitchTableViewCell.h"
#import "WFCUConferenceViewController.h"
#import "WFCUConferenceManager.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUGeneralModifyViewController.h"
#import "CreateBarCodeViewController.h"
#import "UIView+Toast.h"
#import "MBProgressHUD.h"
#import "AppService.h"
#import "WFZConferenceInfo.h"

@interface WFZConferenceInfoViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;

@property(nonatomic, assign)BOOL enableAudio;
@property(nonatomic, assign)BOOL enableVideo;

@property(nonatomic, strong)WFZConferenceInfo *conferenceInfo;

@property(nonatomic, strong)UIButton *joinBtn;

@property(nonatomic, strong)NSTimer *checkTimer;

@property(nonatomic, assign)BOOL isFavConference;
@end

@implementation WFZConferenceInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.enableAudio = YES;
    self.enableVideo = NO;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];

    [self.tableView reloadData];
    
    __weak typeof(self)ws = self;
    __block MBProgressHUD *hud = [self startProgress:@"加载中"];
    [[AppService sharedAppService] queryConferenceInfo:self.conferenceId password:self.password success:^(WFZConferenceInfo * _Nonnull conferenceInfo) {
        ws.conferenceInfo = conferenceInfo;
        [ws stopProgress:hud finishText:nil];
    } error:^(int errorCode, NSString * _Nonnull message) {
        [ws stopProgress:hud finishText:@"会议不存在或者密码错误"];
        [ws.navigationController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [[AppService sharedAppService] isFavConference:self.conferenceId success:^(BOOL isFav) {
        ws.isFavConference = isFav;
    } error:^(int errorCode, NSString * _Nonnull message) {
        ws.isFavConference = NO;
    }];
    
    
    self.checkTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkConferenceStatus) userInfo:nil repeats:YES];
}

- (void)stopCheckTimer {
    [self.checkTimer invalidate];
    self.checkTimer = nil;
}

- (void)setConferenceInfo:(WFZConferenceInfo *)conferenceInfo {
    _conferenceInfo = conferenceInfo;
    [self.tableView reloadData];
    if([conferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"销毁" style:UIBarButtonItemStyleDone target:self action:@selector(onDestroyBtn:)];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor redColor];
    } else {
        self.isFavConference = _isFavConference;
    }
}

- (void)onDestroyBtn:(id)sender {
    __weak typeof(self)ws = self;
    __block MBProgressHUD *hud = [self startProgress:@"销毁会议中"];
    [[AppService sharedAppService] destroyConference:self.conferenceId success:^{
        [ws stopProgress:hud finishText:@"销毁会议成功"];
        [ws.navigationController dismissViewControllerAnimated:YES completion:nil];
    } error:^(int errorCode, NSString * _Nonnull message) {
        [ws stopProgress:hud finishText:@"销毁会议失败"];
    }];
}

- (void)onDeleteBtn:(id)sender {
    __weak typeof(self)ws = self;
    __block MBProgressHUD *hud = [self startProgress:@"删除中"];
    [[AppService sharedAppService] unfavConference:self.conferenceId success:^{
        [ws stopProgress:hud finishText:@"删除成功"];
        [ws.navigationController dismissViewControllerAnimated:YES completion:nil];
    } error:^(int errorCode, NSString * _Nonnull message) {
        [ws stopProgress:hud finishText:@"删除失败"];
    }];
}

- (void)onStartConference:(id)sender {
    UIButton *btn = (UIButton *)sender;
    btn.enabled = NO;
    
    
    if(!self.enableAudio && !self.enableVideo) {
        self.conferenceInfo.audience = YES;
    }
    WFCUConferenceViewController *vc = [[WFCUConferenceViewController alloc] initWithConferenceInfo:self.conferenceInfo muteAudio:!self.enableAudio muteVideo:!self.enableVideo];
    [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    });
}

- (void)onLeftBarBtn:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)onFav:(id)sender {
    __weak typeof(self)ws = self;
    __block MBProgressHUD *hud = [self startProgress:@"收藏中"];
    [[AppService sharedAppService] favConference:self.conferenceInfo.conferenceId success:^{
        [ws stopProgress:hud finishText:@"收藏成功"];
        ws.isFavConference = YES;
    } error:^(int errorCode, NSString * _Nonnull message) {
        [ws stopProgress:hud finishText:@"网络错误"];
    }];
}

- (void)displayMenu:(UITableViewCell *)cell {
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    UIMenuItem *copyConferenceIdItem = [[UIMenuItem alloc]initWithTitle:@"拷贝会议号" action:@selector(performCopyId:)];
    UIMenuItem *copyConferenceLinkItem = [[UIMenuItem alloc]initWithTitle:@"拷贝链接" action:@selector(performCopyLink:)];
    
    CGRect menuPos = cell.frame;
    
    [menu setTargetRect:menuPos inView:self.tableView];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    [items addObject:copyConferenceIdItem];
    [items addObject:copyConferenceLinkItem];
    
    [menu setMenuItems:items];
    [menu setMenuVisible:YES];
}

-(void)performCopyId:(UIMenuItem *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.conferenceInfo.conferenceId;
    [self.view makeToast:@"已拷贝到剪贴板！" duration:1 position:CSToastPositionCenter];
}

-(void)performCopyLink:(UIMenuItem *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [[WFCUConferenceManager sharedInstance] linkFromConferenceId:self.conferenceInfo.conferenceId password:self.conferenceInfo.password];
    [self.view makeToast:@"已拷贝到剪贴板！" duration:1 position:CSToastPositionCenter];
}


-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(performCopyId:) || action == @selector(performCopyLink:)) {
        return YES;
    } else {
        return [super canPerformAction:action withSender:sender];
    }
}

- (void)setIsFavConference:(BOOL)isFavConference {
    _isFavConference = isFavConference;
    if([self.conferenceInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        return;
    }
    
    if(isFavConference) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"删除" style:UIBarButtonItemStyleDone target:self action:@selector(onDeleteBtn:)];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor redColor];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"收藏" style:UIBarButtonItemStyleDone target:self action:@selector(onFav:)];
    }
}

- (MBProgressHUD *)startProgress:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = text;
    [hud showAnimated:YES];
    return hud;
}

- (MBProgressHUD *)stopProgress:(MBProgressHUD *)hud finishText:(NSString *)text {
    [hud hideAnimated:YES];
    if(text) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = text;
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    }
    return hud;
}

- (void)checkConferenceStatus {
    if(self.conferenceInfo) {
        self.joinBtn.enabled = YES;
        long long now = [[[NSDate alloc] init] timeIntervalSince1970];
        if(now > self.conferenceInfo.endTime) {
            self.joinBtn.enabled = NO;
            [self.joinBtn setTitle:@"会议已结束" forState:UIControlStateNormal];
            [self stopCheckTimer];
        } else if(self.conferenceInfo.startTime == 0 || self.conferenceInfo.startTime <= now) {
            [self.joinBtn setTitle:@"加入会议" forState:UIControlStateNormal];
        } else if(self.conferenceInfo.startTime > 0 && self.conferenceInfo.startTime - 180 <= now) {
            [self.joinBtn setTitle:[NSString stringWithFormat:@"加入会议(%lld秒后正式开始)", now - self.conferenceInfo.startTime] forState:UIControlStateNormal];
        } else {
            [self.joinBtn setTitle:@"会议还未开始" forState:UIControlStateNormal];
            self.joinBtn.enabled = NO;
        }
    }
}

- (void)showConferenceQrCode {
    CreateBarCodeViewController *vc = [CreateBarCodeViewController new];
    vc.string = [[WFCUConferenceManager sharedInstance] linkFromConferenceId:self.conferenceInfo.conferenceId password:self.conferenceInfo.password];
    [self.navigationController pushViewController:vc animated:YES];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        UITableViewCell *titleCell = [tableView dequeueReusableCellWithIdentifier:@"title"];
        if (!titleCell) {
            titleCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"title"];
        }
        if(indexPath.row == 0) {
            titleCell.textLabel.text = @"会议主题";
            titleCell.detailTextLabel.text = self.conferenceInfo.conferenceTitle;
        } else if(indexPath.row == 1) {
            titleCell.textLabel.text = @"发起人";
            if([[WFCCNetworkService sharedInstance].userId isEqualToString:self.conferenceInfo.owner]) {
                titleCell.detailTextLabel.text = @"我";
            } else {
                WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.conferenceInfo.owner refresh:NO];
                titleCell.detailTextLabel.text = userInfo.displayName;
            }
        } else if(indexPath.row == 2) {
            titleCell.textLabel.text = @"会议号";
            titleCell.detailTextLabel.text = self.conferenceInfo.conferenceId;
        } else if(indexPath.row == 3) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"qrcell"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"二维码";

            UIImage *qrcode = [UIImage imageNamed:@"qrcode"];
            CGFloat width = [UIScreen mainScreen].bounds.size.width;
            UIImageView *qrview = [[UIImageView alloc] initWithFrame:CGRectMake(width - 56, 8, 24, 24)];
            qrview.image = qrcode;
            [cell addSubview:qrview];
            return cell;
        } else if(indexPath.row == 4) {
            titleCell.textLabel.text = @"入会密码";
            titleCell.detailTextLabel.text = self.conferenceInfo.password;
        }
        return titleCell;
    } else if(indexPath.section == 1) {
        UITableViewCell *timeCell = [tableView dequeueReusableCellWithIdentifier:@"time"];
        if (!timeCell) {
            timeCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"time"];
            timeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        if (indexPath.row == 0) {
            timeCell.textLabel.text = @"开始时间";
            if (self.conferenceInfo.startTime == 0) {
                timeCell.detailTextLabel.text = @"现在";
            } else {
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.conferenceInfo.startTime];
                timeCell.detailTextLabel.text = [date descriptionWithLocale:[NSLocale systemLocale]];
            }
        } else {
            timeCell.textLabel.text = @"结束时间";
            if (self.conferenceInfo.endTime == 0) {
                timeCell.detailTextLabel.text = @"无限制";
            } else {
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.conferenceInfo.endTime];
                timeCell.detailTextLabel.text = [date descriptionWithLocale:[NSLocale systemLocale]];
            }
        }
        
        return timeCell;
    } else if(indexPath.section == 2) {
        __weak typeof(self)ws = self;
        WFCUGeneralSwitchTableViewCell *switchCell = [[WFCUGeneralSwitchTableViewCell alloc] init];
        if(indexPath.row == 0) {
            switchCell.textLabel.text = @"开启音频";
            switchCell.on = self.enableAudio;
            switchCell.onSwitch = ^(BOOL value, int type, void (^handleBlock)(BOOL success)) {
                ws.enableAudio = value;
                handleBlock(YES);
            };
        } else {
            switchCell.textLabel.text = @"开启视频";
            switchCell.on = self.enableVideo;
            switchCell.onSwitch = ^(BOOL value, int type, void (^handleBlock)(BOOL success)) {
                ws.enableVideo = value;
                handleBlock(YES);
            };
        }
        return switchCell;
    } else {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        for (UIView *subView in cell.contentView.subviews) {
            [subView removeFromSuperview];
        }
        self.joinBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
        [self.joinBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        [self.joinBtn addTarget:self action:@selector(onStartConference:) forControlEvents:UIControlEventTouchUpInside];
        if (@available(iOS 14, *)) {
            [cell.contentView addSubview:self.joinBtn];
        } else {
            [cell addSubview:self.joinBtn];
        }
        [self checkConferenceStatus];
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return 0;
    }
    return 10;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(!self.conferenceInfo) {
        return 0;
    }
    
    return 4;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(!self.conferenceInfo) {
        return 0;
    }
    
    if(section == 0) {
        if(self.conferenceInfo.password.length) {
            return 5;
        } else {
            return 4;
        }
    } else if(section == 1) {
        return 2;
    } else if(section == 2){
        return 2;
    } else {
        return 1;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 2) {
        [self displayMenu:[tableView cellForRowAtIndexPath:indexPath]];
    } else if(indexPath.section == 0 && indexPath.row == 3) {
        [self showConferenceQrCode];
    }
}

-(void)dealloc {
    [self stopCheckTimer];
}
@end
