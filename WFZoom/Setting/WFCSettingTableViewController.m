//
//  SettingTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/6.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCSettingTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "WFCSecurityTableViewController.h"
#import "WFCAboutViewController.h"
#import "WFCPrivacyViewController.h"
#import "WFCPrivacyTableViewController.h"
#import "WFCDiagnoseViewController.h"
#import "MBProgressHUD.h"
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "AppService.h"
#import "WFCMeTableViewHeaderViewCell.h"
#import "WFCUConfigManager.h"
#import "WFCUMyProfileTableViewController.h"
#import "AppService.h"

@interface WFCSettingTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@end

@implementation WFCSettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.title = @"设置";
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0.1)];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];
}

- (void)onLeftBarBtn:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)contactUs:(BOOL)isComplain {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:isComplain ? @"投诉":@"建议" message:@"请输入内容，我们收到后回尽快联系您！" preferredStyle:UIAlertControllerStyleAlert];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"请输入内容";
    }];
    

    __weak typeof(self)ws = self;
    [alertController addAction:[UIAlertAction actionWithTitle:@"提交" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSString *content = alertController.textFields.firstObject.text;
        __block MBProgressHUD *hud = [ws startProgress:@"提交中"];
        [[AppService sharedAppService] complain:content success:^{
            [ws stopProgress:hud finishText:@"提交成功"];
        } error:^(int code, NSString * _Nonnull errorMsg) {
            [ws stopProgress:hud finishText:@"提交失败！请重试！"];
        }];
        
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:true completion:nil];
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


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        return 96;
    }
    return 48;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        WFCUMyProfileTableViewController *vc = [[WFCUMyProfileTableViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            [self contactUs:NO];
        } else if (indexPath.row == 2) {
            WFCAboutViewController *avc = [[WFCAboutViewController alloc] init];
            [self.navigationController pushViewController:avc animated:YES];
        }
    } else if(indexPath.section == 2) {
        if (indexPath.row == 0) {
            WFCPrivacyViewController * pvc = [[WFCPrivacyViewController alloc] init];
            pvc.isPrivacy = NO;
            [self.navigationController pushViewController:pvc animated:YES];
        } else if(indexPath.row == 1) {
            WFCPrivacyViewController * pvc = [[WFCPrivacyViewController alloc] init];
            pvc.isPrivacy = YES;
            [self.navigationController pushViewController:pvc animated:YES];
        }
    } else if(indexPath.section == 3) {
        [self contactUs:YES];
    } else if (indexPath.section == 4) {
        WFCDiagnoseViewController *vc = [[WFCDiagnoseViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0.01;
    } else {
        return 9;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    } else {
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 9)];
        v.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        return v;
    }

}

//#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 3; //
    } else if (section == 2) {
        return 2; // 用户协议和隐私声明
    } else if (section == 3) {
        return 1; //举报
    } else if (section == 4) {
        return 1; //diagnose
    } else if (section == 5) {
        return 1; //logout
    }
    return 0;
}


- (UIEdgeInsets)hiddenSeparatorLine:(UITableViewCell *)cell {
    return cell.separatorInset = UIEdgeInsetsMake(self.view.frame.size.width, 0, 0, 0);
}

- (void)showSeparatorLine:(UITableViewCell *)cell {
    cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)setLastCellSeperatorToLeft:(UITableViewCell*) cell
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }

    if([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]){
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        WFCMeTableViewHeaderViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"profileCell"];
        if (cell == nil) {
            cell = [[WFCMeTableViewHeaderViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"profileCell"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        WFCCUserInfo *me = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:YES];
        cell.userInfo = me;
        return cell;
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"style1Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"style1Cell"];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    
    if(indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self showSeparatorLine:cell];
            cell.textLabel.text = @"当前版本";
            cell.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } if (indexPath.row == 1) {
            cell.textLabel.text = @"帮助与反馈";
            [self showSeparatorLine:cell];
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"关于野火会议";
            [self hiddenSeparatorLine:cell];
        }
    } else if(indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"用户协议";
            [self showSeparatorLine:cell];

        } if (indexPath.row == 1) {
            cell.textLabel.text = @"隐私政策";
            [self hiddenSeparatorLine:cell];
        }
    } else if(indexPath.section == 3) {
        if (indexPath.row == 0) {
            [self hiddenSeparatorLine:cell];
            cell.textLabel.text = @"投诉";
        }
    } else if (indexPath.section == 4) {
        [self hiddenSeparatorLine:cell];
        cell.textLabel.text = @"诊断";
    } else if (indexPath.section == 5) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"buttonCell"];
        for (UIView *subView in cell.subviews) {
            [subView removeFromSuperview];
        }
       [self setLastCellSeperatorToLeft:cell];
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
        [btn setTitle:@"退出登录" forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
        [btn setTitleColor:[UIColor colorWithHexString:@"0xf95569"]
                  forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(onLogoutBtn:) forControlEvents:UIControlEventTouchUpInside];
        if (@available(iOS 14, *)) {
            [cell.contentView addSubview:btn];
        } else {
            [cell addSubview:btn];
        }
    }
    
    return cell;
}
 
- (void)onLogoutBtn:(id)sender {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
    [[AppService sharedAppService] clearAppServiceAuthInfos];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //退出后就不需要推送了，第一个参数为YES
    //如果希望再次登录时能够保留历史记录，第二个参数为NO。如果需要清除掉本地历史记录第二个参数用YES
    [[WFCCNetworkService sharedInstance] disconnect:YES clearSession:NO];
}
@end
