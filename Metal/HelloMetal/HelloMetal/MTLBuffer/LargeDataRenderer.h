//
//  LargeDataRenderer.h
//  HelloMetal
//
//  Created by 谢佳培 on 2021/1/10.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LargeDataRenderer : NSObject<MTKViewDelegate>

- (id)initWithMetalKitView:(MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
