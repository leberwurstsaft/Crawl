//
//  PDFSearcher.h
//  Crawl2
//
//  Created by Pit Garbe on 20.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDFSearcher : NSObject 
{
    CGPDFOperatorTableRef table;
    NSMutableString *currentData;
}
@property (nonatomic, retain) NSMutableString * currentData;
-(id)init;
-(BOOL)page:(CGPDFPageRef)inPage containsString:(NSString *)inSearchString;
@end
