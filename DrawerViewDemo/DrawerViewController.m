//
//  DrawerViewController.m
//
//  Created by Alexis Gallagher on 2012-12-17.
//

#import <QuartzCore/QuartzCore.h>

#import "DrawerViewController.h"

#import "UIWebView+PseudoTextView.h"
#import "TabView.h"

#define IOS7_SYSTEM_GREEN_IOS7  ((UIColor*) UIColorFromHex(0x4CD964, 1.0f))
#define IOS7_SYSTEM_BLUE_IOS7   ((UIColor*) UIColorFromHex(0x007AFF, 1.0f))
#define IOS7_SYSTEM_RED_IOS7    ((UIColor*) UIColorFromHex(0xFF3B30, 1.0f))
#define IOS7_SYSTEM_GREY_IOS7   ((UIColor*) UIColorFromHex(0x8E8E93, 1.0f))
#define IOS7_ORANGE             ((UIColor*) UIColorFromHex(0xFF9500, 1.0f))
#define IOS7_MARINE_BLUE        ((UIColor*) UIColorFromHex(0x34AADC, 1.0f))
//#define CORPORATE_BLUE_COLOR  ((UIColor*) UIColorFromHex(0x0E2A44, 1.0f))


// drawer layout & appearance properties
#define DRAWER_BACKGROUND_COLOR ((UIColor*) [UIColor colorWithWhite:0.85 alpha:1.000])
static CGFloat const DRAWER_ALPHA = ((CGFloat) 0.9);
static CGFloat const DRAWER_CORNER_RADIUS = 0; // 12.;
static CGFloat const DRAWER_WIDTH_WHEN_VERTICAL = 356.f;
static CGFloat const DRAWER_HEIGHT_WHEN_HORIZONTAL = 300.f;

// drawer open/close behavior
static NSTimeInterval const DRAWER_OPEN_ANIMATION_DURATION = ((NSTimeInterval) 0.25);
static NSTimeInterval const PEEK_ANIMATION_DURATION = ((NSTimeInterval) 1.0);
static CGFloat const DRAWER_PEEK_ANIMATION_DRAWER_POSITION = 0.0375;

// drawer shudder behavior
// (when thrown above the escape speed, the drawer transitions then shudders on completion)
static CGFloat const DRAWER_ESCAPE_SPEED = 400.f;
static NSTimeInterval const DRAWER_SHUDDER_ANIMATION_DURATION = ((NSTimeInterval) 0.25);
static CGFloat const DRAWER_SHUDDER_MAGNITUDE = 15.f;

// drawer redocking behavior
static BOOL const DRAWER_REDOCK_RESTRICT_DRAG_AXIS = YES;
static BOOL const DRAWER_REDOCK_DO_PICKUP_TRANSFORM = NO;
static CGFloat const DRAWER_REDOCK_TEAROFF_DELTA = 100;
static NSTimeInterval const DRAWER_REDOCK_TEAROFF_ANIMATION_DURATION = 0.1;
static NSTimeInterval const DRAWER_REDOCK_PICKUP_PRESS_DURATION  = 1.5f;
static NSTimeInterval const DRAWER_REDOCK_PICKUP_ANIMATION_DURATION  = 0.2;
static NSTimeInterval const DRAWER_REDOCK_ANIMATION_DURATION = 0.5;
static NSTimeInterval const DRAWER_REDOCK_RECONFIG_ANIMATION_DURATION = 0.125;

static BOOL const DRAWER_REDOCK_OVERLAY = NO;
static CGFloat const DRAWER_REDOCK_OVERLAY_ALPHA = 0.9;
static CGFloat const DRAWER_REDOCK_OVERLAY_DRAWER_ALPHA = 0.5;

@interface DrawerViewController ()
// private state
@property (weak, nonatomic) IBOutlet UIView    * drawerView;      // slides within drawerContainer
@property (weak, nonatomic) IBOutlet UIButton  * drawerControlButton;
@property (weak, nonatomic) IBOutlet UIView    * drawerBackgroundView;
@property (weak, nonatomic) IBOutlet UIWebView * drawerWebView;
@property (weak, nonatomic) IBOutlet TabView   * drawerTabView;
@property (weak, nonatomic) IBOutlet UIView *drawerRedockInfoOverlay;

@property (assign, nonatomic) BOOL isDragging;
@property (assign, nonatomic) CGRectEdge lastNearestEdgeWhileDragging;
@property (weak, nonatomic) UIPanGestureRecognizer * panGR;
@property (weak, nonatomic) UILongPressGestureRecognizer * longPressGR;
@end

static inline CGPoint ALGCGPointAdd(CGPoint p1, CGPoint p2) {
  return CGPointMake(p1.x + p2.x, p1.y + p2.y);
}

static inline CGPoint ALGCGPointSubtract(CGPoint final, CGPoint initial) {
  return CGPointMake(final.x - initial.x, final.y - initial.y);
}

static inline CGPoint ALGCGPointTimes(CGPoint point, CGFloat scalar) {
  return CGPointMake(point.x * scalar, point.y * scalar);
}

static inline CGFloat ALGCGPointInnerProduct(CGPoint p,CGPoint q) {
  return p.x * q.x + p.y * q.y;
}

static inline CGFloat ALGCGPointMaximumNorm(CGPoint point) {
  return MAX(fabsf(point.x),fabsf(point.y));
}

static inline CGFloat ALGCGPointEuclideanNorm(CGPoint point) {
  return sqrtf(ALGCGPointInnerProduct(point, point));
}


@implementation DrawerViewController

#pragma mark - drawer lifecycle methods

-(void)awakeFromNib {
  PSLogDebug(@"entering");
  [super awakeFromNib];
  
//  UIColor * tk = [UIColor colorWithWhite:0.753 alpha:1.000];
  // setup default configurations
  self.drawerDockingEdge = CGRectMaxXEdge;
  self.isDragging = NO;
  self.drawerCornerRadius = DRAWER_CORNER_RADIUS;
  
  // tab configs
  self.tabTrailingJoinCornerRadius = 5.f;
  self.tabLeadingJoinCornerRadius = 5.f;
  self.tabRelativePosition = 0.0875;
  PSLogDebug(@"exiting");
}

