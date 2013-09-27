//
//  ALGViewController.m
//  DrawerViewDemo
//
//  Created by Alexis Gallagher on 2013-09-05.
//  Copyright (c) 2013 Foxtrot Studios. All rights reserved.
//

#import "ALGViewController.h"

#import "DrawerViewController.h"

/**
 This is the view controller that will host the drawer view controller
 as a child view controller.
 */

@interface ALGViewController ()
// html that will be used to populate the child DrawerVC
@property (strong,readonly,nonatomic) NSString * htmlContents;
@end

@implementation ALGViewController

/// Returns an HTML string, used to initialize the DrawerViewController
- (NSString*) htmlContents {
  NSString * const htmlFragment =
  @"<h1>Lorem Tortor Elit</h1>"
  @"<p>Nullam quis risus eget urna mollis ornare vel eu leo. Donec ullamcorper nulla non metus auctor fringilla.</p>"
  @"<p>Curabitur blandit tempus porttitor. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Vestibulum id ligula porta felis euismod semper. Nulla vitae elit libero, a pharetra augue. Cras mattis consectetur purus sit amet fermentum. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Aenean lacinia bibendum nulla sed consectetur.</p>"
  @"<p>Etiam porta sem malesuada magna mollis euismod. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum id ligula porta felis euismod semper. Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Maecenas sed diam eget risus varius blandit sit amet non magna.</p>"
  @"<p>Vestibulum id ligula porta felis euismod semper. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lacinia bibendum nulla sed consectetur. Nullam quis risus eget urna mollis ornare vel eu leo. Nullam quis risus eget urna mollis ornare vel eu leo. Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Vestibulum id ligula porta felis euismod semper.</p>"
  @"<p>Curabitur blandit tempus porttitor. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Vestibulum id ligula porta felis euismod semper. Nulla vitae elit libero, a pharetra augue. Cras mattis consectetur purus sit amet fermentum. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Aenean lacinia bibendum nulla sed consectetur.</p>"
  @"<p>Etiam porta sem malesuada magna mollis euismod. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum id ligula porta felis euismod semper. Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Maecenas sed diam eget risus varius blandit sit amet non magna.</p>"
  ;


  return [NSString stringWithFormat:
          @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\" ?>"
          @"<!DOCTYPE html>"
          @"<html xmlns=\"http://www.w3.org/1999/xhtml\">"
          @"<head>"
          @"<meta name=\"format\" content=\"complete\"/>"
          @"<link rel=\"stylesheet\" href=\"tour.css\" type=\"text/css\"  charset=\"utf-8\">"
          @"</head>"
          @"<body>"
          @"<br/><br/>" // to create space for the close button overlaying the tour
          @"%@"
          @"</body></html>", htmlFragment];
}

- (void)viewDidLoad
{
  PSLogDebug(@"entering");
  [super viewDidLoad];
  
  // create the DrawerVC from the nib
  DrawerViewController * dvc = [[UIStoryboard storyboardWithName:@"DrawerViewScene"
                                                          bundle:[NSBundle mainBundle]]
                                instantiateViewControllerWithIdentifier:@"DrawerViewControllerID"];
  
  // initialize the DrawerVC with its content, an html string
  dvc.drawerHTMLContentString = self.htmlContents;
  
  // initialize the DrawerVC by telling it to dock to the right edge
  dvc.drawerDockingEdge = CGRectMaxXEdge;
  // add the DrawerVC as a child of the current VC
  [self addChildViewController:dvc];
  // trigger the dvc to load its views
  [dvc view];
  // get the dvc's root view, which is the container drawer
  UIView * drawerContainerView = [dvc drawerContainerView];

  // add the dvc's view
  [self.view addSubview:drawerContainerView];
  // tell the dvc it is now a child vc
  [dvc didMoveToParentViewController:self];

  // save the dvc and its view into weak properties on the host vc
  self.drawerViewController = dvc;
  self.childContainerView = drawerContainerView;
  PSLogDebug(@"exiting");
}

-(void)viewWillLayoutSubviews
{
  PSLogDebug(@"entering");
  [super viewWillLayoutSubviews];
  
  // ideally want this to be called only on first-run,
  // since after that the DrawerVC takes care of triggering its own
  // layout events
  [self.drawerViewController layoutDrawerContainerOnly];
  PSLogDebug(@"exiting");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
