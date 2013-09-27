//
//  DrawerViewController.h
//
//  Created by Alexis Gallagher on 2012-12-17.
//

#import <UIKit/UIKit.h>

/** @brief DrawerViewController manages a \em drawer.

 See README.md for use instructions.

 */
@interface DrawerViewController : UIViewController <UIGestureRecognizerDelegate>

#pragma mark - drawer. exported properties & methods

/** The root view of the entire drawer assembly.

 Client code should add this view hierarchy of the parent view controller.
 
 This should abut the superview's inner edge. Pass it to
 layoutDrawerContainerAgainstDockingEdge: to force it to layout against
 the edge specified by drawerDockingEdge.
 
 */
@property (weak, nonatomic) IBOutlet UIView * drawerContainerView;

/// edge where \p drawerContainerView should align with its superview
@property (assign,nonatomic) CGRectEdge drawerDockingEdge;

// drawer system aesthetic properties
@property (assign,nonatomic) CGFloat drawerCornerRadius;
@property (assign,nonatomic) CGFloat tabTrailingJoinCornerRadius;
@property (assign,nonatomic) CGFloat tabLeadingJoinCornerRadius;
@property (assign,nonatomic) CGFloat tabRelativePosition;

-(void) animatePeekOfDrawer;
@property (strong,nonatomic) NSString * drawerHTMLContentString;

// called by client as part of setup
-(void)layoutDrawerContainerOnly;

// TODO: restrict this to private implemetation classes
-(void)layoutSubviewsOfDrawerContainer;

@end