-(void) viewDidLoad {
  PSLogDebug(@"entering");
  [super viewDidLoad];
  
  // configure the tab view
  TabView * tabView = self.drawerTabView;
  tabView.connectedEdge = self.drawerDockingEdge;
  tabView.fillColor = DRAWER_BACKGROUND_COLOR;
  tabView.backgroundColor = nil;
  tabView.opaque = NO;
  tabView.trailingJoinCornerRadius = self.tabTrailingJoinCornerRadius;
  tabView.leadingJoinCornerRadius = self.tabLeadingJoinCornerRadius;
//  tabView.protrudingCornerRadii = self.tabLeadingJoinCornerRadius;
    tabView.protrudingCornerRadii = (tabView.frame.size.height - tabView.trailingJoinCornerRadius - tabView.leadingJoinCornerRadius )/2;
  
  [self.drawerControlButton addTarget:self
                               action:@selector(animateDrawerToOppositeState)
                     forControlEvents:UIControlEventTouchUpInside];
  
  // add a GR to the tab view's tour button to allow slide open/closed
  UIPanGestureRecognizer * panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                           action:@selector(handlePanOnDrawerButton:)];
  [self.drawerControlButton addGestureRecognizer:panGR];
  self.panGR = panGR;
  
  // attach a long press GR
  if (NO) {
    UILongPressGestureRecognizer * pressGR = [[UILongPressGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(handleLongPress:)];
    pressGR.minimumPressDuration = DRAWER_REDOCK_PICKUP_PRESS_DURATION;
    [self.drawerControlButton addGestureRecognizer:pressGR];
    self.longPressGR = pressGR;
    pressGR.delegate = self;
  }
  
  // style the tour drawer and its controls
  self.drawerBackgroundView.backgroundColor = DRAWER_BACKGROUND_COLOR;
  self.drawerView.backgroundColor = nil;
  
  self.drawerWebView.opaque  = NO;
  self.drawerWebView.backgroundColor = [UIColor clearColor];
  [self.drawerWebView addStartingEndingGradients];
  [self.drawerWebView hideBackgroundShadows];
  [self.drawerWebView loadHTMLString:self.drawerHTMLContentString
                             baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
  
  if (DRAWER_ALPHA == 1.0f && self.drawerCornerRadius == 0.0f) {
    self.drawerBackgroundView.opaque = YES;
  }
  else {
    self.drawerBackgroundView.opaque = NO;
  }
  self.drawerBackgroundView.alpha = DRAWER_ALPHA;
  self.drawerTabView.alpha = self.drawerBackgroundView.alpha;
  
  self.drawerRedockInfoOverlay.hidden = YES;
  self.drawerRedockInfoOverlay.backgroundColor = DRAWER_BACKGROUND_COLOR;
  self.drawerRedockInfoOverlay.alpha = DRAWER_REDOCK_OVERLAY_ALPHA;
  self.drawerRedockInfoOverlay.layer.cornerRadius = 12.f;
  PSLogDebug(@"exiting");
}

//-(void) viewWillAppear:(BOOL)animated {
//  PSLogDebug(@"entering");
//  [super viewWillAppear:animated];
//
////  [self layoutDrawerContainerOnly];
//// parent VC or parent V is reponsible for laying out the drawer container
//  
////  [self layoutDrawerAsOpen:NO]; // should be called only on first-run
//
//  PSLogDebug(@"exiting");
//}

//-(void) viewDidLayoutSubviews
//{
//  PSLogDebug(@"entering");
//  [super viewDidLayoutSubviews];
//  PSLogDebug(@"exiting");
//}

//-(void)viewWillLayoutSubviews
//{
//  PSLogDebug(@"entering");
//  [super viewWillLayoutSubviews];
//  PSLogDebug(@"exiting");
//}

//-(void) viewDidAppear:(BOOL)animated {
//  PSLogDebug(@"entering");
//  [super viewDidAppear:animated];
//  //  [self animatePeekOfDrawer];
//  PSLogDebug(@"exiting");
//}

-(void)setDrawerDockingEdge:(CGRectEdge)drawerDockingEdge
{
  _drawerDockingEdge = drawerDockingEdge;
  self.drawerTabView.connectedEdge = drawerDockingEdge;
}

#pragma mark drawer layout logic

/**
 Computes the frame for drawerContainer when properly docked against the edge.

 Computes the frame using the current valueof self.drawerDockingEdge and of
 self.drawerContainerView.superview.
 
 The preferred width is defined by DRAWER_WIDTH_WHEN_VERTICAL.
 */
- (CGRect)dockedDrawerContainerFrame {
    CGRect newDrawerContainerFrame;
    if (self.drawerDockingEdge == CGRectMinXEdge || self.drawerDockingEdge == CGRectMaxXEdge) {
        newDrawerContainerFrame = CGRectMake(0, 0,
                                             DRAWER_WIDTH_WHEN_VERTICAL,
                                             CGRectGetHeight(self.drawerContainerView.superview.bounds));
    }
    else {
        newDrawerContainerFrame = CGRectMake(0, 0,
                                             CGRectGetWidth(self.drawerContainerView.superview.bounds),
                                             DRAWER_HEIGHT_WHEN_HORIZONTAL);
    }
    newDrawerContainerFrame = [DrawerViewController alignFrame:newDrawerContainerFrame
                                                        toEdge:self.drawerDockingEdge
                                                  withinBounds:self.drawerContainerView.superview.bounds];
    return newDrawerContainerFrame;
}

/** Layouts out only the drawerContainer, not its subviews.

 */
-(void)layoutDrawerContainerOnly {
  PSLogDebug(@"");
  self.drawerContainerView.frame = [self dockedDrawerContainerFrame];
}

/** Align a frame against inner edge of a bounds.
 
 @param containedFrame frame to align within bounds
 @param dockingEdge edge against which to align
 @param containingBounds bounds within which to align the frame
 @return new value for the aligned frame
 */
+(CGRect)alignFrame:(CGRect)containedFrame toEdge:(CGRectEdge)dockingEdge withinBounds:(CGRect)containingBounds
{
  if (dockingEdge == CGRectMinXEdge) {
    containedFrame = CGRectOffset(containedFrame, -1 * CGRectGetMinX(containedFrame), 0);
  }
  else if (dockingEdge == CGRectMaxXEdge) {
    containedFrame = CGRectOffset(containedFrame,
                                  CGRectGetMaxX(containingBounds) - CGRectGetMaxX(containedFrame), 0);
  }
  else if (dockingEdge == CGRectMinYEdge) {
    containedFrame = CGRectOffset(containedFrame, 0, -1 * CGRectGetMinY(containedFrame));
  }
  else if (dockingEdge == CGRectMaxYEdge) {
    containedFrame = CGRectOffset(containedFrame,
                                  0, CGRectGetMaxY(containingBounds) - CGRectGetMaxY(containedFrame));
  }
  return containedFrame;
}

/** Lays out the drawer, as open. 
 
 
 */
-(void)layoutSubviewsOfDrawerContainer
{
  PSLogDebug(@"");
  // lays out drawerView, drawerBackgroundView, drawerWebView, drawerButton based on drawerContainerView
  
  // assert: drawerContainerView has one edge aligned with the edge of its superview
  // (which should be true if layoutDrawerContainerAgainstDockingEdge was called)
  // [self isDrawerContainerDockingEdgeAligned];

  self.drawerView.frame = self.drawerContainerView.bounds;
  [self layoutSubviewsOfDrawerView];
}

/**
 Checks if the drawer container is properly aligned to edge, that is, docked.
 */
-(BOOL)isDrawerContainerDockingEdgeAligned {
  BOOL result = YES;
  switch (self.drawerDockingEdge) {
    case CGRectMinXEdge:
      if (! (CGRectGetMinX(self.drawerContainerView.frame) == CGRectGetMinX(self.drawerContainerView.superview.bounds) ) )
      { PSLogError(@"drawerContainer not properly left-aligned"); result=NO; }
      break;
    case CGRectMaxXEdge:
      if (! (CGRectGetMaxX(self.drawerContainerView.frame) == CGRectGetMaxX(self.drawerContainerView.superview.bounds) ) )
      { PSLogError(@"drawerContainer not properly right-aligned"); result=NO;  }
      break;
    case CGRectMinYEdge:
      if (! (CGRectGetMinY(self.drawerContainerView.frame) == CGRectGetMinY(self.drawerContainerView.superview.bounds) ) )
		  { PSLogError(@"drawerContainer not properly top-aligned"); result=NO;  }
      break;
    case CGRectMaxYEdge:
		  if (! (CGRectGetMaxY(self.drawerContainerView.frame) == CGRectGetMaxY(self.drawerContainerView.superview.bounds) ) )
      { PSLogError(@"drawerContainer not properly bottom-aligned"); result=NO; }
      break;
  }
  return result;
}

/**
 Lays out the subview of the drawer view.
 
 Lays out the entire view hierarch under the drawer view.
 */
-(void)layoutSubviewsOfDrawerView
{
  // the drawerBackground fills the drawerView, minus the drawerControl
  if (self.drawerDockingEdge == CGRectMaxXEdge) {
    self.drawerBackgroundView.frame = UIEdgeInsetsInsetRect(self.drawerView.bounds, UIEdgeInsetsMake(0, self.drawerTabView.frame.size.width, 0, 0));
  } else if (self.drawerDockingEdge == CGRectMinXEdge) {
    self.drawerBackgroundView.frame = UIEdgeInsetsInsetRect(self.drawerView.bounds, UIEdgeInsetsMake(0, 0, 0, self.drawerTabView.frame.size.width));
  } else if (self.drawerDockingEdge == CGRectMaxYEdge) {
    self.drawerBackgroundView.frame = UIEdgeInsetsInsetRect(self.drawerView.bounds, UIEdgeInsetsMake(self.drawerTabView.frame.size.height,0,0,0));
  } else if (self.drawerDockingEdge == CGRectMinYEdge) {
    self.drawerBackgroundView.frame = UIEdgeInsetsInsetRect(self.drawerView.bounds, UIEdgeInsetsMake(0,0,self.drawerTabView.frame.size.height,0));
  }
  [self roundCornersOfDrawerBackgroundViewIfNeeded];
  
  // layout drawerWebView to have decent insetting from the drawerBackgroundView
  CGFloat const rightContentInsetAppliedByCSS = 5;
  UIEdgeInsets const DRAWER_WEBVIEW_INSETS = UIEdgeInsetsMake(5, 10, 5, 10 - rightContentInsetAppliedByCSS);
  self.drawerWebView.frame = UIEdgeInsetsInsetRect(self.drawerBackgroundView.bounds,
                                                   DRAWER_WEBVIEW_INSETS);
  [self.drawerWebView layoutStartingEndingGradients];
  
  // layout the drawerRedockInfoOverlay
  CGPoint raisedDrawerBGViewCenter = CGPointMake(self.drawerBackgroundView.center.x,
//                                                 CGRectGetHeight(self.drawerBackgroundView.superview.bounds) * (1.0f / 3.0f)
                                                self.drawerBackgroundView.center.y
                                                 );
  self.drawerRedockInfoOverlay.center = [self.drawerRedockInfoOverlay.superview convertPoint:raisedDrawerBGViewCenter
                                                                                    fromView:self.drawerBackgroundView.superview];


  // layout the tabView
  [self layoutTabViewAgainstBackgroundViewAtPosition:self.tabRelativePosition];
}

/**
 Aligns the drawerControl next to the protruding edge of the drawerBackground.
 
 Along this edge, positions the drawer control based on position.
 
 @param controlCenterPositionInUnitCoords float from 0..1, indicating where to put drawerControl along the length of the protruding edge of the drawerBackground
 
 must be called after self.drawerBackgroundView has accurate bounds */
-(void) layoutTabViewAgainstBackgroundViewAtPosition:(CGFloat)controlCenterPositionInUnitCoords
{
  CGFloat centerPosition = (self.drawerDockingEdge == CGRectMaxXEdge || self.drawerDockingEdge == CGRectMinXEdge) ?
  CGRectGetMinY(self.drawerBackgroundView.frame) + self.drawerTabView.frame.size.height/2 + controlCenterPositionInUnitCoords * (self.drawerBackgroundView.frame.size.height - self.drawerTabView.frame.size.height):
  CGRectGetMinX(self.drawerBackgroundView.frame) + self.drawerTabView.frame.size.width/2 + controlCenterPositionInUnitCoords * (self.drawerBackgroundView.frame.size.width - self.drawerTabView.frame.size.width);
  
  // reposition the show/reveal button based on our orientation
  if (self.drawerDockingEdge == CGRectMaxXEdge) {
    // stick button to left of the drawerBackground
    CGPoint leftSide = CGPointMake(CGRectGetMinX(self.drawerBackgroundView.frame),
                                   centerPosition);
    self.drawerTabView.center = CGPointMake(leftSide.x - self.drawerTabView.frame.size.width/2,
                                            leftSide.y);
  }
  else if (self.drawerDockingEdge==CGRectMinXEdge) {
    // stick button to right of the drawerBackground
    CGPoint rightSide = CGPointMake(CGRectGetMaxX(self.drawerBackgroundView.frame),
                                    centerPosition);
    self.drawerTabView.center = CGPointMake(rightSide.x + self.drawerTabView.frame.size.width/2,
                                            rightSide.y);
  }
  else if (self.drawerDockingEdge==CGRectMaxYEdge) {
    CGPoint topSide = CGPointMake(centerPosition,
                                  CGRectGetMinY(self.drawerBackgroundView.frame));
    self.drawerTabView.center = CGPointMake(topSide.x,
                                            topSide.y - self.drawerTabView.frame.size.height/2);
  }
  else if (self.drawerDockingEdge==CGRectMinYEdge) {
    CGPoint bottomSide = CGPointMake(CGRectGetMidX(self.drawerBackgroundView.frame),
                                     CGRectGetMaxY(self.drawerBackgroundView.frame));
    self.drawerTabView.center = CGPointMake(bottomSide.x,
                                            bottomSide.y + self.drawerTabView.frame.size.height/2);
  }
}

/** must be called after self.drawerBackgroundView has accurate bounds */
-(void)roundCornersOfDrawerBackgroundViewIfNeeded
{
  if (self.drawerCornerRadius > 0) {
    UIRectCorner cornersToRound;
    switch (self.drawerDockingEdge) {
      case CGRectMinXEdge:
        cornersToRound = UIRectCornerTopRight | UIRectCornerBottomRight;
        break;
      case CGRectMaxXEdge:
        cornersToRound = UIRectCornerTopLeft | UIRectCornerBottomLeft;
        break;
      case CGRectMinYEdge:
        cornersToRound = UIRectCornerBottomLeft | UIRectCornerBottomRight;
        break;
      case CGRectMaxYEdge:
        cornersToRound = UIRectCornerTopLeft | UIRectCornerTopRight;
        break;
    }
    
    // cache its place in the VH, so that when we add .mask the .supelayer=nil
    UIView * theDrawerBackgroundView = self.drawerBackgroundView;
    UIView * theDrawerBackgroundViewSuperView = self.drawerBackgroundView.superview;
    NSUInteger vIndex = [[theDrawerBackgroundView.superview subviews] indexOfObject:theDrawerBackgroundView];
    [theDrawerBackgroundView removeFromSuperview];
    
    // define and add the mask
    UIBezierPath * maskPath = [UIBezierPath bezierPathWithRoundedRect:self.drawerBackgroundView.bounds
                                                    byRoundingCorners:cornersToRound
                                                          cornerRadii:CGSizeMake(self.drawerCornerRadius,self.drawerCornerRadius)];
    CAShapeLayer * maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.drawerBackgroundView.layer.bounds;
    maskLayer.path = [maskPath CGPath];
    
    theDrawerBackgroundView.layer.mask = maskLayer;
    theDrawerBackgroundView.layer.masksToBounds = YES;
    
    // restore it in the VH
    [theDrawerBackgroundViewSuperView insertSubview:theDrawerBackgroundView atIndex:vIndex];
    self.drawerBackgroundView = theDrawerBackgroundView;
  }
}

/**
 @brief Animates drawer to open or closed, with or without "shuddering" animation.
 
 If not shuddering, does linear animation to new position in DRAWER_OPEN_ANIMATION_DURATION.
 
 If shuddering, does linear animation to new position at the speed with which it was released.
 This is to simulate the conversation of momentum physics of the user "throwing" the drawer. At
 completion, does a shudder animation taking DRAWER_SHUDDER_ANIMATION_DURATION.
 
 @param openNotClosed whether to open or close the drawer
 @param shuddering whether to do a shudder animation at the end
 @param velocityTowardOpenNotClosedState velocity with which the drawer was released, 
        in the direction of openness.
 So, e.g.,  if we are animating toward closed, and the drawer was released while moving
 toward closed, then this value would be negative.
 
 
 */
-(void)animateDrawerToOpen:(BOOL)openNotClosed
               withShudder:(BOOL)shuddering
      givenReleaseVelocity:(CGFloat)velocityTowardOpenNotClosedState
{
  CGPoint const initialDrawerLayerPosition = self.drawerView.layer.position;
  [self layoutDrawerPositionAsOpen:openNotClosed];
  CGPoint const finalDrawerLayerPosition = self.drawerView.layer.position;
  // assert: model layer is at final position
  if (CGPointEqualToPoint(initialDrawerLayerPosition, finalDrawerLayerPosition)) {
    return;
  }
  
  [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
  // rasterize during the animation for better perf
  BOOL const initialDrawerShouldRasterize = self.drawerView.layer.shouldRasterize;
  self.drawerView.layer.shouldRasterize = YES;
  [CATransaction setCompletionBlock:^{
    self.drawerView.layer.shouldRasterize = initialDrawerShouldRasterize;
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
  }];
  
  CGPoint positionDelta = ALGCGPointSubtract(finalDrawerLayerPosition, initialDrawerLayerPosition);
  CGFloat positionDeltaMagnitude = ALGCGPointMaximumNorm(positionDelta);
  
  // first animation: the linear open/close of the drawer
  CABasicAnimation * translateAnim = [CABasicAnimation animationWithKeyPath:@"position"];
  NSValue * fromValue = [NSValue valueWithCGPoint:initialDrawerLayerPosition];
  NSValue * toValue = [NSValue valueWithCGPoint:finalDrawerLayerPosition];
  translateAnim.fromValue =fromValue;
  translateAnim.toValue   =toValue;
  /** if shuddering, then we animate at the speed with which it was thrown */
  if (shuddering) {
    CGFloat const distanceRemainingToTraverse = positionDeltaMagnitude;
    CGFloat const currentSpeed = fabsf(velocityTowardOpenNotClosedState);
    translateAnim.duration = distanceRemainingToTraverse / currentSpeed;
  }
  else
  {
    translateAnim.duration = DRAWER_OPEN_ANIMATION_DURATION;
  }
  
  // second animation: the shudder
  CABasicAnimation * shudderAnimation;
  if (shuddering) {
    shudderAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    shudderAnimation.fromValue = toValue;
    CGPoint unitVectorToShudderedPosition = ALGCGPointTimes(positionDelta,
                                                            -1.0f / positionDeltaMagnitude);
    CGFloat shudderOffsetMagnitude = DRAWER_SHUDDER_MAGNITUDE;
    CGPoint shudderOffset          = ALGCGPointTimes(unitVectorToShudderedPosition,
                                                     shudderOffsetMagnitude);
    CGPoint shudderedPosition      =  ALGCGPointAdd(finalDrawerLayerPosition, shudderOffset);
    shudderAnimation.toValue = [NSValue valueWithCGPoint:shudderedPosition];
    shudderAnimation.duration = DRAWER_SHUDDER_ANIMATION_DURATION / 2.f;
    shudderAnimation.autoreverses = YES;
    shudderAnimation.beginTime = translateAnim.duration;
  }
  
  CAAnimationGroup * group = [[CAAnimationGroup alloc] init];
  group.animations = [NSArray arrayWithObjects:translateAnim,shudderAnimation, nil];
  group.duration = translateAnim.duration + 2 * shudderAnimation.duration;
  
  [self.drawerView.layer addAnimation:group forKey:@"movement"];
}

/** Opens or closes the drawers, without animation.
 
 Preconditions:
 - you have already layed out the drawerViewContainer, presumably 
 by calling layoutDrawerViewContainerOnly.
 - you have already set the drawerView's size correctly,
 presumably by calling layoutSubviewsOfDrawerContainer. 
 
*/
-(void)layoutDrawerPositionAsOpen:(BOOL)openNotClosed
{
  PSLogDebug(@"");
  self.drawerView.center = openNotClosed ? [self drawerCenterOpen] : [self drawerCenterClosed];
}


#pragma mark drawer open/close controls

/// animates drawer open or closed, without shudder.
-(void)animateDrawerToOppositeState
{
  PSLogDebug(@"");
  [self animateDrawerToOpen:([self isDrawerMostlyOpen]==NO)
                withShudder:NO
       givenReleaseVelocity:0.f
   ];
}

-(void)handlePanOnDrawerButton:(UIPanGestureRecognizer*)panGestureRecognizer
{
  static CGPoint initialDrawerCenter;
  static BOOL initialDrawerShouldRasterize;

  if (self.isDragging) {
    [self handlePanWhileDragging:panGestureRecognizer];
    return;
  }
  
  if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
    initialDrawerCenter = self.drawerView.center;
    self.drawerView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    initialDrawerShouldRasterize =  self.drawerView.layer.shouldRasterize;
    self.drawerView.layer.shouldRasterize = YES;
    PSLogDebug(@"gr began with initialCenterOfTour = %@",NSStringFromCGPoint(initialDrawerCenter));
  }
  else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
    //    PSLogDebug(@"gr changed");

    // how far is the finger from the button its dragging?
    CGPoint const touchPos = [panGestureRecognizer locationOfTouch:(panGestureRecognizer.numberOfTouches) -1
                                                            inView:self.drawerContainerView.superview];
    CGPoint const buttonPos = [self.drawerContainerView.superview convertPoint:self.drawerTabView.center
                                                                      fromView:self.drawerTabView.superview];
    CGPoint fingerDelta = ALGCGPointSubtract(touchPos, buttonPos);
    if (DRAWER_REDOCK_RESTRICT_DRAG_AXIS) {
      fingerDelta = [self translationRestrictedToDockingEdge:fingerDelta];
    }

    CGFloat const fingerDeltaMag = ALGCGPointEuclideanNorm(fingerDelta);
    if (fingerDeltaMag < DRAWER_REDOCK_TEAROFF_DELTA) {
      // less than the tearoff distance, so just slide the drawer
      CGPoint const translationSinceStart = [panGestureRecognizer translationInView:self.drawerView.superview];
      CGPoint const translationSinceStartInAllowedDirection = (self.drawerDockingEdge == CGRectMinXEdge ||
                                                               self.drawerDockingEdge == CGRectMaxXEdge)
      ? CGPointMake(translationSinceStart.x, 0) : CGPointMake(0, translationSinceStart.y);
      CGPoint translatedCenterInAllowedDirection = ALGCGPointAdd(initialDrawerCenter,
                                                                 translationSinceStartInAllowedDirection);
      
      // translate only along allowed direction of drawer motion
      CGPoint const centerWithinAllowedRegion = [self point:translatedCenterInAllowedDirection
                                             forcedIntoRect:[self allowedDrawerCenters]];
      self.drawerView.center = centerWithinAllowedRegion;
    }
    else {
      // above the tearoff distance, so switch to dragging the drawer container as a whole
      [self beginDragDropDockingSession:panGestureRecognizer];
      // animate the catch-up to the finger position, which
      // takes place in the first call to handlePanWhileDragging:
      [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
      [UIView animateWithDuration:DRAWER_REDOCK_TEAROFF_ANIMATION_DURATION
                       animations:^{
                         // translate the drawer so button lies under the finger touch
                         self.drawerContainerView.center = ALGCGPointAdd(self.drawerContainerView.center,
                                                                         fingerDelta);
                       }
                       completion:^(BOOL finished) {
                         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                       }];
    }
  }
  else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded ||
           panGestureRecognizer.state == UIGestureRecognizerStateCancelled) {
    PSLogDebug(@"gr ended or canceled");
    self.drawerView.layer.shouldRasterize = initialDrawerShouldRasterize;
    CGPoint velocity = [panGestureRecognizer velocityInView:self.drawerView.superview];
    [self animateDrawerGivenReleasedVelocity:velocity];
  }
  return;
}

