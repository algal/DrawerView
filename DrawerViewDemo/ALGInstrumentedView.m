//
//  ALGInstrumentedView.m
//  DrawerViewDemo
//
//  Created by Alexis Gallagher on 2013-09-25.
//  Copyright (c) 2013 Foxtrot Studios. All rights reserved.
//

#import "ALGInstrumentedView.h"

@implementation ALGInstrumentedView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)layoutSubviews {
  PSLogDebug(@"entering");
  [super layoutSubviews];
  PSLogDebug(@"exiting");
}

-(void)setBounds:(CGRect)bounds
{
  PSLogDebug(@"entering");
  PSLogDebug(@"setting bounds to: %@",NSStringFromCGRect(bounds));
  [super setBounds:bounds];
  PSLogDebug(@"exiting");
}
@end
