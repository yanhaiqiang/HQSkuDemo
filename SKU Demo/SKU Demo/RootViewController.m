//
//  RootViewController.m
//  SKU Demo
//
//  Created by yifo on 2018/7/6.
//  Copyright © 2018年 yanhaiqiang. All rights reserved.
//

#import "RootViewController.h"
#import "ViewController.h"
#import "XWDrawerAnimator.h"
#import "UIViewController+XWTransition.h"

#define KScreenWidth [[UIScreen mainScreen]bounds].size.width
#define KScreenHeight [[UIScreen mainScreen]bounds].size.height
@interface RootViewController ()
@property (nonatomic, strong) NSDictionary *skuResult;
@property (nonatomic, strong) UILabel *chooselabel;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 100, 100, 50);
    [btn setTitle:@"选择商品" forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor grayColor];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(jumpSKU:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *chooseLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 200, self.view.frame.size.width - 40, 50)];
    chooseLabel.font = [UIFont systemFontOfSize:14];
    chooseLabel.numberOfLines = 0;
    self.chooselabel = chooseLabel;
    [self.view addSubview:chooseLabel];
    
    //读取数据
    [self readDataSource];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"goods_proprety_noti" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSArray *selectArray = note.userInfo[@"Array"];
        NSString *attString = [selectArray componentsJoinedByString:@" "];
        NSString *str = [NSString stringWithFormat:@"已选：%@",attString];
        chooseLabel.text = str;
    }];
}

///读取数据
- (void)readDataSource{
    NSString * path = [[NSBundle mainBundle]pathForResource:@"dataSource" ofType:@"txt"];
    NSString * string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSData * data = [string dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    self.skuResult = obj[@"result"];
}


- (void)jumpSKU:(UIButton *)button {
    ViewController *viewController = [[ViewController alloc] initWithDic:self.skuResult];
    UIWindow *widow = [UIApplication sharedApplication].keyWindow;
    widow.backgroundColor = [UIColor blackColor];
    [self setUpAlterViewControllerWith:viewController WithDistance:KScreenHeight * 0.8 WithDirection:XWDrawerAnimatorDirectionBottom WithParallaxEnable:NO WithFlipEnable:YES];
}
#pragma mark - 转场动画弹出控制器
- (void)setUpAlterViewControllerWith:(UIViewController *)vc WithDistance:(CGFloat)distance WithDirection:(XWDrawerAnimatorDirection)vcDirection WithParallaxEnable:(BOOL)parallaxEnable WithFlipEnable:(BOOL)flipEnable {
    [self dismissViewControllerAnimated:YES completion:nil]; //以防有控制未退出
    XWDrawerAnimatorDirection direction = vcDirection;
    XWDrawerAnimator *animator = [XWDrawerAnimator xw_animatorWithDirection:direction moveDistance:distance];
    animator.parallaxEnable = parallaxEnable;
    animator.flipEnable = flipEnable;
    animator.toDuration = 0.5;
    animator.backDuration = 0.5;
    animator.needInteractiveTimer = YES;
    [self xw_presentViewController:vc withAnimator:animator];
    __weak typeof(self)weakSelf = self;
    [animator xw_enableEdgeGestureAndBackTapWithConfig:^{
        [weakSelf selfAlterViewback];
    }];
    
}
#pragma 退出界面
- (void)selfAlterViewback {
    [self dismissViewControllerAnimated:YES completion:^{
        UIWindow *widow = [UIApplication sharedApplication].keyWindow;
        widow.backgroundColor = [UIColor whiteColor];
    }];
}

@end
