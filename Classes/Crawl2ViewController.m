//
//  Crawl2ViewController.m
//  Crawl2
//
//  Created by Pit Garbe on 17.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Crawl2ViewController.h"
#import "CrawlerView.h"
#import "TFHpple.h"
#import "ASIHTTPRequest.h"
#import "ASIDownloadCache.h"
#import "IndexEntry.h"

void arrayCallback(CGPDFScannerRef inScanner, void *userInfo)
{
	Crawl2ViewController * searcher = (Crawl2ViewController *)userInfo;
    CGPDFArrayRef array;

	bool success = CGPDFScannerPopArray(inScanner, &array);
	
	[searcher.currentData appendString: @" "];

    for(size_t n = 0; n < CGPDFArrayGetCount(array); n += 2)
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        if(n >= CGPDFArrayGetCount(array))
            continue;
        
        CGPDFStringRef string;
        success = CGPDFArrayGetString(array, n, &string);
        if(success)
        {
			NSString *data = (NSString *)CGPDFStringCopyTextString(string);
			NSString *dataTrimmed = [data stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];

			if ([dataTrimmed length] > 0) {

				if ([data length] > [dataTrimmed length]) {
					// es gab leerzeichen!
					// alle leerzeichen abschneiden, direkt ranpappen
					[searcher.currentData appendString: dataTrimmed];
				}
				else {
					// keine leerzeichen
					// eins davor tun, ranpappen
					if (CGPDFArrayGetCount(array) == 1) {
						[searcher.currentData appendFormat:@" %@", dataTrimmed];
					}
					else {
						if (searcher.isOldPDF) {
							[searcher.currentData appendFormat:@" %@", dataTrimmed];
						}
						else {
							[searcher.currentData appendString: dataTrimmed];
						}

					}
				}
			}
			else {
				[searcher.currentData appendString: @" "];
			}

			[data release];
		//	dataTrimmed = nil;
		}
        
        [pool release];

		string = NULL;
	}

	searcher = nil;

}

void stringCallback(CGPDFScannerRef inScanner, void *userInfo)
{
	Crawl2ViewController * searcher = (Crawl2ViewController *)userInfo;
    CGPDFStringRef string;
    
    bool success = CGPDFScannerPopString(inScanner, &string);
	
    if(success)
    {
        NSString *data = (NSString *)CGPDFStringCopyTextString(string);
		NSString *dataTrimmed = [data stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];

		if (![data isEqual: @" "]) {
			int length = [data length];
			if (length > [dataTrimmed length]) {
				// es gab leerzeichen!
				// alle leerzeichen abschneiden, direkt ranpappen
				
				[searcher.currentData appendString: dataTrimmed];
			}
			else {
				// keine leerzeichen
				// eins davor tun, ranpappen
				
				[searcher.currentData appendFormat:@" %@", dataTrimmed];
			}
		}

        [data release];
		dataTrimmed = nil;
		string = NULL;
    }
	searcher = nil;
}

@implementation Crawl2ViewController

@synthesize currentData, isOldPDF;

- (id)init {
	if ((self = [super init])) {
		crawlTime = 0.0;
		timePerDocument = 0.0;
		currentlyCrawling = NO;
        entries = 0;
		
		visitedDocuments = [[NSMutableSet alloc] initWithCapacity:1000];
		documentsToVisit = [[NSMutableSet alloc] initWithCapacity:1000];
		skippedDocuments = [[NSMutableSet alloc] initWithCapacity:1000];
		
		terms = [[NSMutableSet alloc] initWithCapacity:200000];
		
		table = CGPDFOperatorTableCreate();
		traffic = 0;
		isOldPDF = NO;
		CGPDFOperatorTableSetCallback(table, "TJ", arrayCallback);
        CGPDFOperatorTableSetCallback(table, "Tj", stringCallback);
		
		
	
		//[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy: ASICachePermanentlyCacheStoragePolicy];
	}
	return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	UIView *aView = [[UIView alloc] initWithFrame: CGRectMake(0, 20, 768, 1004)];
	
	crawlerView = [[CrawlerView alloc] initWithFrame: CGRectMake(0, 0, 768, 1004)];
	crawlerView.delegate = self;
	
	[aView addSubview: crawlerView];
	
	self.view = aView;
	
	[aView release];
	
}