/**
 Animates drawer depending on its position, velocity, and the dockingEdge.
 
 This is for handling case when the drawer was "thrown" -- i.e., released by the user 
 while the user was moving his finger at speed. There is a magic speed called the ESCAPE_SPEED.
 
 cases:
 1. drawer was released with a speed below it
 then it animates to its nearest state without a shudder animation.
 2. drawer was released with a speed above it
 then it animates in the direction it was thrown, ending with a shudder. This might
 cause it to change states, or not, depending on which direction it was thrown.
 */
-(void)animateDrawerGivenReleasedVelocity:(CGPoint)releaseVelocity
{
  CGPoint unitVectorTowardOpen;
  switch (self.drawerDockingEdge) {
    case CGRectMinXEdge:
      unitVectorTowardOpen = CGPointMake(1, 0);
      break;
    case CGRectMaxXEdge:
      unitVectorTowardOpen = CGPointMake(-1, 0);
      break;
    case CGRectMinYEdge:
      unitVectorTowardOpen = CGPointMake(0, 1);
      break;
    case CGRectMaxYEdge:
      unitVectorTowardOpen = CGPointMake(0, -1);
      break;
  }
  
  BOOL const currentStateIsOpen = [self isDrawerMostlyOpen];
  CGPoint const unitVectorTowardOppositeState = ALGCGPointTimes(unitVectorTowardOpen,
                                                                (currentStateIsOpen ? -1.0f : 1.0f));
  
  CGFloat const velocityTowardOppositeState = ALGCGPointInnerProduct(unitVectorTowardOppositeState,
                                                                     releaseVelocity);
  
  // if SPEED is above the escape speed, then shudder
  BOOL const shudderAtFinish = (fabsf(velocityTowardOppositeState) > DRAWER_ESCAPE_SPEED);
  
  // if SPEED is above escape speed AND in direction of new state, then change state
  BOOL const newStateIsChanged = (velocityTowardOppositeState > DRAWER_ESCAPE_SPEED);
  
  BOOL const newStateIsOpen = newStateIsChanged ? (!currentStateIsOpen) : (currentStateIsOpen);
  
  CGFloat const velocityTowardOpenState = ALGCGPointInnerProduct(unitVectorTowardOpen,
                                                                 releaseVelocity);
  [self animateDrawerToOpen:newStateIsOpen
                withShudder:shudderAtFinish
       givenReleaseVelocity:velocityTowardOpenState];
}

