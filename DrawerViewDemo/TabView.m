//
//  TabView.m
//
//  Created by Alexis Gallagher on 2012-12-12.
//

#import "TabView.h"

#define M_TAU (2 * M_PI) // cf. http://tauday.com/tau-manifesto

@interface TabView ()
@property (assign) BOOL debugMode;
@end

@implementation TabView

-(void)setupWithinInit {
  
  self.opaque = NO;
  self.backgroundColor =nil;
  self.clipsToBounds = NO;
  
  // called from init...:, so we set ivars not props
  _leadingJoinCornerRadius  = 10.f;
  _trailingJoinCornerRadius = 0.f;
  _protrudingCornerRadii = 15.f;
  _fillColor = [UIColor whiteColor];
  // _connectedEdge = CGRectMinXEdge;
  // _connectedEdge = CGRectMaxXEdge;
  _connectedEdge = CGRectMinYEdge;
  // _connectedEdge = CGRectMaxYEdge;
  
  _debugMode = NO;
  
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self setupWithinInit];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self) {
    [self setupWithinInit];
  }
  return self;
}

-(void)setConnectedEdge:(CGRectEdge)connectedEdge
{
  _connectedEdge = connectedEdge;
  [self setNeedsDisplay];
}

/// returns rect in which drawing happens, in own coords.
-(CGRect)drawableRect
{
  // inset by 0.5px to stroke on pixels instead of on pixel boundaries
  //  return CGRectInset(self.bounds, 0.5, 0.5);
  
  // don't inset
  return self.bounds;
}

/** Returns edge insets defining the non-stretchable perimeter.
 
 This edge inseting is applied to drawableRect.
 */
-(UIEdgeInsets)capInsets
{
  return UIEdgeInsetsMake(MAX(self.leadingJoinCornerRadius,self.trailingJoinCornerRadius),
                          self.leadingJoinCornerRadius + self.protrudingCornerRadii,
                          self.protrudingCornerRadii,
                          self.protrudingCornerRadii + self.trailingJoinCornerRadius);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextClearRect(ctx, self.bounds);
  CGContextSaveGState(ctx);
  
  // drawing code is written to draw a down-hanging tab, i.e., a tab
  // where self.connectedEdge = CGRectMinYEdge. If we're drawing another
  // orientation, then we resize the drawableRect and translate & rotate
  // the CTM so the drawn result appears with the desired orientation
  CGRect drawableRect = [self drawableRect];
  if (self.connectedEdge==CGRectMaxXEdge) {
    // if our "top" should actually be drawon on the "right"
    CGContextTranslateCTM(ctx, self.bounds.size.width, 0);
    CGContextRotateCTM(ctx, M_TAU/4);
    
    drawableRect = CGRectMake(drawableRect.origin.x, drawableRect.origin.y,
                              drawableRect.size.height, drawableRect.size.width);
  }
  else if (self.connectedEdge==CGRectMinXEdge) {
    // if tab's "top" should actually be drawn on the view's "left"
    CGContextTranslateCTM(ctx, 0, self.bounds.size.height);
    CGContextRotateCTM(ctx, 3*M_TAU/4);
    
    drawableRect = CGRectMake(drawableRect.origin.x, drawableRect.origin.y,
                              drawableRect.size.height, drawableRect.size.width);
    
  } else if (self.connectedEdge==CGRectMaxYEdge) {
    // if tab's top should be the view's bottom
    CGContextConcatCTM(ctx,CGAffineTransformMake(1, 0, 0, -1, 0, self.bounds.size.height));
  }
  
  CGRect capRect = UIEdgeInsetsInsetRect(drawableRect,[self capInsets]);
  
  CGFloat tabBodyMinX = drawableRect.origin.x + self.leadingJoinCornerRadius;
  CGFloat tabBodyMaxX = drawableRect.origin.x + self.leadingJoinCornerRadius + self.protrudingCornerRadii +  capRect.size.width + self.protrudingCornerRadii;
  
  //// Bezier Drawing
  UIBezierPath* bezierPath = [UIBezierPath bezierPath];
  
  // start at origin
  [bezierPath moveToPoint: drawableRect.origin];
  // turn right heading down
  [bezierPath addArcWithCenter:CGPointMake(drawableRect.origin.x,self.leadingJoinCornerRadius)
                        radius:self.leadingJoinCornerRadius
                    startAngle:(3 * M_PI / 4 ) endAngle:0 clockwise:YES];
  
  // go down the left side
  [bezierPath addLineToPoint:CGPointMake(tabBodyMinX,
                                         CGRectGetMaxY(capRect))];
  
  // turn left to head right
  [bezierPath addArcWithCenter:CGPointMake(CGRectGetMinX(capRect),
                                           CGRectGetMaxY(capRect))
                        radius:self.protrudingCornerRadii
                    startAngle:(M_TAU / 2)  endAngle:(M_TAU / 4) clockwise:NO];
  
  // go right
  [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(capRect),
                                         CGRectGetMaxY(drawableRect))];
  
  // turn left to go up
  [bezierPath addArcWithCenter:CGPointMake(CGRectGetMaxX(capRect),
                                           CGRectGetMaxY(capRect))
                        radius:self.protrudingCornerRadii
                    startAngle:(M_TAU /4) endAngle:0 clockwise:NO];
  
  // travel up
  [bezierPath addLineToPoint:CGPointMake(tabBodyMaxX, CGRectGetMinY(capRect))];
  
  // trun right to go right
  [bezierPath addArcWithCenter:CGPointMake(CGRectGetMaxX(drawableRect),
                                           drawableRect.origin.y + self.trailingJoinCornerRadius)
                        radius:self.trailingJoinCornerRadius
                    startAngle:(M_TAU /2) endAngle:(3 * M_TAU / 4) clockwise:YES];
  
  // close the path with horizontal line going right-to-left
  [bezierPath closePath];
  
  [self.fillColor setFill];
  [bezierPath fill];
  
  /*
   Stroke will fall on pixel cracks if   drawableRect=self.bounds.
   Stroke will fall on pixels if drawableRect=UIEdgeInset(self.bounds,0.5)
   */
  //  [[UIColor blackColor] setStroke];
  //  bezierPath.lineWidth = 1;
  //  [bezierPath stroke];
  
  if (self.debugMode) {
    [[UIColor greenColor] setStroke];
    CGContextStrokeRect(UIGraphicsGetCurrentContext(), capRect);
    [[UIColor redColor] setStroke];
    CGContextStrokeRect(UIGraphicsGetCurrentContext(), drawableRect);
    PSLogDebug(@"stretchableNside=%@",NSStringFromCGRect(capRect));
    PSLogDebug(@"bounds=%@",NSStringFromCGRect(self.bounds));
  }
  
  CGContextRestoreGState(UIGraphicsGetCurrentContext());
}


@end
