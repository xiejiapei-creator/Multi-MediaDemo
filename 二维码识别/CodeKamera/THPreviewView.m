
#import "THPreviewView.h"

@interface THPreviewView ()<THCodeDetectionDelegate>

@property(strong,nonatomic)NSMutableDictionary *codeLayers;//二维码图层

@end

@implementation THPreviewView

+ (Class)layerClass
{
    //目的让视图的备用层成为AVCaptureVideoPreviewLayer 实例
    return [AVCaptureVideoPreviewLayer class];//获的预览图层
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    //保存一组表示识别编码的几何信息图层。
    _codeLayers = [NSMutableDictionary dictionary];
    
    //设置图层的videoGravity 属性，保证宽高比在边界范围之内
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
}

- (AVCaptureSession*)session {

    return [[self previewLayer]session];
}

//重写setSession 方法，将AVCaptureSession 作为预览层的session 属性
- (void)setSession:(AVCaptureSession *)session {
    
    self.previewLayer.session = session;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {

    return (AVCaptureVideoPreviewLayer *)self.layer;
}

//元数据转换
- (void)didDetectCodes:(NSArray *)codes
{
    //保存转换完成的元数据对象
    NSArray *transformedCodes = [self transformedCodesFromCodes:codes];
    
    //从codeLayers字典中获得key，用来判断那个图层应该在方法尾部移除
    NSMutableArray *lostCodes = [self.codeLayers.allKeys mutableCopy];
    
    //遍历数组
    for (AVMetadataMachineReadableCodeObject *code in transformedCodes)
    {
        //获得code.stringValue
        NSString *stringValue = code.stringValue;
        
        if (stringValue)
        {
            [lostCodes removeObject:stringValue];
        }
        else
        {
            continue;
        }
        
        //根据当前的 stringValue 查找图层
        NSArray *layers = self.codeLayers[stringValue];
        
        //如果没有对应的类目
        if (!layers)
        {
            //新建图层 方、圆
            layers = @[[self makeBoundsLayer],[self makeCornersLayer]];
            
            //将图层以stringValue 为key 存入字典中
            self.codeLayers[stringValue] = layers;
            
            //在预览图层上添加 图层0、图层1
            [self.previewLayer addSublayer:layers[0]];
            [self.previewLayer addSublayer:layers[1]];
        }
        
        //创建一个和对象的bounds关联的UIBezierPath
        //画方框
        CAShapeLayer *boundsLayer = layers[0];
        boundsLayer.path = [self bezierPathForBounds:code.bounds].CGPath;
        
        //对于cornersLayer 构建一个CGPath
        CAShapeLayer *cornersLayer = layers[1];
        cornersLayer.path = [self bezierPathForCorners:code.corners].CGPath;
    }
    
    //遍历lostCodes
    for (NSString *stringValue in lostCodes)
    {
        //将里面的条目图层从 previewLayer 中移除
        for (CALayer *layer in self.codeLayers[stringValue])
        {
            [layer removeFromSuperlayer];
        }
        
        //数组条目中也要移除
        [self.codeLayers removeObjectForKey:stringValue];
    }
    
}



// 将设备坐标空间元数据对象转换为视图坐标空间对象
- (NSArray *)transformedCodesFromCodes:(NSArray *)codes
{
    NSMutableArray *transformedCodes = [NSMutableArray array];
    
    //遍历数组
    for (AVMetadataObject *code in codes)
    {
        //将设备坐标空间元数据对象转换为视图坐标空间对象
        AVMetadataObject *transformedCode = [self.previewLayer transformedMetadataObjectForMetadataObject:code];
        
        //将转换好的数据添加到数组中
        [transformedCodes addObject:transformedCode];
        
    }
    
    //返回已经处理好的数据
    return transformedCodes;
}

- (UIBezierPath *)bezierPathForBounds:(CGRect)bounds {

    //绘制一个方框
    return [UIBezierPath bezierPathWithOvalInRect:bounds];
    
}

//CAShapeLayer 是CALayer 子类，用于绘制UIBezierPath  绘制boudns矩形
- (CAShapeLayer *)makeBoundsLayer {

    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.strokeColor = [[UIColor colorWithRed:0.95f green:0.75f blue:0.06f alpha:1.0f]CGColor];
    shapeLayer.fillColor = nil;
    shapeLayer.lineWidth = 4.0f;
    return shapeLayer;

}

//CAShapeLayer 是CALayer 子类，用于绘制UIBezierPath  绘制coners路径
- (CAShapeLayer *)makeCornersLayer {

    CAShapeLayer *cornerLayer = [CAShapeLayer layer];
    cornerLayer.lineWidth = 2.0f;
    cornerLayer.strokeColor  = [UIColor colorWithRed:0.172f green:0.671f blue:0.48f alpha:1.000f].CGColor;
    cornerLayer.fillColor = [UIColor colorWithRed:0.190f green:0.753f blue:0.489f alpha:0.5f].CGColor;
    
    return cornerLayer;
}

- (UIBezierPath *)bezierPathForCorners:(NSArray *)corners {
    //创建一个空的UIBezierPath
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    //遍历数组中的条目，为每个条目构建一个CGPoint
     for (int i = 0; i < corners.count; i++)
    {
        CGPoint point = [self pointForCorner:corners[i]];
        
        if (i == 0) {
            [path moveToPoint:point];
        }else
        {
            [path addLineToPoint:point];
        }
    }

    [path closePath];
    return  path;

}

//从字典corner 中拿到需要的点point
- (CGPoint)pointForCorner:(NSDictionary *)corner {

    CGPoint point;
    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)corner, &point);
    return point;
    
    
}

@end