/// Animates drawer to open slightly then close, to cue user
-(void) animatePeekOfDrawer
{
  CGPoint const initialDrawerCenter = self.drawerView.center;
  BOOL const initialDrawerShouldRasterize = self.drawerView.layer.shouldRasterize;
  self.drawerView.layer.shouldRasterize = YES;
  CGFloat drawerPeekOpenPosition = DRAWER_PEEK_ANIMATION_DRAWER_POSITION;
  CGPoint drawerCenterPeekOpen = [self drawerCenterForDrawerPosition:drawerPeekOpenPosition];
  
  [UIView animateWithDuration:(PEEK_ANIMATION_DURATION/2)
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^{
                     self.drawerView.center = drawerCenterPeekOpen;
                   }
                   completion:^(BOOL finished) {
                     [UIView animateWithDuration:(PEEK_ANIMATION_DURATION/2)
                                           delay:0.0f
                                         options:UIViewAnimationOptionCurveEaseInOut animations:^{
                                           self.drawerView.center = initialDrawerCenter;
                                         }
                                      completion:^(BOOL finishedAgain) {
                                        self.drawerView.layer.shouldRasterize = initialDrawerShouldRasterize;
                                      }];
                   }];
}

#pragma mark drawer dragging and docking

// ensures long press does not disable panGR
-(BOOL) gestureRecognizer:(UIGestureRecognizer*)grOne
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)grTwo
{
  if([[NSSet setWithObjects:grOne, grTwo,nil] isEqualToSet:
      [NSSet setWithObjects:self.longPressGR, self.panGR,nil]]) {
    PSLogDebug(@"returning YES");
    return YES;
  }
  PSLogDebug(@"returning NO");
  return NO;
}


