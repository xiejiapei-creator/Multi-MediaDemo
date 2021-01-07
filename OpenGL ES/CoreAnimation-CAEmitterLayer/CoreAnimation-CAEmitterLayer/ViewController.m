//
//  ViewController.m
//  CoreAnimation-CAEmitterLayer
//
//  Created by 谢佳培 on 2021/1/7.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) CAEmitterLayer * colorBallLayer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self createTipLable];
    [self setupEmitter];
}

- (void)createTipLable
{
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 800, self.view.bounds.size.width, 50)];
    [self.view addSubview:label];
    label.textColor = [UIColor whiteColor];
    label.text = @"轻点或拖动来改变发射源位置";
    label.textAlignment = NSTextAlignmentCenter;
}

// 设置发射器和粒子参数
- (void)setupEmitter
{
    // 1.创建发射器
    CAEmitterLayer * colorBallLayer = [CAEmitterLayer layer];
    [self.view.layer addSublayer:colorBallLayer];
    self.colorBallLayer = colorBallLayer;
    
    // 2.设置发射器的参数
    // 发射源的尺寸大小
    colorBallLayer.emitterSize = self.view.frame.size;
    // 发射源的形状：点、线、矩形框、立体矩形框、圆形、立体圆形
    colorBallLayer.emitterShape = kCAEmitterLayerPoint;
    // 发射模式：点、轮廓边缘、表面
    colorBallLayer.emitterMode = kCAEmitterLayerPoints;
    // 粒子发射形状的中心点
    colorBallLayer.emitterPosition = CGPointMake(self.view.layer.bounds.size.width, 0.f);
    
    // 3.创建发射的粒子
    CAEmitterCell * colorBallCell = [CAEmitterCell emitterCell];
    // 粒子名称
    colorBallCell.name = @"colorBallCell";
    // 粒子产生率，默认为0
    colorBallCell.birthRate = 20.f;
    // 粒子生命周期
    colorBallCell.lifetime = 10.f;
    
    // 粒子速度，默认为0
    colorBallCell.velocity = 40.f;
    // 粒子速度平均量
    colorBallCell.velocityRange = 100.f;
    // x,y,z方向上的加速度分量，三者默认都是0
    colorBallCell.yAcceleration = 15.f;
    
    // 指定纬度，纬度角代表了在x-z轴平面坐标系中与x轴之间的夹角，默认0
    colorBallCell.emissionLongitude = M_PI; // 向左
    // 发射角度范围，默认0，以锥形分布开的发射角度。角度用弧度制。粒子均匀分布在这个锥形范围内
    colorBallCell.emissionRange = M_PI_4; // 围绕X轴向左90度
    
    // 缩放比例, 默认是1
    colorBallCell.scale = 0.2;
    // 缩放比例范围,默认是0
    colorBallCell.scaleRange = 0.1;
    // 在生命周期内的缩放速度,默认是0
    colorBallCell.scaleSpeed = 0.02;
    
    // 粒子的内容，为CGImageRef的对象
    colorBallCell.contents = (id)[[UIImage imageNamed:@"circle_white"] CGImage];
    // 颜色
    colorBallCell.color = [[UIColor colorWithRed:0.5 green:0.f blue:0.5 alpha:1.f] CGColor];
    // 粒子颜色red,green,blue,alpha能改变的范围,默认0
    colorBallCell.redRange = 1.f;
    colorBallCell.greenRange = 1.f;
    colorBallCell.alphaRange = 0.8;
    // 粒子颜色red,green,blue,alpha在生命周期内的改变速度,默认都是0
    colorBallCell.blueSpeed = 1.f;
    colorBallCell.alphaSpeed = -0.1f;
    
    // 添加粒子到图层
    colorBallLayer.emitterCells = @[colorBallCell];
}

#pragma mark - 手指控制粒子的发射位置

// 获取手指所在点的位置
- (CGPoint)locationFromTouchEvent:(UIEvent *)event
{
    UITouch * touch = [[event allTouches] anyObject];
    return [touch locationInView:self.view];
}

// 手指触摸到屏幕后将发射器移动到触摸位置
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [self locationFromTouchEvent:event];
    [self setBallInPsition:point];
}

// 手指移动过程中发射器位置随之移动
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [self locationFromTouchEvent:event];
    [self setBallInPsition:point];
}

// 移动发射源到某个点上
- (void)setBallInPsition:(CGPoint)position
{
    // 创建基础动画
    CABasicAnimation * anim = [CABasicAnimation animationWithKeyPath:@"emitterCells.colorBallCell.scale"];
    // fromValue
    anim.fromValue = @0.2f;
    // toValue
    anim.toValue = @0.5f;
    // duration
    anim.duration = 1.f;
    // 线性动画，使动画在其持续时间内均匀地发生
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    // 用事务包装隐式动画
    [CATransaction begin];
    // 设置是否禁止由于该事务组内的属性更改而触发的操作
    [CATransaction setDisableActions:YES];
    // 为colorBallLayer添加动画
    [self.colorBallLayer addAnimation:anim forKey:nil];
    // 为colorBallLayer指定位置添加动画效果
    [self.colorBallLayer setValue:[NSValue valueWithCGPoint:position] forKeyPath:@"emitterPosition"];
    // 提交动画
    [CATransaction commit];
}

@end
