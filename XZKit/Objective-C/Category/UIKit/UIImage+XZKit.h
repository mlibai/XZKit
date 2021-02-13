//
//  UIImage.h
//  XZKit
//
//  Created by Xezun on 2017/10/30.
//

#import <UIKit/UIKit.h>
#import <XZKit/XZKitDefines.h>
#import <XZKit/UIColor+XZKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (XZKit)

/// 读取 XZKit 中的资源库图片。
/// @param name 图片名字
/// @param traitCollection UITraitCollection
/// @return UIImage
+ (nullable UIImage *)XZKit:(NSString *)name compatibleWithTraitCollection:(nullable UITraitCollection *)traitCollection NS_SWIFT_NAME(init(XZKit:compatibleWith:));

/// 读取 XZKit 中的资源库图片。
/// @param name 图片名称
/// @return UIImage
+ (nullable UIImage *)XZKit:(NSString *)name NS_SWIFT_NAME(init(XZKit:));

@end


#pragma mark - 纯色图片绘制

typedef struct XZImageBorder {
    XZRGBA color;
    CGFloat width;
} NS_SWIFT_NAME(XZImageDescriptor.Border) XZImageBorder;

typedef struct XZImageRadius {
    CGFloat topLeft;
    CGFloat topRight;
    CGFloat bottomLeft;
    CGFloat bottomRight;
} NS_SWIFT_NAME(XZImageDescriptor.Radius) XZImageRadius;

typedef struct XZImageDescriptor {
    CGSize size;
    XZRGBA backgroundColor;
    XZImageBorder border;
    XZImageRadius radius;
} NS_SWIFT_NAME(Image) XZImageDescriptor;

FOUNDATION_STATIC_INLINE XZImageDescriptor XZImageDescriptorMake(CGSize size, XZRGBA backgroundColor, XZRGBA borderColor, CGFloat radius) NS_SWIFT_UNAVAILABLE("Use init instead") {
    return (XZImageDescriptor){size, backgroundColor, {borderColor, 1.0 / UIScreen.mainScreen.scale}, {radius, radius, radius, radius}};
}

@interface UIImage (XZKitDrawing)

/// 根据指定条件绘制图片。
/// @param descriptor 图片信息
/// @return 绘制的图片。
+ (nullable UIImage *)xz_imageWithDescriptor:(XZImageDescriptor)descriptor NS_SWIFT_NAME(init(_:));

@end


#pragma mark - 图片颜色混合

@interface UIImage (XZKitBlending)

// 命名：blend 需要宾语，因此用 blending 而不是 bended ：
// image blend (with) alpha => new image

/// 混合。改变图片透明度。
/// @param alpha 透明度
/// @return UIImage
- (nullable UIImage *)xz_imageByBlendingAlpha:(CGFloat)alpha NS_SWIFT_NAME(blending(alpha:));

/// 混合，重新渲染图片颜色。
/// @param tintColor 图片渲染色。
/// @return 渲染后的图片。
- (nullable UIImage *)xz_imageByBlendingColor:(UIColor *)tintColor NS_SWIFT_NAME(blending(_:));

@end


#pragma mark - 滤镜

/// 色阶输入。
typedef struct XZImageLevelsInput {
    /// 阴影。范围 0 ~ 1.0 ，默认 0 。
    CGFloat shadows;
    /// 中间调。范围 0 ~ 9.99 ，默认 1.0 。
    CGFloat midtones;
    /// 高光。范围 0 ~ 1.0 ，默认 1.0 。
    CGFloat highlights;
} NS_SWIFT_NAME(XZImageLevels.Input) XZImageLevelsInput;

UIKIT_EXTERN XZImageLevelsInput const XZImageLevelsInputIdentity NS_SWIFT_NAME(XZImageLevelsInput.identity);

FOUNDATION_STATIC_INLINE XZImageLevelsInput XZImageLevelsInputMake(CGFloat shadows, CGFloat midtones, CGFloat highlights) NS_SWIFT_UNAVAILABLE("Use init instead") {
    return (XZImageLevelsInput){shadows, midtones, highlights};
}

/// 色阶输出。
typedef struct XZImageLevelsOutput {
    /// 阴影。范围 0 ~ 1.0 ，默认 0 。
    CGFloat shadows;
    /// 高光。范围 0 ~ 1.0 ，默认 1.0 。
    CGFloat highlights;
} NS_SWIFT_NAME(XZImageLevels.Output) XZImageLevelsOutput;

UIKIT_EXTERN XZImageLevelsOutput const XZImageLevelsOutputIdentity NS_SWIFT_NAME(XZImageLevelsOutput.identity);

FOUNDATION_STATIC_INLINE XZImageLevelsOutput XZImageLevelsOutputMake(CGFloat shadows, CGFloat highlights) NS_SWIFT_UNAVAILABLE("Use init instead") {
    return (XZImageLevelsOutput){shadows, highlights};
}

/// 色阶。
/// @see [Adobe Photoshop User Guide - Image adjustments](https://helpx.adobe.com/photoshop/using/levels-adjustment.html)
typedef struct XZImageLevels {
    /// 输入
    XZImageLevelsInput input;
    /// 输出
    XZImageLevelsOutput output;
    /// 通道
    XZRGBAChannel channels;
} NS_SWIFT_NAME(XZImageDescriptor.Levels) XZImageLevels;

UIKIT_STATIC_INLINE XZImageLevels XZImageLevelsMake(XZImageLevelsInput input, XZImageLevelsOutput output, XZRGBAChannel channels) XZ_OVERLOAD NS_SWIFT_UNAVAILABLE("Use init instead") {
    return (XZImageLevels){input, output, channels};
}

UIKIT_STATIC_INLINE XZImageLevels XZImageLevelsMake(XZImageLevelsInput input, XZImageLevelsOutput output) XZ_OVERLOAD NS_SWIFT_UNAVAILABLE("Use init instead") {
    return (XZImageLevels){input, output, XZRGBAChannelRGB};
}

/// 构造色阶。
UIKIT_STATIC_INLINE XZImageLevels XZImageLevelsMake(CGFloat shadows, CGFloat midtones, CGFloat highlights, CGFloat outputShadows, CGFloat outputHighlights, XZRGBAChannel channels) XZ_OVERLOAD NS_SWIFT_UNAVAILABLE("Use init instead") {
    return (XZImageLevels){{shadows, midtones, highlights}, {outputShadows, outputHighlights}, channels};
}

/// 构造色阶：默认输出，RGB通道。
UIKIT_STATIC_INLINE XZImageLevels XZImageLevelsMake(CGFloat shadows, CGFloat midtones, CGFloat highlights) XZ_OVERLOAD NS_SWIFT_UNAVAILABLE("Use init instead") {
    return (XZImageLevels){{shadows, midtones, highlights}, XZImageLevelsOutputIdentity, XZRGBAChannelRGB};
}

@interface UIImage (XZKitFiltering)

/// 滤镜。改变图片亮度。
/// @note 图片处理属于高耗性能的操作。
/// @param brightness 图片亮度，取值范围 [0, 1.0]，默认 0.5
/// @return UIImage
- (nullable UIImage *)xz_imageByFilteringBrightness:(CGFloat)brightness NS_SWIFT_NAME(filtering(brightness:));

/// 滤镜。改变图片色阶。
/// @note 图片处理属于高耗性能的操作。
/// @param levels 色阶。
/// @return UIImage
- (nullable UIImage *)xz_imageByFilteringImageLevels:(XZImageLevels)levels NS_SWIFT_NAME(filtering(_:));

@end

NS_ASSUME_NONNULL_END
