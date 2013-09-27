//
//  ALGDoubleGradientLayer.m
//
//  Created by Alexis Gallagher on 2013-01-08.
//

#import "ALGDoubleGradientLayer.h"

@implementation ALGDoubleGradientLayer

- (id)init
{
    self = [super init];
    if (self) {
      [self setOpaque:NO];
      [self setNeedsDisplayOnBoundsChange:YES];
      // default to no gradients
      _endStartingGradientUnitY = 0.0f;
      _beginEndingGradientUnitY = 1.0f;
    }
    return self;
}

-(void)drawInContext:(CGContextRef)ctx
{
  CGFloat const endStartingGradientY = floorf(self.endStartingGradientUnitY * CGRectGetHeight(self.bounds));
  CGFloat const beginEndingGradientY = ceilf(self.beginEndingGradientUnitY * CGRectGetHeight(self.bounds));
  
  // build a gradient
  UIColor * myClearColor = [UIColor clearColor];  //[UIColor colorWithWhite:1.0f alpha:0.0f];
  UIColor * opaqueColor = [UIColor whiteColor];
  NSArray * clearThenOpaque = [NSArray arrayWithObjects:(id)[myClearColor CGColor],(id)[opaqueColor CGColor],nil];
  CGColorSpaceRef colorSpace = CGColorGetColorSpace([opaqueColor CGColor]);
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                      (__bridge CFArrayRef) clearThenOpaque,
                                                      NULL);
  
  CGContextSaveGState(ctx);
  // draw the top gradient
  CGContextDrawLinearGradient(ctx, gradient,
                              CGPointMake(CGRectGetMidX(self.bounds),0 * CGRectGetHeight(self.bounds)),
                              CGPointMake(CGRectGetMidX(self.bounds),endStartingGradientY),
                              0);
  
  // draw the rect in the middle
  CGContextSetFillColorWithColor(ctx, [UIColor redColor].CGColor);
  CGContextFillRect(ctx, UIEdgeInsetsInsetRect(self.bounds,
                                               UIEdgeInsetsMake(endStartingGradientY, 0,
                                                                CGRectGetHeight(self.bounds) - beginEndingGradientY, 0)));

  // draw the bottom gradient
  CGContextDrawLinearGradient(ctx, gradient,
                              CGPointMake(CGRectGetMidX(self.bounds),1.0 * CGRectGetHeight(self.bounds)),
                              CGPointMake(CGRectGetMidX(self.bounds),beginEndingGradientY),
                              0);
  CGContextRestoreGState(ctx);
  
  CFRelease(gradient);
}

@end
