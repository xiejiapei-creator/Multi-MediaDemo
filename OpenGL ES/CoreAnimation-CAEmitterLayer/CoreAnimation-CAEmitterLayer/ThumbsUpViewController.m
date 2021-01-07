//
//  ThumbsUpViewController.m
//  CoreAnimation-CAEmitterLayer
//
//  Created by 谢佳培 on 2021/1/7.
//

#import "ThumbsUpViewController.h"

@interface ThumbsUpViewController ()

@property(nonatomic,strong)CAEmitterLayer *explosionLayer;

@end

@implementation ThumbsUpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createLikeButton];
}

- (void)createLikeButton
{
    LikeButton *likeButton = [LikeButton buttonWithType:UIButtonTypeCustom];
    likeButton.frame = CGRectMake(200, 500, 30, 130);
    [self.view addSubview:likeButton];
    [likeButton setImage:[UIImage imageNamed:@"dislike"] forState:UIControlStateNormal];
    [likeButton setImage:[UIImage imageNamed:@"like_orange"] forState:UIControlStateSelected];
    [likeButton addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)btnClick:(UIButton *)button
{
    if (!button.selected)// 点赞
    {
        button.selected = !button.selected;
        NSLog(@"点赞");
    }
    else// 取消点赞
    {
        button.selected = !button.selected;
        NSLog(@"取消点赞");
    }
}

@end

#pragma mark - 点赞按钮

@interface LikeButton()

@property(nonatomic,strong)CAEmitterLayer *explosionLayer;

@end

@implementation LikeButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupExplosion];
    }
    return self;
}

-(void)layoutSubviews
{
    // 发射源位置
    self.explosionLayer.position = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    
    [super layoutSubviews];
}

// 设置粒子效果
- (void)setupExplosion
{
    CAEmitterLayer * explosionLayer = [CAEmitterLayer layer];
    [self.layer addSublayer:explosionLayer];
    self.explosionLayer = explosionLayer;
    
    // 发射器尺寸大小
    self.explosionLayer.emitterSize = CGSizeMake(self.bounds.size.width + 40, self.bounds.size.height + 40);
    // 表示粒子从圆形形状发射出来
    explosionLayer.emitterShape = kCAEmitterLayerCircle;
    // 发射模型为轮廓模式表示从形状的边界上发射粒子
    explosionLayer.emitterMode = kCAEmitterLayerOutline;
    // 渲染模式
    explosionLayer.renderMode = kCAEmitterLayerOldestFirst;
    
    
    CAEmitterCell * explosionCell = [CAEmitterCell emitterCell];
    explosionCell.name = @"explosionCell";
    
    // 透明值变化速度
    explosionCell.alphaSpeed = -1.f;
    // 透明值范围
    explosionCell.alphaRange = 0.10;
    // 生命周期
    explosionCell.lifetime = 1;
    // 生命周期范围
    explosionCell.lifetimeRange = 0.1;
    // 粒子速度
    explosionCell.velocity = 40.f;
    // 粒子速度范围
    explosionCell.velocityRange = 10.f;
    // 缩放比例
    explosionCell.scale = 0.08;
    // 缩放比例范围
    explosionCell.scaleRange = 0.02;
    // 粒子图片
    explosionCell.contents = (id)[[UIImage imageNamed:@"spark_red"] CGImage];
    
    explosionLayer.emitterCells = @[explosionCell];
}

// 通过判断选中状态实现缩放和爆炸效果
- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    // 通过关键帧动画实现缩放
    CAKeyframeAnimation * animation = [CAKeyframeAnimation animation];
    // 设置动画路径
    animation.keyPath = @"transform.scale";
    
    if (selected)
    {
        // 从没有点击到点击状态会有爆炸的动画效果
        animation.values = @[@1.5,@2.0, @0.8, @1.0];
        animation.duration = 0.5;
        // 计算关键帧方式
        animation.calculationMode = kCAAnimationCubic;
        // 为图层添加动画
        [self.layer addAnimation:animation forKey:nil];
        
        // 让放大动画先执行完毕，再执行爆炸动画
        [self performSelector:@selector(startAnimation) withObject:nil afterDelay:0.25];
    }
    else
    {
        // 从点击状态变为正常状态无动画效果
        // 如果点赞之后马上取消，那么也立马停止动画
        [self stopAnimation];
    }
}

// 开始动画
- (void)startAnimation
{
    // 用KVC设置颗粒个数为1000
    [self.explosionLayer setValue:@1000 forKeyPath:@"emitterCells.explosionCell.birthRate"];
    
    // 开始动画
    self.explosionLayer.beginTime = CACurrentMediaTime();
    
    // 延迟停止动画
    [self performSelector:@selector(stopAnimation) withObject:nil afterDelay:0.15];
}

// 动画结束
- (void)stopAnimation
{
    // 用KVC设置颗粒个数为0
    [self.explosionLayer setValue:@0 forKeyPath:@"emitterCells.explosionCell.birthRate"];
    
    // 移除动画
    [self.explosionLayer removeAllAnimations];
}


@end
