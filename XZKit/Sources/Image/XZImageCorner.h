//
//  XZImageCorner.h
//  XZKit
//
//  Created by Xezun on 2021/2/17.
//

#import <XZKit/XZImageLine.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(XZImage.Corner)
@interface XZImageCorner : XZImageLine

/// 圆角半径。
/// @note 如果设置了半径，那么半径最小值为线条宽度（粗细）。
@property (nonatomic) CGFloat radius;


@end

NS_ASSUME_NONNULL_END
