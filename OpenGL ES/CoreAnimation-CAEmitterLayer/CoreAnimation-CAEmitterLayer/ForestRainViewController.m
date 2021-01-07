//
//  ForestRainViewController.m
//  CoreAnimation-CAEmitterLayer
//
//  Created by 谢佳培 on 2021/1/7.
//

#import "ForestRainViewController.h"

@interface ForestRainViewController ()

@property (nonatomic, strong) CAEmitterLayer * rainLayer;
@property (nonatomic, weak) UIImageView * imageView;

@end

@implementation ForestRainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createSubviews];
    [self setupEmitter];
}

- (void)setupEmitter
{
    CAEmitterLayer * rainLayer = [CAEmitterLayer layer];
    // 在背景图上添加粒子图层
    [self.imageView.layer addSublayer:rainLayer];
    self.rainLayer = rainLayer;
    
    // 发射形状为线
    rainLayer.emitterShape = kCAEmitterLayerLine;
    // 发射模式为表面
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    // 发射源大小为整个屏幕
    rainLayer.emitterSize = self.view.frame.size;
    // 发射源位置，y最好不要设置为0，而是<0，营造黄河之水天上来的效果
    rainLayer.emitterPosition = CGPointMake(self.view.bounds.size.width * 0.5, -10);

    CAEmitterCell * snowCell = [CAEmitterCell emitterCell];
    // 粒子内容为雨滴
    snowCell.contents = (id)[[UIImage imageNamed:@"rain_white"] CGImage];
    // 每秒产生的粒子数量的系数
    snowCell.birthRate = 25.f;
    // 粒子的生命周期
    snowCell.lifetime = 20.f;
    // speed粒子速度
    snowCell.speed = 10.f;
    // 粒子速度系数, 默认1.0
    snowCell.velocity = 10.f;
    // 每个发射物体的初始平均范围,默认等于0
    snowCell.velocityRange = 10.f;
    // 粒子在y方向是加速的
    snowCell.yAcceleration = 1000.f;
    // 粒子缩放比例
    snowCell.scale = 0.1;
    // 粒子缩放比例范围
    snowCell.scaleRange = 0.f;
    
    // 将雨滴添加到图层上
    rainLayer.emitterCells = @[snowCell];
}

#pragma mark - 控制天气

- (void)buttonClick:(UIButton *)sender
{
    if (!sender.selected)// 停止下雨
    {
        sender.selected = !sender.selected;
        [self.rainLayer setValue:@0.f forKeyPath:@"birthRate"];
    }
    else// 开始下雨
    {
        sender.selected = !sender.selected;
        [self.rainLayer setValue:@1.f forKeyPath:@"birthRate"];
    }
}


- (void)rainButtonClick:(UIButton *)sender
{
    NSInteger rate = 1;
    CGFloat scale = 0.05;
    
    if (sender.tag == 100)
    {
        NSLog(@"暴雨⛈️");
        
        if (self.rainLayer.birthRate < 30)
        {
            // birthRate变为2，scale变为1.05
            [self.rainLayer setValue:@(self.rainLayer.birthRate + rate) forKeyPath:@"birthRate"];
            [self.rainLayer setValue:@(self.rainLayer.scale + scale) forKeyPath:@"scale"];
        }
    }
    else if (sender.tag == 200)
    {
        NSLog(@"小雨");
        
        if (self.rainLayer.birthRate > 1)
        {
            // birthRate恢复为1，scale恢复为1
            [self.rainLayer setValue:@(self.rainLayer.birthRate - rate) forKeyPath:@"birthRate"];
            [self.rainLayer setValue:@(self.rainLayer.scale - scale) forKeyPath:@"scale"];
        }
    }
}

- (void)createSubviews
{
    // 背景图片
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:imageView];
    self.imageView = imageView;
    imageView.image = [UIImage imageNamed:@"forest"];
    
    // 下雨按钮
    UIButton * startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:startBtn];
    startBtn.frame = CGRectMake(50, self.view.bounds.size.height - 100, 80, 40);
    startBtn.backgroundColor = [UIColor whiteColor];
    [startBtn setTitle:@"停止下雨" forState:UIControlStateNormal];
    [startBtn setTitle:@"下雨" forState:UIControlStateSelected];
    [startBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [startBtn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    [startBtn addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    // 雨量按钮
    UIButton * rainBIgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:rainBIgBtn];
    rainBIgBtn.tag = 100;
    rainBIgBtn.frame = CGRectMake(180, self.view.bounds.size.height - 100, 80, 40);
    rainBIgBtn.backgroundColor = [UIColor whiteColor];
    [rainBIgBtn setTitle:@"下暴雨" forState:UIControlStateNormal];
    [rainBIgBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [rainBIgBtn addTarget:self action:@selector(rainButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton * rainSmallBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:rainSmallBtn];
    rainSmallBtn.tag = 200;
    rainSmallBtn.frame = CGRectMake(320, self.view.bounds.size.height - 100, 80, 40);
    rainSmallBtn.backgroundColor = [UIColor whiteColor];
    [rainSmallBtn setTitle:@"下小雨" forState:UIControlStateNormal];
    [rainSmallBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [rainSmallBtn addTarget:self action:@selector(rainButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

@end
