//
//  View.h
//  GLSL金字塔
//
//  Created by 谢佳培 on 2021/1/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface View : UIView

@property(nonatomic, assign)BOOL bX;
@property(nonatomic, assign)BOOL bY;
@property(nonatomic, assign)BOOL bZ;

- (void)reDegree;

@end

NS_ASSUME_NONNULL_END
