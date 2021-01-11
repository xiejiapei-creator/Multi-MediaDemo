//
//  NoticeView.m
//  GPUImageDemo
//
//  Created by 谢佳培 on 2021/1/9.
//

#import "NoticeView.h"
#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight  [UIScreen mainScreen].bounds.size.height

@implementation NoticeView

+ (instancetype)message:(NSString *)message delaySecond:(CGFloat)second
{
    NoticeView *_labelView = nil;
    if (_labelView == nil)
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        label.backgroundColor = [UIColor clearColor];
        label.text = message;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        
        CGFloat width = [label.text boundingRectWithSize:CGSizeMake(kScreenWidth/4*3-20, 33) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:label.font} context:nil].size.width;
        CGFloat height = [label.text boundingRectWithSize:CGSizeMake(width, FLT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:label.font} context:nil].size.height;
        [label setFrame:CGRectMake(10, 10, width, height)];
        
        _labelView = [[NoticeView alloc] initWithFrame:CGRectMake(kScreenWidth/2-width/2, kScreenHeight/2-height/2+10, width+20, height+20)];
        [_labelView addSubview:label];
        _labelView.backgroundColor = [UIColor blackColor];
        _labelView.alpha = 0.7;
        _labelView.layer.cornerRadius = 8;
        _labelView.clipsToBounds = YES;
    }
    [_labelView removeFromItsSuperView:_labelView second:second];
    return _labelView;
}

- (void)removeFromItsSuperView:(NoticeView *)labelView second:(CGFloat)second
{
    __weak typeof(labelView) weakSelf = labelView;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(second * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf removeFromSuperview];
    });
}

@end
