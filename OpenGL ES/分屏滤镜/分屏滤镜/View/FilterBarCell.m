//
//  FilterBarCell.m
//  分屏滤镜
//
//  Created by 谢佳培 on 2021/1/7.
//

#import "FilterBarCell.h"

@interface FilterBarCell ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation FilterBarCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.label = [[UILabel alloc] initWithFrame:self.bounds];
    self.label.frame = CGRectInset(self.label.frame, 10, 10);
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.font = [UIFont boldSystemFontOfSize:15];
    self.label.layer.masksToBounds = YES;
    self.label.layer.cornerRadius = 15;
    [self addSubview:self.label];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.label.text = title;
}

- (void)setIsSelect:(BOOL)isSelect
{
    _isSelect = isSelect;
    self.label.backgroundColor = isSelect ? [UIColor blackColor] : [UIColor clearColor];
    self.label.textColor = isSelect ? [UIColor whiteColor] : [UIColor blackColor];
}

@end
