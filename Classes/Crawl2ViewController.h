//
//  Crawl2ViewController.h
//  Crawl2
//
//  Created by Pit Garbe on 17.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIHTTPRequest.h"

@class CrawlerView;

@interface Crawl2ViewController : UIViewController <ASIHTTPRequestDelegate> {
	CrawlerView *crawlerView;
	
	BOOL currentlyCrawling;
	BOOL indexLoaded;
	
	NSString *entryURL;
	NSDate *startTime;
	
	NSMutableSet *visitedDocuments, *documentsToVisit;
	NSMutableSet *terms, *skippedDocuments;
	NSMutableArray *documentUrls;
	NSMutableDictionary *invertedIndex;
	int numberOfHTML, numberOfPDF;
    int entries;
	
	NSUInteger traffic;
	NSTimeInterval crawlTime;
	NSTimeInterval timePerDocument;
	
	NSMutableString *currentData;
	CGPDFOperatorTableRef table;
	
	BOOL isOldPDF;
}

@property (nonatomic, assign) NSMutableString * currentData;
@property (nonatomic) BOOL isOldPDF;

- (void)crawl:(NSString *)url;
- (void)query:(NSString *)query;
- (void)handleNextUrl;

- (void)updateIndex:(NSCountedSet *)words withDocument:(NSString*)documentUrl;
- (NSCountedSet *)parseHTML:(NSData *)htmlData;
- (NSCountedSet *)parsePDF:(NSData *)pdfData;
- (NSCountedSet *)normalizeWords:(NSCountedSet *)words;

- (void)update:(NSString *)text;

@end