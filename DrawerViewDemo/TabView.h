//
//  TabView.h
//
//  Created by Alexis Gallagher on 2012-12-12.
//

#import <UIKit/UIKit.h>
/**
  Draws a downward hanging "tab". Configurable.
 */

@interface TabView : UIView

@property (strong) UIColor * fillColor;
@property (assign) CGFloat protrudingCornerRadii;
@property (assign) CGFloat leadingJoinCornerRadius;
@property (assign) CGFloat trailingJoinCornerRadius;
@property (assign,nonatomic) CGRectEdge connectedEdge;

@end
