//
//  AssetReader.h
//  Camera
//
//  Created by 谢佳培 on 2021/1/12.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssetReader : NSObject

// 初始化
- (instancetype)initWithUrl:(NSURL *)url;

// 从mov文件读取CMSampleBufferRef数据
- (CMSampleBufferRef)readBuffer;

@end

NS_ASSUME_NONNULL_END
