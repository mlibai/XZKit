//
//  XZImage.m
//  XZKit
//
//  Created by Xezun on 2021/2/17.
//

#import "XZImage.h"
#import "XZImageBorderArrow+XZImageDrawing.h"
#import "XZImageBorder+XZImageDrawing.h"

/// 连接另一条边时，如果连接的是圆角，则使用圆角半径，否则使用边的一半。
static inline CGFloat DRS(CGFloat radius, CGFloat d) {
    return radius > 0 ? radius : d;
}

/// 避免画的圆角异常：
/// radius < borderWidth / 2 不能画出圆角；
/// radius < borderWidth 会以中心点画出两个半圆。
static inline CGFloat BRS(CGFloat radius, CGFloat b) {
    return radius > 0 ? (radius > b ? radius : b) : 0;
}
/// 给纵横坐标分别增加 dx 和 dy
static inline void CGPointMove(CGPoint *point, CGFloat dx, CGFloat dy) {
    point->x += (dx); point->y += (dy);
}
/// 设置横坐标为 x 并给纵坐标增加 dy
static inline void CGPointMoveY(CGPoint *point, CGFloat x, CGFloat dy) {
    point->x = x; point->y += (dy);
}
/// 给横坐标增加 dx 并设置纵坐标为 y
static inline void CGPointMoveX(CGPoint *point, CGFloat dx, CGFloat y) {
    point->x += dx; point->y = y;
}


@protocol XZImageContext <NSObject>
- (void)drawInContext:(CGContextRef)context;
@end
@interface XZImageContext : NSObject <XZImageContext>
/// 构造
+ (instancetype)contextWithLine:(XZImageLine *)line startPoint:(CGPoint)startPoint;
/// 处于线型交接的线条需要起点。
@property (nonatomic, readonly) CGPoint startPoint;
/// 线型
@property (nonatomic, strong, readonly) XZImageLine *line;
/// 添加一条直线
- (void)addLineToPoint:(CGPoint)endPoint;
/// 添加一个圆角
- (void)addArcWithCenter:(CGPoint)center radius:(CGFloat)radiusTR startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle;
@end



@implementation XZImage

@synthesize corners = _corners;
@synthesize borders = _borders;

- (XZImageCorners *)corners {
    if (_corners == nil) {
        _corners = [[XZImageCorners alloc] init];
    }
    return _corners;
}

- (XZImageBorders *)borders {
    if (_borders == nil) {
        _borders = [[XZImageBorders alloc] init];
    }
    return _borders;
}

- (CGFloat)borderWidth {
    return _borders.width;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.borders.width = borderWidth;
    self.corners.width = borderWidth;
}

- (UIColor *)borderColor {
    return _borders.color;
}

- (void)setBorderColor:(UIColor *)borderColor {
    self.borders.color = borderColor;
    self.corners.color = borderColor;
}

- (XZImageLineDash)borderDash {
    return _borders.dash;
}

- (void)setBorderDash:(XZImageLineDash)borderDash {
    self.borders.dash = borderDash;
    self.corners.dash = borderDash;
}

- (CGFloat)cornerRadius {
    return _corners.radius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.corners.radius = cornerRadius;
}

/// 默认绘制区域大小。
- (CGSize)defaultSize {
    CGSize size = self.size;
    if (size.width > 0 && size.height > 0) {
        return size;
    }
    UIImage *backgroundImage = self.backgroundImage;
    if (backgroundImage == nil) {
        return CGSizeZero;
    }
    size = backgroundImage.size;
    if (size.width <= 0 || size.height <= 0) {
        return CGSizeZero;
    }
    if (self.backgroundImage.scale == UIScreen.mainScreen.scale) {
        return size;
    }
    CGFloat as = UIScreen.mainScreen.scale / self.backgroundImage.scale;
    size.width /= as;
    size.height /= as;
    return size;
}

- (UIImage *)image {
    CGRect rect = CGRectZero;
    CGRect frame = CGRectZero;
    
    CGSize const size = [self defaultSize];
    [self prepareRect:&rect frame:&frame withPoint:CGPointZero size:size];
    
    CGFloat const w = frame.size.width + frame.origin.x * 2;
    CGFloat const h = frame.size.height + frame.origin.y * 2;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), NO, 0);
    [self drawWithRect:rect frame:frame];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)drawAtPoint:(CGPoint)point {
    CGRect rect = CGRectZero;
    CGRect frame = CGRectZero;
    
    CGSize const size = [self defaultSize];
    [self prepareRect:&rect frame:&frame withPoint:point size:size];
    
    [self drawWithRect:rect frame:frame];
}

