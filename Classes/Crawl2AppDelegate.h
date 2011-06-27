//
//  Crawl2AppDelegate.h
//  Crawl2
//
//  Created by Pit Garbe on 17.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Crawl2ViewController;

@interface Crawl2AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    Crawl2ViewController *viewController;
}

@property (nonatomic, retain)  UIWindow *window;

@property (nonatomic, retain)  Crawl2ViewController *viewController;

@end
