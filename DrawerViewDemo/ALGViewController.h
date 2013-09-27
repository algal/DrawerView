//
//  ALGViewController.h
//  DrawerViewDemo
//
//  Created by Alexis Gallagher on 2013-09-05.
//  Copyright (c) 2013 Foxtrot Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DrawerViewController.h"

@interface ALGViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

#pragma mark - DrawerView

/// the drawer VC
@property (weak,nonatomic) DrawerViewController * drawerViewController;

/// a the drawerVC's root view
@property (weak, nonatomic) UIView  * childContainerView;

/*
 (These properties are weak because the objects are already owned 
 by their parents in VC hierarchy and V hierarchy.)
 */

@end