- (void)drawInRect:(CGRect)rect1 {
    CGRect rect = CGRectZero;
    CGRect frame = CGRectZero;
    [self prepareRect:&rect frame:&frame withPoint:rect1.origin size:rect1.size];
    [self drawWithRect:rect frame:frame];
}

/// 计算绘制的背景区域、边框区域。
- (void)prepareRect:(CGRect *)rect frame:(CGRect *)frame withPoint:(CGPoint)point size:(CGSize)size {
    UIEdgeInsets const contentInsets = self.contentInsets;
    XZImageBorders *const borders = self.borders;
    XZImageCorners *const corners = self.corners;
    // 内容边距
    CGFloat const top    = (borders.top.arrowIfLoaded.height    + contentInsets.top);
    CGFloat const left   = (borders.left.arrowIfLoaded.height   + contentInsets.left);
    CGFloat const bottom = (borders.bottom.arrowIfLoaded.height + contentInsets.bottom);
    CGFloat const right  = (borders.right.arrowIfLoaded.height  + contentInsets.right);
    
    // 所需的最小宽度、高度
    CGFloat width = left + right;
    width += MAX(corners.topLeft.radius, corners.bottomLeft.radius);
    width += MAX(borders.top.arrowIfLoaded.width, borders.bottom.arrowIfLoaded.width);
    width += MAX(corners.topRight.radius, corners.bottomRight.radius);
    CGFloat height = top + bottom;
    height += MAX(corners.topLeft.radius, corners.topRight.radius);
    height += MAX(borders.left.arrowIfLoaded.width, borders.right.arrowIfLoaded.width);
    height += MAX(corners.bottomLeft.radius, corners.bottomRight.radius);
    
    CGFloat const deltaW = MAX(0, size.width - point.x - width);
    CGFloat const deltaH = MAX(0, size.height - point.y - height);
    
    frame->origin.x = point.x + contentInsets.left;
    frame->origin.y = point.y + contentInsets.top;
    frame->size.width = (width - contentInsets.left - contentInsets.right) + deltaW;
    frame->size.height = (height - contentInsets.top - contentInsets.bottom) + deltaH;
    
    rect->origin.x = point.x + left;
    rect->origin.y = point.y + top;
    rect->size.width = width + deltaW - left - right;
    rect->size.height = height + deltaH - top - bottom;
}

/// 绘制。
/// @param rect 边框的绘制区域
/// @param frame 包括箭头在内的整体绘制区域
- (void)drawWithRect:(CGRect const)rect frame:(CGRect const)frame {
    NSMutableArray<XZImageContext *> * const contexts = [NSMutableArray arrayWithCapacity:8];
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [self createContexts:contexts path:path withRect:rect];

    CGContextRef const context = UIGraphicsGetCurrentContext();
    // LineJion 拐角：kCGLineJoinMiter尖角、kCGLineJoinRound圆角、kCGLineJoinBevel缺角
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    // LineCap 线端：kCGLineCapButt无、kCGLineCapRound圆形、kCGLineCapSquare方形
    CGContextSetLineCap(context, kCGLineCapButt);
    CGContextSetFillColorWithColor(context, UIColor.clearColor.CGColor);
    
    // 绘制背景
    CGContextSaveGState(context);
    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextAddPath(context, path.CGPath);
    CGContextFillPath(context);
    CGContextRestoreGState(context);
    if (self.backgroundImage) {
        CGContextSaveGState(context);
        CGContextAddPath(context, path.CGPath);
        CGContextClip(context);
        CGSize size = self.backgroundImage.size;
        CGRect rect = CGSizeFitingInRectWithContentMode(size, frame, self.contentMode);
        [self.backgroundImage drawInRect:rect];
        CGContextRestoreGState(context);
    }
    // 切去最外层的一像素，避免border因为抗锯齿或误差盖不住底色。
    CGContextSaveGState(context);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextSetStrokeColorWithColor(context, UIColor.clearColor.CGColor);
    CGContextSetLineWidth(context, 1.0 / UIScreen.mainScreen.scale);
    CGContextAddPath(context, path.CGPath);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    
    // 绘制边框
    for (XZImageContext *imageContext in contexts) {
        CGContextSaveGState(context);
        
        [imageContext drawInContext:context];
        
        CGContextStrokePath(context);
        CGContextRestoreGState(context);
    }
}

