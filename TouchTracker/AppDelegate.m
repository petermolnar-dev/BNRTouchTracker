//
//  AppDelegate.m
//  TouchTracker
//
//  Created by Peter Molnar on 17/05/2015.
//  Copyright (c) 2015 Peter Molnar. All rights reserved.
//

#import "AppDelegate.h"
#import "BNRDrawViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //    Override for customization app launch
    
    BNRDrawViewController *dvc = [[BNRDrawViewController alloc]init];
    self.window.rootViewController = dvc;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
