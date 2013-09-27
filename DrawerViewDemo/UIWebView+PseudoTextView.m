//
//  UIWebView+PseudoTextView.m
//
//  Created by Alexis Gallagher on 2012-12-03.
//

#import "UIWebView+PseudoTextView.h"

#import <QuartzCore/QuartzCore.h>
#import "ALGDoubleGradientLayer.h"

static NSString * CSSFontRulesetFromFontFamilySize(NSString * fontFamily,CGFloat fontSize)
{
  return [NSString stringWithFormat:@"{font-family: \"%@\"; font-size: %@px;}",
          fontFamily,@(fontSize)];
}

static void HideBackgroundShadows(UIWebView * webView)
{
  webView.backgroundColor = [UIColor clearColor];
  for (UIView* subView in [webView subviews])
  {
    if ([subView isKindOfClass:[UIScrollView class]]) {
      for (UIView* shadowView in [subView subviews])
      {
        if ([shadowView isKindOfClass:[UIImageView class]]) {
          [shadowView setHidden:YES];
        }
      }
    }
  }
}


@implementation UIWebView (PseudoTextView)
-(void)hideBackgroundShadows
{
  HideBackgroundShadows(self);
}

/**
 Adds a gradient layer to fade-out the text at the bottom.
 
 */
-(void)addStartingEndingGradients
{
  ALGDoubleGradientLayer * gradLayer = [[ALGDoubleGradientLayer alloc] init];
  gradLayer.frame = self.layer.bounds;
  gradLayer.rasterizationScale = self.layer.rasterizationScale;
  gradLayer.contentsScale = self.layer.contentsScale;
  gradLayer.endStartingGradientUnitY = 0.05f;
  gradLayer.beginEndingGradientUnitY = 1.0f-0.05f;
  
  /*
   CALayer.layer.mask says CALayer.layer should not have a superview, so we
   temporarily remove the UIWebView from the view hierarchy so we can add
   the mask layer while it has no superview.
   */
  UIView * mySuperview = self.superview;
  NSUInteger pos = [[mySuperview subviews] indexOfObject:self];
  [self removeFromSuperview];
  self.layer.mask = gradLayer;
  [mySuperview insertSubview:self atIndex:pos];
}

/**
 Resizes mask gradient and adjusts its active region.

 Can't rely on layer auto-resizing since we shouldn't subclass UIWebView to override
 layoutSublayers to tell it to resize the sublayers of the UIWebView.layer.
 */

-(void)layoutStartingEndingGradients
{
  self.layer.mask.frame = self.layer.bounds;
}


-(void)loadText:(NSString *)text font:(UIFont*)font
{
  [self loadText:text fontFamily:font.fontName fontSize:font.pointSize];
}

/**

 @param text text to display
 
 @param fontFamily name to be included in the CSS font-family property, which may
 be either the font's actual familyName (which then leaves font-variant, font-style, 
 and font-weight unspecified) or which may be the font's fontName, which is its 
 PostScript name, which will fully specify the font to the UIWebView.

 @param fontSize   size of the font in points, to be declared in px to UIWebView.
 */
-(void)loadText:(NSString*)text fontFamily:(NSString*)fontFamily fontSize:(CGFloat)fontSize
{
  NSString * const textContentAsHTML = [NSString stringWithFormat:
                                        @"<html>\n"
                                        @"<head>\n"
                                        @"<style type=\"text/css\">\n"
                                        @"body %@\n"
                                        @"</style>\n"
                                        @"</head>\n"
                                        @"<body>%@</body>\n"
                                        @"</html>",
                                        CSSFontRulesetFromFontFamilySize(fontFamily, fontSize),
                                        text];
  [self loadHTMLString:textContentAsHTML baseURL:nil];
}

//+(NSString*)styleTag

@end
