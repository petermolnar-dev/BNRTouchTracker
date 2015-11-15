//
//  BNRDrawViewController.m
//  TouchTracker
//
//  Created by Peter Molnar on 17/05/2015.
//  Copyright (c) 2015 Peter Molnar. All rights reserved.
//

#import "BNRDrawViewController.h"
#import "BNRDrawView.h"

@interface BNRDrawViewController ()

@end

@implementation BNRDrawViewController

- (void)viewDidLoad {
    self.view = [[BNRDrawView alloc] initWithFrame:CGRectZero];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
