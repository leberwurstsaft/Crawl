//
//  IndexEntry.m
//  Crawl2
//
//  Created by Pit Garbe on 12.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IndexEntry.h"


@implementation IndexEntry

@synthesize documentID, tf;

- (id)init {
    documentID = 0;
    tf = 0;
    
    return self;
}

- (id)initWithCoder: (NSCoder *)decoder {
    documentID  = [decoder decodeIntForKey:@"ID"];
    tf          = [decoder decodeDoubleForKey:@"tf"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:documentID forKey:@"ID"];
    [coder encodeDouble:tf forKey:@"tf"];
}


@end
