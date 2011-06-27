//
//  PDFSearcher.m
//  Crawl2
//
//  Created by Pit Garbe on 20.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PDFSearcher.h"

void arrayCallback(CGPDFScannerRef inScanner, void *userInfo)
{
    PDFSearcher * searcher = (PDFSearcher *)userInfo;
	
    CGPDFArrayRef array;
    
    bool success = CGPDFScannerPopArray(inScanner, &array);
    
    for(size_t n = 0; n < CGPDFArrayGetCount(array); n += 2)
    {
        if(n >= CGPDFArrayGetCount(array))
            continue;
        
        CGPDFStringRef string;
        success = CGPDFArrayGetString(array, n, &string);
        if(success)
        {
            NSString *data = (NSString *)CGPDFStringCopyTextString(string);
            [searcher.currentData appendFormat:@"%@", data];
            [data release];
        }
    }
}

void stringCallback(CGPDFScannerRef inScanner, void *userInfo)
{
    PDFSearcher *searcher = (PDFSearcher *)userInfo;
    
    CGPDFStringRef string;
    
    bool success = CGPDFScannerPopString(inScanner, &string);
	
    if(success)
    {
        NSString *data = (NSString *)CGPDFStringCopyTextString(string);
        [searcher.currentData appendFormat:@" %@", data];
        [data release];
    }
}

@implementation PDFSearcher

- (id)init
{
    if(self = [super init])
    {
        table = CGPDFOperatorTableCreate();
        CGPDFOperatorTableSetCallback(table, "TJ", arrayCallback);
        CGPDFOperatorTableSetCallback(table, "Tj", stringCallback);
    }
    return self;
}

- (BOOL)page:(CGPDFPageRef)inPage containsString:(NSString *)inSearchString;

{
    [self setCurrentData:[NSMutableString string]];
    CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(inPage);
    CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, table, self);
    bool ret = CGPDFScannerScan(scanner);
    CGPDFScannerRelease(scanner);
    CGPDFContentStreamRelease(contentStream);
    return ([[currentData uppercaseString] 
			 rangeOfString:[inSearchString uppercaseString]].location != NSNotFound);
}


@end
