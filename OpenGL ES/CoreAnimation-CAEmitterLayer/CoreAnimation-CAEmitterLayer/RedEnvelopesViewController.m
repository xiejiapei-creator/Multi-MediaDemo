//
//  RedEnvelopesViewController.m
//  CoreAnimation-CAEmitterLayer
//
//  Created by 谢佳培 on 2021/1/7.
//

#import "RedEnvelopesViewController.h"

@interface RedEnvelopesViewController ()

@property (nonatomic, strong) CAEmitterLayer * rainLayer;

@end

@implementation RedEnvelopesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpEmitter];
}

- (void)setUpEmitter
{
    CAEmitterLayer * rainLayer = [CAEmitterLayer layer];
    [self.view.layer addSublayer:rainLayer];
    self.rainLayer = rainLayer;
    
    rainLayer.emitterShape = kCAEmitterLayerLine;
    rainLayer.emitterMode = kCAEmitterLayerSurface;
    rainLayer.emitterSize = self.view.frame.size;
    rainLayer.emitterPosition = CGPointMake(self.view.bounds.size.width * 0.5, -10);
    
    // 金币雨
    CAEmitterCell * snowCell = [CAEmitterCell emitterCell];
    snowCell.contents = (id)[[UIImage imageNamed:@"jinbi.png"] CGImage];
    snowCell.birthRate = 1.0;
    snowCell.lifetime = 30;
    snowCell.speed = 2;
    snowCell.velocity = 10.f;
    snowCell.velocityRange = 10.f;
    snowCell.yAcceleration = 60;
    snowCell.scale = 0.1;
    snowCell.scaleRange = 0.f;
    
    // 红包雨
    CAEmitterCell * hongbaoCell = [CAEmitterCell emitterCell];
    hongbaoCell.contents = (id)[[UIImage imageNamed:@"hongbao.png"] CGImage];
    hongbaoCell.birthRate = 1.0;
    hongbaoCell.lifetime = 30;
    hongbaoCell.speed = 2;
    hongbaoCell.velocity = 10.f;
    hongbaoCell.velocityRange = 10.f;
    hongbaoCell.yAcceleration = 60;
    hongbaoCell.scale = 0.05;
    hongbaoCell.scaleRange = 0.f;
    
    // 粽子雨
    CAEmitterCell * zongziCell = [CAEmitterCell emitterCell];
    zongziCell.contents = (id)[[UIImage imageNamed:@"zongzi.jpg"] CGImage];
    zongziCell.birthRate = 1.0;
    zongziCell.lifetime = 30;
    zongziCell.speed = 2;
    zongziCell.velocity = 10.f;
    zongziCell.velocityRange = 10.f;
    zongziCell.yAcceleration = 60;
    zongziCell.scale = 0.05;
    zongziCell.scaleRange = 0.f;
    
    // 将金币、红包、粽子一起添加到图层上
    rainLayer.emitterCells = @[snowCell,hongbaoCell,zongziCell];
}

@end
