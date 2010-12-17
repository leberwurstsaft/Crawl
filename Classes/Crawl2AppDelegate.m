//
//  Crawl2AppDelegate.m
//  Crawl2
//
//  Created by Pit Garbe on 17.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Crawl2AppDelegate.h"

#import "Crawl2ViewController.h"

@implementation Crawl2AppDelegate


@synthesize window;

@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Override point for customization after application launch.
     
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {

    // Save data if appropriate.
}

- (void)dealloc {

    [window release];
    [viewController release];
    [super dealloc];
}

@end
