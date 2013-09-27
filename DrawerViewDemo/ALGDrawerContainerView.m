//
//  ALGDrawerContainerView.m
//  DrawerViewDemo
//
//  Created by Alexis Gallagher on 2013-09-25.
//  Copyright (c) 2013 Foxtrot Studios. All rights reserved.
//

#import "ALGDrawerContainerView.h"

#import "DrawerViewController.h"

@implementation ALGDrawerContainerView

/**
 Override normal hit-test logic so only self's subviews swallow events.
 
 This is used for both DrawerContainerView and DrawerView, as both these
 views are transparent containers, which should transparently pass
 touch events through to their non-transparent subviews.
 
 DrawerContainerView is just a container for the drawer
 assembly. We want touch events which fall on this transparent region
 not to be swallowed; they should fall through to the view underneath.
 However, touch events which fall on the visible drawer assembly should be
 received by the assembly's views as usual.
 
 We can't produce this effect by a setting on userInteractionEnabled.
 userInteractionEnabled=YES makes it & assembly swallow all events. bad.
 userInteractionEnabled=NO makes it & assembly swallow none. bad.
 
 We override hitTest:withEvent: in order to override this default logic.
 
 New behavior:
 - if any subview returns a result from hitTest:withEvent:, then we
 return that result. In other words, we state that that subview is the
 "hit-test view". In other words, subviews can still be hit.
 - otherwise, we return nil. In other words, we do NOT state that we
 are teh "hit-test view" just because the event was inside our bounds.
 In other words, we ignore the event. (Default behaviour for this
 otherwise case is to call pointInside:withEvent: and then return self
 if the touch within bounds and nil if out of bounds.)
 */
-(UIView*) hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  UIView * standardHitTestView = [super hitTest:point withEvent:event];
  
  // assert: standardHitTestView =
  //   1. a subview (good. we want subviews to be hittable)
  //   2. self (bad, we don't want to be hittable, since then we block our underview)
  //   3. nil  (good. we don't want this view to claim to be hittable where it's not normally.)
  
  if (standardHitTestView == self) {
    return nil;
  }
  else {
    return standardHitTestView;
  }
}

-(void)layoutSubviews
{
  PSLogDebug(@"entering");
  [super layoutSubviews];

  [self.drawerViewController layoutSubviewsOfDrawerContainer];
  PSLogDebug(@"exiting");
}

@end