- (void)viewDidLoad {
	NSLog(@"view did load");
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	if ([fileManager fileExistsAtPath: [NSString stringWithFormat:@"%@/index", documentsDirectory]]) {
		NSString *urlForIndex = [NSKeyedUnarchiver unarchiveObjectWithFile: [NSString stringWithFormat: @"%@/entryurl", documentsDirectory]];
		
		UIAlertView *myAlertView = [[UIAlertView alloc] init];
		myAlertView.delegate = self;
		myAlertView.title = @"Index gefunden";
		[myAlertView setMessage: [NSString stringWithFormat:@"%@ %@", @"Es gibt schon einen Index für", urlForIndex]];
		[myAlertView addButtonWithTitle: @"Abfragen"];
		[myAlertView addButtonWithTitle: @"Neu erstellen"];
		[myAlertView show];
		NSLog(@"index found");
	}
	else {
		invertedIndex = [[NSMutableDictionary alloc] initWithCapacity:100000];
		documentUrls = [[NSMutableArray alloc] initWithCapacity: 1000];
		NSLog(@"no index");
	}
	[fileManager release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	if (buttonIndex == 0) {
		
		NSDictionary *savedData = [NSKeyedUnarchiver unarchiveObjectWithFile: [NSString stringWithFormat: @"%@/index", documentsDirectory]];
		invertedIndex = [[savedData objectForKey:@"index"] retain];
		documentUrls = [[savedData objectForKey:@"documentUrls"] retain];
		indexLoaded = YES;

		
		[crawlerView performSelector:@selector(enableQueries)  withObject:nil afterDelay:0.5];
		[alertView release];
	}
	else if (buttonIndex == 1) {
		[fileManager removeItemAtPath: [NSString stringWithFormat:@"%@/index", [paths objectAtIndex:0]] error: NULL];
		[fileManager removeItemAtPath: [NSString stringWithFormat:@"%@/entryurl", [paths objectAtIndex:0]] error: NULL];

		invertedIndex = [[NSMutableDictionary alloc] initWithCapacity:100000];
		documentUrls = [[NSMutableArray alloc] initWithCapacity:1000];
		indexLoaded = NO;
	}
	
	[fileManager release];
}



- (void)crawl:(NSString *)url {
	[crawlerView disableChanges];
	
	startTime = [[NSDate alloc] init];

	entryURL = url;
	NSLog(@"crawl: %@", url);
	numberOfPDF = 0; numberOfHTML = 0;
	
	[documentsToVisit addObject: url];
	[self handleNextUrl];
}

- (void)query:(NSString *)query {
	
	NSMutableArray *queryTerms = [NSMutableArray array];
	
	for (NSString *word in [query componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
		NSString *normalizedWord = [[[[word decomposedStringWithCanonicalMapping] componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""] lowercaseString];
		if ([normalizedWord length] > 3) {
			[queryTerms addObject: normalizedWord];
		}
	}
	
	NSMutableDictionary *documentsForQuery = [NSMutableDictionary dictionary];
	
	for (NSString *term in queryTerms) {
        IndexEntry *entry;
		for (entry in [invertedIndex objectForKey: term]) {
			int docId = entry.documentID;
			double newRank = entry.tf;
			double oldRank = 0;

			// document already exists in documentsForQuery
			if ([documentsForQuery objectForKey: [NSNumber numberWithInt: docId]]) {
				oldRank = [[documentsForQuery objectForKey: [NSNumber numberWithInt: docId]] doubleValue];
			}
			
			[documentsForQuery setObject: [NSNumber numberWithDouble: (oldRank + newRank)] forKey: [NSNumber numberWithInt: docId]];
		}
	}
	
	NSMutableString *queryResult = [NSMutableString string];
	
	[queryResult appendFormat: @"Abfrage: %@\n\n", query];

	NSArray *sortedDocuments = [[documentsForQuery allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [[documentsForQuery objectForKey: obj2] compare: [documentsForQuery objectForKey: obj1]];
	}];
	
    for (NSNumber *documentNumber in sortedDocuments) {

		[queryResult appendFormat:@"%f  %@\n", [[documentsForQuery objectForKey: documentNumber] floatValue], [documentUrls objectAtIndex: [documentNumber intValue]]];
	}
	
	[crawlerView displayResults: queryResult];
}

- (void)handleNextUrl {

	NSString *nextURL = @"";
	NSString *nextURLLowercase = @"";
	if ([documentsToVisit count] > 0) {
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		nextURL = [documentsToVisit anyObject];
		nextURLLowercase = [nextURL lowercaseString];
		
		[self update: nextURL];

		
		[visitedDocuments addObject: nextURL];
		[documentsToVisit minusSet: visitedDocuments];
		
		if ([nextURLLowercase hasSuffix: @"tar"]
			 || [nextURLLowercase hasSuffix: @"tar.gz"]
			 || [nextURLLowercase hasSuffix: @"bz2"]
			 || [nextURLLowercase hasSuffix: @"gz"]
			 || [nextURLLowercase hasSuffix: @"jar"]
			 || [nextURLLowercase hasSuffix: @"zip"]
			 || [nextURLLowercase hasSuffix: @"7z"]
			 || [nextURLLowercase hasSuffix: @"rar"]
			 || [nextURLLowercase hasSuffix: @"avi"]
			 || [nextURLLowercase hasSuffix: @"mpg"]
			 || [nextURLLowercase hasSuffix: @"png"]
			 || [nextURLLowercase hasSuffix: @"jpeg"]
			 || [nextURLLowercase hasSuffix: @"jpg"]
			 || [nextURLLowercase hasSuffix: @"exe"]
			 || [nextURLLowercase hasSuffix: @"ppt"]
			 || [nextURLLowercase hasSuffix: @"pptx"]
			 || [nextURLLowercase hasSuffix: @"mdb"]
			 || [nextURLLowercase hasSuffix: @"txt"]
			 || [nextURLLowercase hasSuffix: @"ps"]
			 || [nextURLLowercase hasSuffix: @"ppt"]
			 || [nextURLLowercase hasSuffix: @"pptx"]
			 || [nextURLLowercase hasSuffix: @"xml"]
			 || [nextURLLowercase hasSuffix: @"java"]
			 || [nextURL isEqualToString:@"http://wwwdb.inf.tu-dresden.de/team"]
			 || ([nextURL rangeOfString:@".rss"].location != NSNotFound)
			) {
			// potentially big file, has no text anyway, disregard (OR: rss file, there are issues...)
			[skippedDocuments addObject: nextURL];
			[self handleNextUrl];
		}
		else {
		
			NSString *type;
			if ([nextURLLowercase hasSuffix: @"pdf"]) {
				type = @"pdf";
			}
			else {
				type = @"html";
			}

			//NSLog(@"next URL: %@", nextURL);
			ASIHTTPRequest *myRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString: [nextURL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]];
			
			[myRequest setDelegate:self];

			[myRequest setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
								  type, @"type",
								  [NSDate date], @"start",
								  nil]];
				 
			[myRequest setDidFinishSelector:@selector(requestFinished:)];
			[myRequest setDidFailSelector:@selector(requestFailed:)];
			[myRequest setShouldPresentAuthenticationDialog:YES];
			[myRequest setDownloadCache:[ASIDownloadCache sharedCache]];
			[myRequest setCachePolicy: ASIOnlyLoadIfNotCachedCachePolicy];
			[myRequest setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
			[myRequest setSecondsToCache:60*60*24*30];
			[myRequest setDownloadProgressDelegate:crawlerView.progressBar];
			[myRequest setShowAccurateProgress: YES];
							
			[myRequest startAsynchronous];

		}
		crawlTime = [[NSDate date] timeIntervalSinceDate: startTime];
		timePerDocument = crawlTime / [visitedDocuments count];
		[pool release];
	}
	else {
		NSLog(@"fertig");
		[self update:@"Fertig."];
		[self setCurrentData: [NSMutableString string]];
				
		// calculate tf.idf
		
		for (NSMutableArray *documents in [invertedIndex allValues]) {
			for (IndexEntry *entry in documents) {
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                
                double tfidf = entry.tf * log10((double)[invertedIndex count] / (double)[documents count]);
				entry.tf = tfidf;
                
				[pool release];
			}
		}
		NSLog(@"calculated tfidf");
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		
		NSDictionary *dataToSave = [NSDictionary dictionaryWithObjectsAndKeys:
									invertedIndex, @"index",
									documentUrls, @"documentUrls",
									nil];
		BOOL result = [NSKeyedArchiver archiveRootObject: dataToSave toFile: [NSString stringWithFormat:@"%@/index", documentsDirectory]];
		if (result) {
			BOOL res = [NSKeyedArchiver archiveRootObject: entryURL toFile: [NSString stringWithFormat:@"%@/entryurl", documentsDirectory]];

			NSLog(@"written successfully");
			[documentsToVisit removeAllObjects];
			[visitedDocuments removeAllObjects];
			[terms removeAllObjects];
			[skippedDocuments removeAllObjects];
		}
		else {
			NSLog(@"couldn't write");
		}
		
		//[self displayResults];
		[crawlerView enableQueries];
	}
}

- (void)updateIndex:(NSCountedSet *)words withDocument:(NSString*)documentUrl {
	if (words) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        NSCountedSet *myWords = [words mutableCopy];
		double denominator = 0;
		
        id object;
		for (object in myWords) {
			float frequency = (float)[myWords countForObject:object];
			denominator += (frequency * frequency);
		}
		
		denominator = sqrt(denominator);
				
		[documentUrls addObject: documentUrl];
		NSMutableSet *newWords = [NSMutableSet setWithCapacity:[myWords count]];
		[newWords unionSet: myWords];
		[newWords minusSet:terms];
		
        NSString *word =[[NSString alloc] init];
        
		for (word in newWords) {
			if (word != nil) {
				[invertedIndex setObject: [NSMutableArray array] forKey: word];
			}
		}
		
        double tf;
        
		for (word in myWords) {
            entries++;
            tf = [myWords countForObject: word];
            
            IndexEntry *entry = [[IndexEntry alloc] init];
            entry.documentID = [documentUrls count] - 1;
            entry.tf = (tf*tf)/denominator;

			[[invertedIndex objectForKey:word] addObject: entry];

            [entry release];
		}
        [word release];
        
		[terms unionSet: newWords];
        [myWords release];
		[pool release];
	}
	[self performSelector:@selector(handleNextUrl) withObject:nil afterDelay:0];
}

- (void)update:(NSString *)text {
	NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
	
	if (text != nil) {
		[dic setValue:text forKey:@"url"];
		[dic setValue:[NSNumber numberWithInt:[visitedDocuments count]] forKey:@"visitedDocuments"];
		[dic setValue:[NSNumber numberWithInt:[documentsToVisit count]] forKey:@"documentsToVisit"];
		[dic setValue:[NSNumber numberWithInt:[skippedDocuments count]] forKey:@"skippedDocuments"];
        [dic setValue:[NSNumber numberWithInt:entries] forKey: @"entries"];
		[dic setValue:[NSNumber numberWithDouble: crawlTime] forKey:@"crawlTime"];
		[dic setValue:[NSNumber numberWithDouble: timePerDocument] forKey:@"timePerDocument"];
		[dic setValue:[NSNumber numberWithInt: traffic] forKey:@"traffic"];
		[dic setValue:[NSNumber numberWithInt: numberOfHTML] forKey:@"numberOfHTML"];
		[dic setValue:[NSNumber numberWithInt: numberOfPDF] forKey:@"numberOfPDF"];
		[dic setValue:[NSNumber numberWithInt: [terms count]] forKey:@"numberOfTerms"];
	}
	
	[crawlerView update:dic];
	[dic release];
}

- (NSCountedSet *)parseHTML:(NSData *)htmlData {

	NSCountedSet *words = [NSCountedSet setWithCapacity:20000];
	if (!htmlData) {
		NSLog(@"error no htmldata");
	}
	else {
		numberOfHTML++;
		traffic += [htmlData length];
		TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:htmlData];

		NSMutableSet *tempLinks = [NSMutableSet setWithCapacity:50];
		
		// get html title
		TFHppleElement *element;
		NSArray *elements;
		
		elements = [xpathParser search:@"//title"]; // get the page title - this is xpath notation
		if ([elements count] > 0) {
			element = [elements objectAtIndex:0];
			NSString *title = [element content];
			[words addObjectsFromArray: [title componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		}
		elements = [xpathParser search:@"//p"];
		for (element in elements) {
			if ([element content]) {
				[words addObjectsFromArray: [[element content] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			}
		}
		elements = [xpathParser search:@"//a/@href"];
		
		for (element in elements) {
			if ([element content]) {
				NSString *theURL = [element content];
				NSRange h = [theURL rangeOfString:@"#"];
				if (h.location > 0 && h.location < 100000000) {
					theURL = [theURL substringToIndex: h.location];
				}
				if ([theURL hasPrefix: entryURL]
					|| [theURL hasPrefix:@"./"]
					|| [theURL hasPrefix:@"/"]) {
					
					if ([theURL hasPrefix:@"./"]) {
						theURL = [entryURL stringByAppendingString:[theURL substringFromIndex: 1]];
					}
					if ([theURL hasPrefix:@"/"]) {
						theURL = [entryURL stringByAppendingString: theURL];
					}
					[tempLinks addObject: theURL];
				}
			}
		}
		// add found links to "visit list", but remove visited first
		[tempLinks minusSet: visitedDocuments];
		
		NSString *someURL;
		for (someURL in tempLinks) {
			[documentsToVisit addObject: someURL];
		}
		[xpathParser release];
	}
	
	return [self normalizeWords:words];
}

- (NSCountedSet *)parsePDF:(NSData *)pdfData {
	numberOfPDF++;
	CGDataProviderRef provider;

	traffic += [pdfData length];
	provider = CGDataProviderCreateWithCFData((CFDataRef)pdfData);
	
	CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(provider);
	CGDataProviderRelease(provider);
	// get content from PDF
	int k;
	CGPDFPageRef myPage;
	[self setCurrentData: [NSMutableString string]];
	
	int numOfPages = CGPDFDocumentGetNumberOfPages (document);
	int majorVersion, minorVersion;
	
	NSMutableSet *tempLinks = [NSMutableSet setWithCapacity:20];
	NSCountedSet *words = [NSCountedSet setWithCapacity:50000];
	
	CGPDFStringRef string;
    CGPDFDictionaryRef infoDict;
    
    infoDict = CGPDFDocumentGetInfo(document);
    if (CGPDFDictionaryGetString(infoDict, "Title", &string))
	{
		CFStringRef s;
		s = CGPDFStringCopyTextString(string);
		if (s != NULL) {
			//need something in here in case it cant find anything
			[currentData appendString: (NSString *)s];
			CFRelease(s);
		}
		
		if (!([currentData isEqualToString:@""] || currentData == nil)) {
			NSArray *dataSeparated = [currentData componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			[words addObjectsFromArray: dataSeparated];
		}
	}

	
	
	//if (numOfPages >5) numOfPages = 5;
	for (k = 0; k < numOfPages; k++) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[self setCurrentData: [NSMutableString stringWithCapacity:10000000]];
		
		myPage = CGPDFDocumentGetPage (document, k + 1 );
		
		// find links
		CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(myPage);
		CGPDFArrayRef outputArray;
		if (!CGPDFDictionaryGetArray(pageDictionary, "Annots", &outputArray)) {
			int arrayCount = CGPDFArrayGetCount( outputArray );
			if(!arrayCount) {
				for( int j = 0; j < arrayCount; ++j ) {
					CGPDFObjectRef aDictObj;
					if(!CGPDFArrayGetObject(outputArray, j, &aDictObj)) {
						continue;
					}
					
					CGPDFDictionaryRef annotDict;
					if(!CGPDFObjectGetValue(aDictObj, kCGPDFObjectTypeDictionary, &annotDict)) {
						continue;
					}
					
					CGPDFDictionaryRef aDict;
					if(!CGPDFDictionaryGetDictionary(annotDict, "A", &aDict)) {
						continue;
					}
					
					CGPDFStringRef uriStringRef;
					if(!CGPDFDictionaryGetString(aDict, "URI", &uriStringRef)) {
						continue;
					}
					
					char *uriString = (char *)CGPDFStringGetBytePtr(uriStringRef);
					
					NSString *theURL = [NSString stringWithCString:uriString encoding:NSUTF8StringEncoding];
					
					NSRange h = [theURL rangeOfString:@"#"];
					if (h.location > 0 && h.location < 100000000) {
						theURL = [theURL substringToIndex: h.location];
					}
					if ([theURL hasPrefix: entryURL]
						|| [theURL hasPrefix:@"./"]
						|| [theURL hasPrefix:@"/"]) {
						
						if ([theURL hasPrefix:@"./"]) {
							theURL = [entryURL stringByAppendingString:[theURL substringFromIndex: 1]];
						}
						if ([theURL hasPrefix:@"/"]) {
							theURL = [entryURL stringByAppendingString: theURL];
						}
						[tempLinks addObject: theURL];
					}
				}
			}
		}
		
		CGPDFDocumentGetVersion(document, &majorVersion, &minorVersion);
		
		if (majorVersion >= 1 && minorVersion <= 3) {
			self.isOldPDF = YES;
		}
		else if (majorVersion >= 1 && minorVersion > 3) {
			self.isOldPDF = NO;
		}		
		
		CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(myPage);
		CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, table, self);
		CGPDFScannerScan(scanner);
		CGPDFScannerRelease(scanner);
		CGPDFContentStreamRelease(contentStream);
	
		if (!([currentData isEqualToString:@""] || currentData == nil)) {
			NSArray *dataSeparated = [currentData componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			[words addObjectsFromArray: dataSeparated];
		}
				
		[pool drain];
	}

	
	[tempLinks minusSet: visitedDocuments];
	NSString *someURL;
	for (someURL in tempLinks) {
		NSLog(@"added link from pdf: %@", someURL);
		[documentsToVisit addObject: someURL];
	}

	CGPDFDocumentRelease(document);

	return [self normalizeWords: words];
}

- (NSCountedSet *)normalizeWords:(NSCountedSet *)words {
	NSCountedSet *normalizedWords = [NSCountedSet setWithCapacity:[words count]];
	
	for (NSString * word in words) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString *normalizedWord = [[[[[word decomposedStringWithCanonicalMapping] componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""] lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];

		if ([normalizedWord length] > 3) {
			[normalizedWords addObject: normalizedWord];
		}
       // [word release];
		[pool release];
	}
	return normalizedWords;
}


#pragma mark -
#pragma mark ASI Delegate Methods

- (void)requestFinished:(ASIHTTPRequest *)request
{
	NSData *responseData = [request responseData];
	NSString *type = [[request userInfo] objectForKey:@"type"];
	NSString *originalURL = [[request originalURL] absoluteString];
	
	if ([type isEqualToString:@"html"]) {
		[self updateIndex: [self parseHTML:responseData] withDocument: originalURL];
	}
	else if ([type isEqualToString:@"pdf"]) {
		[self updateIndex:[self parsePDF:responseData] withDocument: originalURL];
		//[self handleNextUrl];
	}
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	NSError *error = [request error];
	NSLog(@"error: %@", error);
	NSLog(@"url was: %@", [[request originalURL] absoluteURL]);
	[self handleNextUrl];
}

#pragma mark -

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return NO;
}


- (void)dealloc {
    [super dealloc];
}

@end


@implementation NSNumber (Utilities)

- (NSString *)humanReadableBase10 {
	if (self == nil) return nil;
	
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[formatter setMaximumFractionDigits:1];
	
	NSString *formattedString = nil;
	uint64_t size = [self unsignedLongLongValue];
	if (size < 1000) {
		NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size]];
		formattedString = [NSString stringWithFormat:@"%@ B", formattedNumber];
	}
	else if (size < 1000 * 1000) {
		NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1000.0]];
		formattedString = [NSString stringWithFormat:@"%@ KB", formattedNumber];
	}
	else if (size < 1000 * 1000 * 1000) {
		NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1000.0 / 1000.0]];
		formattedString = [NSString stringWithFormat:@"%@ MB", formattedNumber];
	}
	else {
		NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1000.0 / 1000.0 / 1000.0]];
		formattedString = [NSString stringWithFormat:@"%@ GB", formattedNumber];
	}
	[formatter release];
	
	return formattedString;
}

- (NSString *)humanReadableBase2 {
	if (self == nil)
		return nil;
	
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[formatter setMaximumFractionDigits:1];
	
	NSString *formattedString = nil;
	uint64_t size = [self unsignedLongLongValue];
	if (size < 1024) {
		NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size]];
		formattedString = [NSString stringWithFormat:@"%@ B", formattedNumber];
	}
	else if (size < 1024 * 1024) {
		NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1024.0]];
		formattedString = [NSString stringWithFormat:@"%@ KB", formattedNumber];
	}
	else if (size < 1024 * 1024 * 1024) {
		NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1024.0 / 1024.0]];
		formattedString = [NSString stringWithFormat:@"%@ MB", formattedNumber];
	}
	else {
		NSString *formattedNumber = [formatter stringFromNumber:[NSNumber numberWithFloat:size / 1024.0 / 1024.0 / 1024.0]];
		formattedString = [NSString stringWithFormat:@"%@ GB", formattedNumber];
	}
	[formatter release];
	
	return formattedString;
}

@end