/**
 Handles long presses on the drawer tab.
 
 These initiate a DnD pickup, which may lead to redocking the
 drawer on a different edge.
 
 All dragging sessions begin with a longpress. Then, some continue to include
 a pan. If it includes a pan, the panGR cleans up after the session. Otherwise,
 the longpressGR cleans up.

 Cleanup is done by calling endDragDropDockingSession
 */
-(void)handleLongPress:(UILongPressGestureRecognizer*)longPressGR
{
  if (longPressGR.state == UIGestureRecognizerStateBegan) {
    PSLogDebug(@"began");
    // long press always initiates a dragging session
    [self beginDragDropDockingSession:nil];
  }
  else if (longPressGR.state == UIGestureRecognizerStateEnded ||
           longPressGR.state == UIGestureRecognizerStateCancelled) {
    PSLogDebug(@"ended or canceled");
    // has this dragging session included a pan?
    // if the panGR is in state "possible" or "failed", then this dragging session ended
    // without any panning, so we need to cleanup here rather than relying on the panGR to do so.
    PSLogDebug(@"panGR.state=%d",self.panGR.state);
    if (self.panGR.state == UIGestureRecognizerStatePossible ||
        self.panGR.state == UIGestureRecognizerStateFailed) {
      PSLogDebug(@"dragging session ended with no panning");
      [self endDragDropDockingSession];
    }
  }
}

