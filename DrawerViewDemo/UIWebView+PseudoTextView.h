//
//  UIWebView+PseudoTextView.h
//
//  Created by Alexis Gallagher on 2012-12-03.
//

#import <UIKit/UIKit.h>

/**
  Treat UIWebView as a plain content view.
 */

@interface UIWebView (PseudoTextView)
/// Hide shadows built-in to UIWebView
-(void)hideBackgroundShadows;
/// Load plain text into the view
-(void)loadText:(NSString *)text font:(UIFont*)font;

/// Add fade-in / fade-out gradients to text area
-(void)addStartingEndingGradients;
/// Layout fade-in / fade-out gradients
-(void)layoutStartingEndingGradients;
@end
