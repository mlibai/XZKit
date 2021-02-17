//
//  XZImageViewController.m
//  XZKitDemo
//
//  Created by Xezun on 2021/2/16.
//

#import "XZImageViewController.h"
#import <XZKit/XZKit.h>

@interface XZImageSliderView : UIView
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@end

@interface XZImageViewController ()

@property (nonatomic, strong) UIImage *image;

@property (weak, nonatomic) IBOutlet XZImageSliderView *shadowsLevelsView;
@property (weak, nonatomic) IBOutlet XZImageSliderView *midtonesLevelsView;
@property (weak, nonatomic) IBOutlet XZImageSliderView *highlightsLevelsView;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation XZImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    XZImage *image = [[XZImage alloc] init];
    
    image.size            = CGSizeMake(300, 200);
    image.backgroundColor = rgba(0xFF0000, 1.0);
    image.borderColor     = rgba(0x00FF00, 1.0);
    image.borderWidth     = 2.0;
    image.cornerRadius    = 10.0;
    //image.borderDash      = XZImageLineDashMake(1, 1);
    
//    image.borders.arrow.anchor = 0;
//    image.borders.arrow.vector = 0;
//    image.borders.arrow.width  = 40;
//    image.borders.arrow.height = 20;
    
//    image.borders.top.arrow.anchor = 0;
//    image.borders.top.arrow.vector = 0;
//    image.borders.top.arrow.width  = 40;
//    image.borders.top.arrow.height = 20;

    image.borders.bottom.arrow.anchor = 0;
    image.borders.bottom.arrow.vector = 0;
    image.borders.bottom.arrow.width  = 20;
    image.borders.bottom.arrow.height = 10;
    
    image.backgroundImage = [UIImage imageNamed:@"icon_image"];
    image.contentMode = UIViewContentModeScaleAspectFill;
    image.contentInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    
    self.image = image.image;
    
    self.imageView.image = self.image;
    
//    self.imageView.image = [[UIImage imageNamed:@"icon_star"] xz_imageByBlendingColor:rgb(0xff9900)];
}

- (IBAction)imageLevelsChangeAction:(id)sender {
    CGFloat shadows = self.shadowsLevelsView.slider.value;
    CGFloat midtones = self.midtonesLevelsView.slider.value;
    CGFloat highlights = self.highlightsLevelsView.slider.value;
    XZImageLevels levels = XZImageLevelsMake(shadows, midtones, highlights);
    self.imageView.image = [self.image xz_imageByFilteringImageLevels:levels];

    self.shadowsLevelsView.valueLabel.text = [NSString stringWithFormat:@"%.2f", shadows];
    self.midtonesLevelsView.valueLabel.text = [NSString stringWithFormat:@"%.2f", midtones];
    self.highlightsLevelsView.valueLabel.text = [NSString stringWithFormat:@"%.2f", highlights];
    
//    self.imageView.image = [self.image xz_imageByFilteringBrightness:shadows];
}

@end


@implementation XZImageSliderView



@end