/**
 Initiates a drag drop of the drawerContainerView, un-docking it from an edge.
 
 @param panGR pan gesture recognizer reporting the pan gesture
 
 Should be balanced by one call to endDragDropDockingSession.
 */
-(void)beginDragDropDockingSession:(UIPanGestureRecognizer*)panGR {
  PSLogDebug(@"");
  if (self.isDragging==YES) {
    PSLogError(@"internal logic error. was called while already in a dragging session was already "
               @"in effect. Skipping the pickup animation. I expect the program is in a valid state "
               @"but there is probably a problem in the code surrounding the long press and pan "
               @"gesture recognizers");
    return;
  }
  self.isDragging = YES;
  self.lastNearestEdgeWhileDragging = self.drawerDockingEdge;
  // reset the panGR to zero translation, since handlePanWhileDragging
  // relies on its internal translation property to track dragging progress
  // of the drawerContainerView
  [panGR setTranslation:CGPointZero inView:self.drawerContainerView.superview];
  [UIView animateWithDuration:DRAWER_REDOCK_PICKUP_ANIMATION_DURATION
                   animations:^{
                     [self performPickup:YES];
                   }];
  
}

-(void)handlePanWhileDragging:(UIPanGestureRecognizer*)panGestureRecognizer
{
  if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
    // self.lastNearestEdgeWhileDragging has been initialized by beginDragDropDockingSession
  }
  else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
    CGPoint translationSinceLastChange = [panGestureRecognizer translationInView:self.drawerContainerView.superview];
    if (DRAWER_REDOCK_RESTRICT_DRAG_AXIS) {
      translationSinceLastChange = [self translationRestrictedToDockingEdge:translationSinceLastChange];
    }
    CGPoint const translatedCenter = ALGCGPointAdd(self.drawerContainerView.center, translationSinceLastChange);
    self.drawerContainerView.center = translatedCenter;
    [panGestureRecognizer setTranslation:CGPointZero
                                  inView:self.drawerContainerView.superview];
    
    CGPoint const touchPoint = [panGestureRecognizer locationOfTouch:(panGestureRecognizer.numberOfTouches-1)
                                                              inView:self.drawerContainerView.superview];
    CGRectEdge const newNearestEdge = [self dockingEdgeForDropAtPoint:touchPoint
                                                               inView:self.drawerContainerView.superview];
    if (self.lastNearestEdgeWhileDragging != newNearestEdge) {
      PSLogDebug(@"crossing the barrier");
      self.lastNearestEdgeWhileDragging = newNearestEdge;
      // relayout view under the finger
      [UIView animateWithDuration:DRAWER_REDOCK_RECONFIG_ANIMATION_DURATION
       animations:^{
         CGPoint const preFlipDTabCenter = [self.drawerContainerView.superview convertPoint:self.drawerTabView.center
                                                                                   fromView:self.drawerTabView.superview];
         self.drawerDockingEdge = newNearestEdge;
         [self layoutSubviewsOfDrawerContainer];
         // assert: centers now changed.
         CGPoint const postFlipDCVCenter = self.drawerContainerView.center;
         CGPoint const postFlipDTabCenter = [self.drawerContainerView.superview convertPoint:self.drawerTabView.center
                                                                                    fromView:self.drawerTabView.superview];
         
         // we must compute: what new drawerContainerView.center will restore drawerTabView.center ?
         CGPoint tabDelta = ALGCGPointSubtract(preFlipDTabCenter, postFlipDTabCenter);
         CGPoint desiredPostFlipDCVCenter = ALGCGPointAdd(postFlipDCVCenter, tabDelta);
         self.drawerContainerView.center = desiredPostFlipDCVCenter;
      }];
    }
  }
  else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded ||
           panGestureRecognizer.state == UIGestureRecognizerStateCancelled) {
    PSLogDebug(@"gr ended or canceled");
    [self endDragDropDockingSession];
  }
  return;
}


