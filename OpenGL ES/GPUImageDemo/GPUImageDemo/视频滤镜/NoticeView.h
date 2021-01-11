//
//  NoticeView.h
//  GPUImageDemo
//
//  Created by 谢佳培 on 2021/1/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NoticeView : UIView

/** 提示框
 *  message: 要显示的文字信息
 *  second: 显示文字的时间
 */
+ (instancetype)message:(NSString *)message delaySecond:(CGFloat)second;

@end

NS_ASSUME_NONNULL_END
