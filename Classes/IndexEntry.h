//
//  IndexEntry.h
//  Crawl2
//
//  Created by Pit Garbe on 12.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IndexEntry : NSObject <NSCoding> {
    int documentID;
    double tf;
}

@property (nonatomic, assign) int documentID;
@property (nonatomic, assign) double tf;

@end