/// 创建绘制内容。
/// @param contexts 输出，边框的绘制内容将添加到此数组
/// @param backgroundPath 输出，背景色填充路径
/// @param rect 绘制区域（矩形所在的区域，不包括箭头，箭头绘制在此区域外）
- (void)createContexts:(NSMutableArray<XZImageContext *> * const)contexts path:(UIBezierPath * const)backgroundPath withRect:(CGRect const)rect {
    
    CGFloat const minX = CGRectGetMinX(rect);
    CGFloat const minY = CGRectGetMinY(rect);
    CGFloat const maxX = CGRectGetMaxX(rect);
    CGFloat const maxY = CGRectGetMaxY(rect);
    CGFloat const midX = CGRectGetMidX(rect);
    CGFloat const midY = CGRectGetMidY(rect);
    
    // 最大圆角半径
    CGFloat const maxR = MIN(rect.size.width, rect.size.height) * 0.5;
    
    XZImageCorner * const topLeft     = self.corners.topLeft;
    XZImageBorder * const top         = self.borders.top;
    XZImageCorner * const topRight    = self.corners.topRight;
    XZImageBorder * const right       = self.borders.right;
    XZImageCorner * const bottomRight = self.corners.bottomRight;
    XZImageBorder * const bottom      = self.borders.bottom;
    XZImageCorner * const bottomLeft  = self.corners.bottomLeft;
    XZImageBorder * const left        = self.borders.left;
    
    CGFloat const radiusTR = BRS(MIN(maxR, topRight.radius), topRight.width);
    CGFloat const radiusBR = BRS(MIN(maxR, bottomRight.radius), bottomRight.width);
    CGFloat const radiusBL = BRS(MIN(maxR, bottomLeft.radius), bottomLeft.width);
    CGFloat const radiusTL = BRS(MIN(maxR, topLeft.radius), topLeft.width);
    
    { // 调整箭头位置
        CGFloat const w_2 = midX - minX;
        CGFloat const h_2 = midY - minY;
        [top.arrowIfLoaded adjustAnchorWithMinValue:-(w_2 - radiusTL - top.width) maxValue:(w_2 - radiusTR - top.width)];
        [top.arrowIfLoaded adjustVectorWithMinValue:-w_2 maxValue:w_2];
        
        [left.arrowIfLoaded adjustAnchorWithMinValue:-(h_2 - radiusBL - left.width) maxValue:(h_2 - radiusTL - left.width)];
        [left.arrowIfLoaded adjustVectorWithMinValue:-h_2 maxValue:h_2];
        
        [bottom.arrowIfLoaded adjustAnchorWithMinValue:-(w_2 - radiusBR - bottom.width) maxValue:(w_2 - radiusBL - bottom.width)];
        [bottom.arrowIfLoaded adjustVectorWithMinValue:-w_2 maxValue:w_2];
        
        [right.arrowIfLoaded adjustAnchorWithMinValue:-(h_2 - radiusTR - right.width) maxValue:(h_2 - radiusBR - right.width)];
        [right.arrowIfLoaded adjustVectorWithMinValue:-h_2 maxValue:h_2];
    }

    CGFloat const dT   = top.width;
    CGFloat const dT_2 = dT * 0.5;
    CGFloat const dR   = right.width;
    CGFloat const dR_2 = dR * 0.5;
    CGFloat const dB   = bottom.width;
    CGFloat const dB_2 = dB * 0.5;
    CGFloat const dL   = left.width;
    CGFloat const dL_2 = dL * 0.5;
    
    { // MARK: - Top line
        CGPoint start = CGPointMake(minX + radiusTL, minY);
        [backgroundPath moveToPoint:start];
        
        CGPointMove(&start, 0, dT_2);
        XZImageContext * const context = [XZImageContext contextWithLine:top startPoint:start];
        
        CGPoint end = CGPointMake(maxX - radiusTR, minY);
        
        XZImageBorderArrow const *arrow = top.arrowIfLoaded;
        if (arrow.width > 0 && arrow.height > 0) {
            CGFloat const w = arrow.width * 0.5;
            
            CGPoint point1 = CGPointMake(midX + arrow.anchor - w, minY);
            CGPoint point2 = CGPointMake(midX + arrow.vector, minY - arrow.height);
            CGPoint point3 = CGPointMake(midX + arrow.anchor + w, minY);
            [backgroundPath addLineToPoint:point1];
            [backgroundPath addLineToPoint:point2];
            [backgroundPath addLineToPoint:point3];
            
            CGPoint const offset1 = [arrow offsetForVectorAtIndex:2 lineOffset:dT_2];
            CGPoint const offset2 = [arrow offsetForVectorAtIndex:0 lineOffset:dT_2];
            CGPoint const offset3 = [arrow offsetForVectorAtIndex:1 lineOffset:dT_2];
            CGPointMove(&point1, offset1.x, offset1.y);
            CGPointMove(&point2, offset2.x, offset2.y);
            CGPointMove(&point3, offset3.x, offset3.y);
            
            [context addLineToPoint:point1];
            [context addLineToPoint:point2];
            [context addLineToPoint:point3];
        }
        [backgroundPath addLineToPoint:end];
        
        CGPointMoveY(&end, maxX - DRS(radiusTR, dR), dT_2);
        [context addLineToPoint:end];
        
        [contexts addObject:context];
    }
    
    if (radiusTR > 0) { // MARK: - Top Right
        CGPoint const center = CGPointMake(maxX - radiusTR, minY + radiusTR);
        CGFloat const startAngle = -M_PI_2;
        CGFloat const endAngle   = 0;
        [backgroundPath addArcWithCenter:center radius:radiusTR startAngle:startAngle endAngle:endAngle clockwise:YES];
        
        CGFloat const dTR_2 = topRight.width * 0.5;
        
        CGPoint const start = CGPointMake(maxX - radiusTR, minY + dTR_2);
        XZImageContext *context = [XZImageContext contextWithLine:topRight startPoint:start];
        [context addArcWithCenter:center
                           radius:(radiusTR - dTR_2)
                       startAngle:(startAngle)
                         endAngle:endAngle];
        [contexts addObject:context];
    }
    
    { // MARK: - Right
        CGPoint start = CGPointMake(maxX, minY + radiusTR);
        [backgroundPath addLineToPoint:start];
        
        CGPointMove(&start, -dR_2, 0);
        XZImageContext *context = [XZImageContext contextWithLine:right startPoint:start];
        
        CGPoint end = CGPointMake(maxX, maxY - radiusBR);
        
        XZImageBorderArrow const *arrow = right.arrowIfLoaded;
        if (arrow.width > 0 && arrow.height > 0) {
            CGFloat const w = arrow.width * 0.5;
            
            CGPoint point1 = CGPointMake(maxX, midY + arrow.anchor - w);
            CGPoint point2 = CGPointMake(maxX + arrow.height, midY + arrow.vector);
            CGPoint point3 = CGPointMake(maxX, midY + arrow.anchor + w);
            [backgroundPath addLineToPoint:point1];
            [backgroundPath addLineToPoint:point2];
            [backgroundPath addLineToPoint:point3];
            
            CGPoint const offset1 = [arrow offsetForVectorAtIndex:2 lineOffset:dR_2];
            CGPoint const offset2 = [arrow offsetForVectorAtIndex:0 lineOffset:dR_2];
            CGPoint const offset3 = [arrow offsetForVectorAtIndex:1 lineOffset:dR_2];
            CGPointMove(&point1, -offset1.y, offset1.x);
            CGPointMove(&point2, -offset2.y, offset2.x);
            CGPointMove(&point3, -offset3.y, offset3.x);
            
            [context addLineToPoint:point1];
            [context addLineToPoint:point2];
            [context addLineToPoint:point3];
        }
        [backgroundPath addLineToPoint:end];
        
        CGPointMoveX(&end, -dR_2, maxY - DRS(radiusBR, dB));
        [context addLineToPoint:end];
        [contexts addObject:context];
    }
    
    if (radiusBR > 0) { // MARK: - BottomRight
        CGPoint const center = CGPointMake(maxX - radiusBR, maxY - radiusBR);
        CGFloat const startAngle = 0;
        CGFloat const endAngle   = M_PI_2;
        [backgroundPath addArcWithCenter:center radius:radiusBR startAngle:startAngle endAngle:endAngle clockwise:YES];
        
        CGFloat const dBR_2 = bottomRight.width * 0.5;
        
        CGPoint const start = CGPointMake(maxX - dBR_2, maxY - radiusBR);
        XZImageContext *context = [XZImageContext contextWithLine:topRight startPoint:start];
        [context addArcWithCenter:center
                           radius:(radiusBR - dBR_2)
                       startAngle:(startAngle)
                         endAngle:endAngle];
        [contexts addObject:context];
    }
    
    { // MARK: - Bottom
        CGPoint start = CGPointMake(maxX - radiusBR, maxY);
        [backgroundPath addLineToPoint:start];
        
        CGPointMove(&start, 0, -dB_2);
        XZImageContext *context = [XZImageContext contextWithLine:right startPoint:start];
        
        CGPoint end = CGPointMake(minX + radiusBL, maxY);
        
        XZImageBorderArrow const *arrow = bottom.arrowIfLoaded;
        if (arrow.width > 0 && arrow.height > 0) {
            CGFloat const w = arrow.width * 0.5;
            
            CGPoint point1 = CGPointMake(midX - arrow.anchor + w, maxY);
            CGPoint point2 = CGPointMake(midX + arrow.vector, maxY + arrow.height);
            CGPoint point3 = CGPointMake(midX - arrow.anchor - w, maxY);
            [backgroundPath addLineToPoint:point1];
            [backgroundPath addLineToPoint:point2];
            [backgroundPath addLineToPoint:point3];
            
            CGPoint const offset1 = [arrow offsetForVectorAtIndex:2 lineOffset:dB_2];
            CGPoint const offset2 = [arrow offsetForVectorAtIndex:0 lineOffset:dB_2];
            CGPoint const offset3 = [arrow offsetForVectorAtIndex:1 lineOffset:dB_2];
            CGPointMove(&point1, -offset1.x, -offset1.y);
            CGPointMove(&point2, -offset2.x, -offset2.y);
            CGPointMove(&point3, -offset3.x, -offset3.y);
            
            [context addLineToPoint:point1];
            [context addLineToPoint:point2];
            [context addLineToPoint:point3];
        }
        [backgroundPath addLineToPoint:end];
        
        CGPointMoveY(&end, minX + DRS(radiusBL, dL), -dB_2);
        [context addLineToPoint:end];
        [contexts addObject:context];
    }
    
    if (radiusBL > 0) { // MARK: - BottomLeft
        CGPoint const center = CGPointMake(minX + radiusBL, maxY - radiusBL);
        CGFloat const startAngle = M_PI_2;
        CGFloat const endAngle   = M_PI;
        [backgroundPath addArcWithCenter:center radius:radiusBL startAngle:startAngle endAngle:endAngle clockwise:YES];
        
        CGFloat const dBL_2 = bottomLeft.width * 0.5;
        CGPoint const start = CGPointMake(minX + radiusBL, maxY - dBL_2);
        
        XZImageContext *context = [XZImageContext contextWithLine:topRight startPoint:start];
        [context addArcWithCenter:center
                           radius:(radiusBL - dBL_2)
                       startAngle:(startAngle)
                         endAngle:endAngle];
        [contexts addObject:context];
    }
    
    { // MARK: - Left
        CGPoint start = CGPointMake(minX, maxY - radiusBL);
        [backgroundPath addLineToPoint:start];
        
        CGPointMove(&start, dL_2, 0);
        XZImageContext *context = [XZImageContext contextWithLine:left startPoint:start];
        
        CGPoint end = CGPointMake(minX, minY + radiusTL);
        
        XZImageBorderArrow const *arrow = left.arrowIfLoaded;
        if (arrow.width > 0 && arrow.height > 0) {
            CGFloat const w = arrow.width * 0.5;
            
            CGPoint point1 = CGPointMake(minX, midY - arrow.anchor + w);
            CGPoint point2 = CGPointMake(minX - arrow.height, midY + arrow.vector);
            CGPoint point3 = CGPointMake(minX, midY - arrow.anchor - w);
            [backgroundPath addLineToPoint:point1];
            [backgroundPath addLineToPoint:point2];
            [backgroundPath addLineToPoint:point3];
            
            CGPoint const offset1 = [arrow offsetForVectorAtIndex:2 lineOffset:dL_2];
            CGPoint const offset2 = [arrow offsetForVectorAtIndex:0 lineOffset:dL_2];
            CGPoint const offset3 = [arrow offsetForVectorAtIndex:1 lineOffset:dL_2];
            CGPointMove(&point1, offset1.y, -offset1.x);
            CGPointMove(&point2, offset2.y, -offset2.x);
            CGPointMove(&point3, offset3.y, -offset3.x);
            
            [context addLineToPoint:point1];
            [context addLineToPoint:point2];
            [context addLineToPoint:point3];
        }
        [backgroundPath addLineToPoint:end];
        
        CGPointMoveX(&end, dL_2, minY + DRS(radiusTL, dT));
        [context addLineToPoint:end];
        [contexts addObject:context];
    }
    
    if (radiusTL > 0) { // MARK: - TopLeft
        CGPoint const center = CGPointMake(minX + radiusTL, minY + radiusTL);
        CGFloat const startAngle = -M_PI;
        CGFloat const endAngle   = -M_PI_2;
        [backgroundPath addArcWithCenter:center radius:radiusTL startAngle:startAngle endAngle:endAngle clockwise:YES];
        
        CGFloat const dTL_2 = topLeft.width * 0.5;
        CGPoint const start = CGPointMake(minX + dTL_2, minY + radiusTL);
        
        XZImageContext *context = [XZImageContext contextWithLine:topRight startPoint:start];
        [context addArcWithCenter:center
                           radius:(radiusTL - dTL_2)
                       startAngle:(startAngle)
                         endAngle:endAngle];
        [contexts addObject:context];
    }
    
    [backgroundPath closePath];
}

