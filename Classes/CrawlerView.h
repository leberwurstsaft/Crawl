//
//  CrawlerView.h
//  Crawl2
//
//  Created by Pit Garbe on 18.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Crawl2ViewController;

@interface CrawlerView : UIView <UITextFieldDelegate, UIAlertViewDelegate> {
	//Crawl2ViewController *delegate;
	
	UIImageView *bgView;
	
	UIAlertView *myAlertView;
	UITextView *textView;
	UITextField *urlField;
	UIButton *submitButton;
	
	UIView *visitedBar;
	UIView *toVisitBar;
	UIView *skippedBar;
	
	UISwitch *toggleMode;
	
	UILabel *currentURL;
	UILabel *timeTotal, *timePerDoc, *traffic;
	UILabel *numPDF, *numHTML;
	UILabel *numTerms;
	UILabel *entries;
	
	UIProgressView *progressBar;
}

- (void)disableChanges;
- (void)enableQueries;
- (void)update:(NSMutableDictionary*)data;
- (void)displayResults:(NSString*)result;
- (void)crawl;
- (void)query;

@property (nonatomic, assign) Crawl2ViewController *delegate;
@property (nonatomic, assign) UIProgressView *progressBar;

@end
