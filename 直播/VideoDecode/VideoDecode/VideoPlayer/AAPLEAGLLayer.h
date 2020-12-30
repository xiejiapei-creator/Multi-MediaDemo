//
//  AAPLEAGLLayer.h
//  VideoDecode
//
//  Created by 谢佳培 on 2020/12/29.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

// CAEAGLLayer 是专门用来渲染OpenGL ES的图层，继承自CALayer
// OpenGL ES只负责渲染，不关心图层，所以支持跨平台
@interface AAPLEAGLLayer : CAEAGLLayer

// 用于渲染的解码后的数据
@property CVPixelBufferRef pixelBuffer;

// 展示的图层尺寸
- (id)initWithFrame:(CGRect)frame;

// 重新渲染
- (void)resetRenderBuffer;

@end

NS_ASSUME_NONNULL_END