@end




@interface XZImageLineContext : NSObject <XZImageContext>
@property (nonatomic) CGPoint endPoint;
@end

@interface XZImageArcContext : NSObject <XZImageContext>
@property (nonatomic) CGPoint center;
@property (nonatomic) CGFloat radius;
@property (nonatomic) CGFloat startAngle;
@property (nonatomic) CGFloat endAngle;
@end

@implementation XZImageContext {
    NSMutableArray<id<XZImageContext>> *_images;
}

+ (instancetype)contextWithLine:(XZImageLine *)line startPoint:(CGPoint)startPoint {
    return [[self alloc] initWithLine:line startPoint:startPoint];
}

- (instancetype)initWithLine:(XZImageLine *)line startPoint:(CGPoint)startPoint {
    self = [super init];
    if (self) {
        _line = line;
        _startPoint = startPoint;
        _images = [NSMutableArray arrayWithCapacity:4];
    }
    return self;
}

- (void)addLineToPoint:(CGPoint)endPoint {
    XZImageLineContext *border = [[XZImageLineContext alloc] init];
    border.endPoint = endPoint;
    [_images addObject:border];
}

- (void)addArcWithCenter:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle {
    XZImageArcContext *corner = [[XZImageArcContext alloc] init];
    corner.radius = radius;
    corner.center = center;
    corner.startAngle = startAngle;
    corner.endAngle   = endAngle;
    [_images addObject:corner];
}

- (void)drawInContext:(CGContextRef)context {
    CGContextMoveToPoint(context, _startPoint.x, _startPoint.y);
    
    CGContextSetStrokeColorWithColor(context, _line.color.CGColor);
    CGContextSetLineWidth(context, _line.width);
    if (_line.dash.width > 0 && _line.dash.space > 0) {
        CGFloat const dashes[2] = {_line.dash.width, _line.dash.space};
        CGContextSetLineDash(context, 0, dashes, 2);
    }
    
    for (id<XZImageContext> image in _images) {
        [image drawInContext:context];
    }
}

@end

@implementation XZImageArcContext

- (void)drawInContext:(CGContextRef)context {
    // CG 的坐标系 顺时针方向 跟 UI 是反的
    CGContextAddArc(context, _center.x, _center.y, _radius, _startAngle, _endAngle, NO);
}

@end

@implementation XZImageLineContext

- (void)drawInContext:(CGContextRef)context {
    CGContextAddLineToPoint(context, _endPoint.x, _endPoint.y);
    
    // NSLog(@"addLine: (%.2f, %.2f)", _endPoint.x, _endPoint.y);
}

@end