/**
 Ends a drag drop session of the drawerContainerView, re-docking it to an edge.
 */
-(void)endDragDropDockingSession {
  if (self.isDragging == NO) {
    PSLogError(@"internal logic error. was called while not in a dragging session. "
               @"Aborting. The program may be in an invalid state if last time "
               @"I was called with an incorrect value for a parameter. "
               @"There is probably a problem in the code surrounding the long press and pan "
               @"gesture recognizers");
    return;
  }
  self.isDragging = NO;
  
  BOOL const initialShouldRasterize = self.drawerView.layer.shouldRasterize;
  self.drawerView.layer.shouldRasterize = YES;
  [UIView animateWithDuration:DRAWER_REDOCK_ANIMATION_DURATION
                   animations:^{
                     [self performPickup:NO];

                     
                     const BOOL drawerLooksMostlyOpen = [self drawerLooksMostlyOpen];
                     
                     // (we do not need to set the drawerDockingEdge here
                     // because it has already been set within handlePanWhileDragging:
                     // or within handleLongPress:.)
                     [self layoutDrawerContainerOnly];
                     
                     // (we do not need to call [self layoutSubviewsOfDrawerContainer]
                     // because it has already been called within handlePanWhileDragging:
                     // when the drawer was dragged into a new drop region.)
                     
                     BOOL const DRAWER_REDOCK_PREVENT_MIDWAY_REDOCK = YES;
                     if (DRAWER_REDOCK_PREVENT_MIDWAY_REDOCK) {
                       // we force the drawer to open or closed, so it looks tidy
                       [self layoutDrawerPositionAsOpen:drawerLooksMostlyOpen];
                     }
                   }
                   completion:^(BOOL finished) {
                     self.drawerView.layer.shouldRasterize = initialShouldRasterize;
                   }];
}



/**
 Applies pickup/putdown effects to drawer system
 
 This relies on pickup calls being immediately matched by putdown calls, which
 relies on the longPressGR and handlePanGR correctly terminating every DnD
 session only once.
 */
-(void)performPickup:(BOOL)pickupNotPutDown
{
  if ( DRAWER_REDOCK_OVERLAY ) {
    static CGFloat initialBackgroundViewAlpha;
    static CGFloat initialTabViewAlpha;
    static BOOL    initialBackgroundViewOpaque;
    if (pickupNotPutDown) {
      initialBackgroundViewAlpha = self.drawerBackgroundView.alpha;
      initialBackgroundViewOpaque = self.drawerBackgroundView.opaque;
      initialTabViewAlpha = self.drawerTabView.alpha;
      self.drawerBackgroundView.alpha = DRAWER_REDOCK_OVERLAY_DRAWER_ALPHA;
      self.drawerBackgroundView.opaque = NO;
      self.drawerTabView.alpha = DRAWER_REDOCK_OVERLAY_DRAWER_ALPHA;

      self.drawerRedockInfoOverlay.hidden = NO;
    }
    else {
      self.drawerBackgroundView.alpha = initialBackgroundViewAlpha;
      self.drawerBackgroundView.opaque = initialBackgroundViewOpaque;
      self.drawerTabView.alpha = initialTabViewAlpha;
      
      self.drawerRedockInfoOverlay.hidden = YES;
    }
  }
  
  if ( DRAWER_REDOCK_DO_PICKUP_TRANSFORM) {
    UIView * const viewToTransform = self.drawerContainerView;

    static CGAffineTransform initialAffineTransform;
    static CGSize initialShadowOffset;
    static CGFloat initialShadowRadius;
    static CGFloat initialShadowOpacity;
    
    if (pickupNotPutDown) {
      initialAffineTransform = viewToTransform.layer.affineTransform;
      initialShadowOffset =viewToTransform.layer.shadowOffset;
      initialShadowRadius = viewToTransform.layer.shadowRadius;
      initialShadowOpacity = viewToTransform.layer.shadowOpacity;
      
      viewToTransform.layer.affineTransform = CGAffineTransformConcat(initialAffineTransform,
                                                                      CGAffineTransformMakeScale(1.05, 1.05));
      viewToTransform.layer.shadowOffset = CGSizeMake(0, 3);
      viewToTransform.layer.shadowRadius = 5;
      viewToTransform.layer.shadowOpacity = 0.7;
    }
    else
    {
      viewToTransform.layer.affineTransform = initialAffineTransform;
      viewToTransform.layer.shadowOffset = initialShadowOffset;
      viewToTransform.layer.shadowRadius = initialShadowRadius;
      viewToTransform.layer.shadowOpacity = initialShadowOpacity;
    }
    
  }

}

// what edge's drop region contains this this point (in view's coordinates)?
-(CGRectEdge)dockingEdgeForDropAtPoint:(CGPoint)point inView:(UIView*)view {
  CGPoint dropPoint = [view convertPoint:point toView:self.drawerContainerView.superview];

  CGRect screenBounds = [self.drawerContainerView.superview bounds];
  CGRect bottomSide;
  CGRect topSide;
  CGRect leftSide;
  CGRect rightSide;
  
  CGFloat const BOTTOM_DROP_STRIP_HEIGHT = 0;
  
  CGRectDivide(screenBounds, &bottomSide, &topSide, BOTTOM_DROP_STRIP_HEIGHT, CGRectMaxYEdge);
  CGRectDivide(topSide, &leftSide, &rightSide,
               CGRectGetWidth(topSide) / 2.f, CGRectMinXEdge);
  
  if (CGRectContainsPoint(leftSide, dropPoint)) {
    return CGRectMinXEdge;
  }
  else if (CGRectContainsPoint(rightSide, dropPoint)) {
    return CGRectMaxXEdge;
  }
  else if (CGRectContainsPoint(bottomSide, dropPoint)) {
    return CGRectMaxYEdge;
  }
  else {
    return CGRectMinXEdge;
  }

}

#pragma mark layout calculators

// these helpers allow us to manipulate the drawer mostly in terms of open vs closed,
// without knowing its dockingEdge

/// drawerView.center, when it's open
-(CGPoint) drawerCenterOpen {
  return CGPointMake(CGRectGetMidX(self.drawerView.superview.bounds),
                     CGRectGetMidY(self.drawerView.superview.bounds));
}

