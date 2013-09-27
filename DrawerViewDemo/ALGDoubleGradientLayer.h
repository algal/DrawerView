//
//  ALGDoubleGradientLayer.h
//
//  Created by Alexis Gallagher on 2013-01-08.
//

#import <QuartzCore/QuartzCore.h>

/**
 A layer for masking UIWebView to present gradients at the top and bottom of the content.
 
 For instance, setting

   endStartingGradientUnitY = 0.10
   beginEndingGradientUnitY = 0.80

 would mean that the top 10% and the bottom 80% were a gradient
 */
@interface ALGDoubleGradientLayer : CALayer
// end of top gradient in fractional units
@property (assign,nonatomic) CGFloat endStartingGradientUnitY;
// beginning of bottom gradient in fractional units
@property (assign,nonatomic) CGFloat beginEndingGradientUnitY;
@end
