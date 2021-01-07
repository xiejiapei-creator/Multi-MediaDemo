//
//  PointParticleEffect.h
//  OpenGL粒子系统
//
//  Created by 谢佳培 on 2021/1/7.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

// 默认重力加速度矢量与地球的
extern const GLKVector3 DefaultGravity;

// 管理并且绘制所有的粒子
// 参数包括初始速度、受力、大小、持续时间、渐隐时间
// 粒子会根据生命周期进行复用
@interface PointParticleEffect : NSObject

//重力
@property(nonatomic,assign)GLKVector3 gravity;

//耗时
@property(nonatomic,assign)GLfloat elapsedSeconds;

//纹理
@property (strong, nonatomic, readonly)GLKEffectPropertyTexture *texture2d0;

//变换
@property (strong, nonatomic, readonly) GLKEffectPropertyTransform *transform;


//添加粒子
/*
 aPosition:位置
 aVelocity:速度
 aForce:重力
 aSize:大小
 aSpan:跨度
 aDuration:时长
 */
- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        force:(GLKVector3)aForce
                         size:(float)aSize
              lifeSpanSeconds:(NSTimeInterval)aSpan
          fadeDurationSeconds:(NSTimeInterval)aDuration;

//准备绘制
- (void)prepareToDraw;

//绘制
- (void)draw;

@end