/// drawerView.center, when it's closed
-(CGPoint) drawerCenterClosed {
  switch (self.drawerDockingEdge) {
    case CGRectMinXEdge:
      return CGPointMake([self drawerCenterOpen].x - self.drawerBackgroundView.bounds.size.width,
                         [self drawerCenterOpen].y);
    case CGRectMaxXEdge:
      return CGPointMake([self drawerCenterOpen].x + self.drawerBackgroundView.bounds.size.width,
                         [self drawerCenterOpen].y);
    case CGRectMinYEdge:
      return CGPointMake([self drawerCenterOpen].x,
                         [self drawerCenterOpen].y - self.drawerBackgroundView.bounds.size.height);
    case CGRectMaxYEdge:
      return CGPointMake([self drawerCenterOpen].x,
                         [self drawerCenterOpen].y + self.drawerBackgroundView.bounds.size.height);
  }
}

/// returns drawer's nearest state, based on its position within drawerContainer.superview
-(BOOL)drawerLooksMostlyOpen
{
  // compute the movement needed to dock drawerContainer
  CGPoint const drawerContainerFrameDeltaToDock= ALGCGPointSubtract([self dockedDrawerContainerFrame].origin,
                                                                    self.drawerContainerView.frame.origin);

  // apply opposite delta vector to the drawerView, to see
  // what would be its center if it maintained its current
  // on-screen position but the drawerContianer was docked
  CGPoint currentDrawerCenterInDockedCoordinates = ALGCGPointSubtract(self.drawerView.center, drawerContainerFrameDeltaToDock);

  // calculate if that is mostly open or closed.
  // pseudoPosition ranges from 0.. infinity.
  // 0.5..infinity ranges from midway to open to over-open
  // 0.1 means either 0.1 away from closed or 0.1 over-closed
  // maybe fix drawerPositionForDrawerCenter so it returns in the range -inf to +inf
  CGFloat const pseudoPosition = [self drawerPositionForDrawerCenter:currentDrawerCenterInDockedCoordinates];

  return (pseudoPosition > 0.5f);
  // compute the drawer position w/r/t/ the drawerContainer once docked
}


/// returns drawer's nearest state, based only on its position within the drawerContainer
-(BOOL)isDrawerMostlyOpen
{
  if( [self drawerPositionForDrawerCenter:self.drawerView.center] > 0.5f ) {
    PSLogDebug(@"tour is mostly open");
    return YES;
  }
  PSLogDebug(@"tour is mostly closed");
  return NO;
}

/// rect describing allowed values for self.drawerView.center
-(CGRect)allowedDrawerCenters{
  switch (self.drawerDockingEdge) {
    case CGRectMinXEdge:
      return CGRectMake([self drawerCenterClosed].x, [self drawerCenterOpen].y, [self drawerCenterOpen].x   - [self drawerCenterClosed].x, 0);
    case CGRectMaxXEdge:
      return CGRectMake([self drawerCenterOpen].x,   [self drawerCenterOpen].y, [self drawerCenterClosed].x - [self drawerCenterOpen].x, 0);
    case CGRectMinYEdge:
      return CGRectMake([self drawerCenterOpen].x,   [self drawerCenterClosed].y, 0, [self drawerCenterOpen].y   - [self drawerCenterClosed].y);
    case CGRectMaxYEdge:
      return CGRectMake([self drawerCenterOpen].x,   [self drawerCenterOpen].y,   0, [self drawerCenterClosed].y - [self drawerCenterOpen].y);
  }
}

/** Returns drawerView.center for a given drawerPosition.
 
 @param pos position ranging from 0 (closed) to 1 (open)
 
 @todo maybe rewrite to range from overclosed to overopen, for
 anticipation and exaggeration animations.
 
 */
-(CGPoint) drawerCenterForDrawerPosition:(CGFloat)pos {
  // closed + maxTranslation == open
  CGPoint closed = [self drawerCenterClosed];
  CGPoint open = [self drawerCenterOpen];
  UIOffset maxTranslation = UIOffsetMake(open.x - closed.x, open.y - closed.y);
  return CGPointMake(closed.x + pos * maxTranslation.horizontal, closed.y + pos * maxTranslation.vertical);
}

/** Returns drawerPosition for a given drawerView.center.

 Return value ranges from 0..+infinity.
 0 means exactly closed.
 1 means exactly open.
 >1 means over-open.
 
 A value like 0.1f means either 10% open or else 10% over-closed.

 maybe fix this to return a value ranging -inf to +inf ?
 
 @param drawerCenter a value for drawerView.center
 */
-(CGFloat) drawerPositionForDrawerCenter:(CGPoint)drawerCenter {
  // closed + actualTranslation == drawerCenter
  CGPoint closed = [self drawerCenterClosed];
  CGPoint open = [self drawerCenterOpen];
  UIOffset maxTranslation = UIOffsetMake(open.x - closed.x, open.y - closed.y);
  UIOffset actualTranslation = UIOffsetMake(drawerCenter.x - closed.x, drawerCenter.y - closed.y);
  // assert: actualTranslation is colinear with maxTranslation
  
  // assert: drawerPosition is along the line of allowed motion, which is either horiz or vert,
  // so actualTranslation has a component with value zero, so we can take its magnitude without
  // the pythagorean theroem
  CGFloat maxMagnitude = MAX(fabsf(maxTranslation.horizontal), fabsf(maxTranslation.vertical));
  CGFloat actualMagnitude = MAX(fabsf(actualTranslation.horizontal), fabsf(actualTranslation.vertical));
  
  CGFloat actualAsFractionOfMax = actualMagnitude / maxMagnitude;
  return actualAsFractionOfMax;
}

-(BOOL)isDockingOnXEdge {
  return (self.drawerDockingEdge == CGRectMinXEdge || self.drawerDockingEdge == CGRectMaxXEdge);
}

-(CGPoint) translationRestrictedToDockingEdge:(CGPoint)translation
{
  return [self isDockingOnXEdge] ? CGPointMake(translation.x, 0) : CGPointMake(0, translation.y);
}

/// Returns point forced allowedRegionRect
-(CGPoint)point:(CGPoint)point forcedIntoRect:(CGRect)allowedRegionRect
{
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshadow" // so clang stops moaning about MIN & MAX
  return CGPointMake(MAX(MIN(point.x,
                             CGRectGetMaxX(allowedRegionRect)),
                         CGRectGetMinX(allowedRegionRect)),
                     MAX(MIN(point.y,
                             CGRectGetMaxY(allowedRegionRect)),
                         CGRectGetMinY(allowedRegionRect)));
#pragma clang diagnostic pop
  
}

@end
