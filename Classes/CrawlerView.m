//
//  CrawlerView.m
//  Crawl2
//
//  Created by Pit Garbe on 18.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CrawlerView.h"
#import "Crawl2ViewController.h"

@implementation CrawlerView

@synthesize delegate, progressBar;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
	
		bgView = [[UIImageView alloc] initWithFrame: CGRectMake(0, -20, 768, 1024)];
		bgView.image = [UIImage imageNamed: @"bg"];
		
		textView = [[UITextView alloc] initWithFrame: CGRectMake(50, 240, 668, 714)];
		textView.backgroundColor = [UIColor whiteColor];
		textView.editable = NO;
		textView.maximumZoomScale = 1.0;
		textView.minimumZoomScale = 1.0;
		textView.dataDetectorTypes = UIDataDetectorTypeLink;
		
		currentURL = [[UILabel alloc] initWithFrame: CGRectMake(50, 60, 668, 40)];
		currentURL.backgroundColor = [UIColor clearColor];
		currentURL.adjustsFontSizeToFitWidth = YES;
		
		urlField = [[UITextField alloc] initWithFrame: CGRectMake(50, 10, 400, 32)];
		urlField.placeholder = @"Start-URL";
		urlField.clearButtonMode = UITextFieldViewModeAlways;
		urlField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		urlField.autocorrectionType = UITextAutocorrectionTypeNo;
		urlField.borderStyle = UITextBorderStyleRoundedRect;
		urlField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		urlField.delegate = self;
		urlField.text = @"http://wwwdb.inf.tu-dresden.de";
		
		submitButton = [UIButton buttonWithType: UIButtonTypeCustom];
		submitButton.frame = CGRectMake(460, 10, 183, 32);
		[submitButton setBackgroundImage:[UIImage imageNamed:@"button"] forState:UIControlStateNormal];
		[submitButton setBackgroundImage: [UIImage imageNamed:@"button_pressed"] forState: UIControlStateHighlighted];
		[submitButton setTitle:@"Crawl!" forState: UIControlStateNormal];
		[submitButton addTarget:self action:@selector(crawl) forControlEvents:UIControlEventTouchUpInside];
		
		visitedBar = [[UIView alloc] initWithFrame: CGRectMake(50, 100, 0, 5)];
		visitedBar.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:1.0 alpha:1];
		
		toVisitBar = [[UIView alloc] initWithFrame: CGRectMake(50, 105, 0, 5)];
		toVisitBar.backgroundColor = [UIColor colorWithRed:0.6 green:0 blue:0 alpha:1];

		skippedBar = [[UIView alloc] initWithFrame: CGRectMake(50, 110, 0, 5)];
		skippedBar.backgroundColor = [UIColor lightGrayColor];

		timeTotal = [[UILabel alloc] initWithFrame: CGRectMake(50, 115, 200, 40)];
		timeTotal.backgroundColor = [UIColor clearColor];
		timeTotal.adjustsFontSizeToFitWidth = YES;
		
		timePerDoc = [[UILabel alloc] initWithFrame: CGRectMake(300, 115, 200, 40)];
		timePerDoc.backgroundColor = [UIColor clearColor];
		timePerDoc.adjustsFontSizeToFitWidth = YES;
		
		traffic = [[UILabel alloc] initWithFrame: CGRectMake(550, 115, 200, 40)];
		traffic.backgroundColor = [UIColor clearColor];
		traffic.adjustsFontSizeToFitWidth = YES;

		numTerms = [[UILabel alloc] initWithFrame: CGRectMake(50, 145, 200, 40)];
		numTerms.backgroundColor = [UIColor clearColor];
		numTerms.adjustsFontSizeToFitWidth = YES;

        entries = [[UILabel alloc] initWithFrame: CGRectMake(50, 170, 200, 40)];
		entries.backgroundColor = [UIColor clearColor];
		entries.adjustsFontSizeToFitWidth = YES;

        
		numPDF = [[UILabel alloc] initWithFrame: CGRectMake(300, 145, 200, 40)];
		numPDF.backgroundColor = [UIColor clearColor];
		numPDF.adjustsFontSizeToFitWidth = YES;

		numHTML = [[UILabel alloc] initWithFrame: CGRectMake(550, 145, 200, 40)];
		numHTML.backgroundColor = [UIColor clearColor];
		numHTML.adjustsFontSizeToFitWidth = YES;
		
		timeTotal.textColor = [UIColor lightGrayColor];
		timeTotal.shadowColor = [UIColor blackColor];
		timeTotal.shadowOffset = CGSizeMake(0, -1.0);
		
		timePerDoc.textColor = [UIColor lightGrayColor];
		timePerDoc.shadowColor = [UIColor blackColor];
		timePerDoc.shadowOffset = CGSizeMake(0, -1.0);
		
		traffic.textColor = [UIColor lightGrayColor];
		traffic.shadowColor = [UIColor blackColor];
		traffic.shadowOffset = CGSizeMake(0, -1.0);
		
		numTerms.textColor = [UIColor lightGrayColor];
		numTerms.shadowColor = [UIColor blackColor];
		numTerms.shadowOffset = CGSizeMake(0, -1.0);

        entries.textColor = [UIColor lightGrayColor];
		entries.shadowColor = [UIColor blackColor];
		entries.shadowOffset = CGSizeMake(0, -1.0);
		
        
		numPDF.textColor = [UIColor lightGrayColor];
		numPDF.shadowColor = [UIColor blackColor];
		numPDF.shadowOffset = CGSizeMake(0, -1.0);
		
		numHTML.textColor = [UIColor lightGrayColor];
		numHTML.shadowColor = [UIColor blackColor];
		numHTML.shadowOffset = CGSizeMake(0, -1.0);
		
		currentURL.textColor = [UIColor lightGrayColor];
		currentURL.shadowColor = [UIColor blackColor];
		currentURL.shadowOffset = CGSizeMake(0, -1.0);

		
		progressBar = [[UIProgressView alloc] initWithFrame: CGRectMake(50, 205, 668, 20)];
		progressBar.progress = 0.0;
		progressBar.progressViewStyle = UIProgressViewStyleBar;
		
		[self addSubview: bgView];
		
		[self addSubview: urlField];
		[self addSubview: submitButton];
		[self addSubview: textView];
		[self addSubview: currentURL];
		
		[self addSubview: visitedBar];
		[self addSubview: toVisitBar];
		[self addSubview: skippedBar];
		
		[self addSubview: timeTotal];
		[self addSubview: timePerDoc];
		[self addSubview: traffic];
		[self addSubview: numTerms];
		[self addSubview: numPDF];
		[self addSubview: numHTML];
        [self addSubview: entries];
		
		[self addSubview: progressBar];
		
		
        // Initialization code
    }
    return self;
}

- (void)disableChanges {
	urlField.enabled = NO;
	submitButton.enabled = NO;	 
}

- (void)enableQueries {
	NSLog(@"enable queries");
	urlField.placeholder = @"Abfrage (Leerzeichen als Separator)";
	urlField.text = @"";
	urlField.enabled = YES;
	
	[submitButton setTitle:@"Query!" forState:UIControlStateNormal];
	[submitButton removeTarget:self action:@selector(crawl) forControlEvents:UIControlEventTouchUpInside];
	[submitButton addTarget:self action:@selector(query) forControlEvents:UIControlEventTouchUpInside];
	submitButton.enabled = YES;
	
	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == urlField) {
		[textField resignFirstResponder];
		[submitButton sendActionsForControlEvents:UIControlEventTouchUpInside];
	}
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	if  (textField == urlField) {
		if ([[textField text] length] == 0 && [submitButton.titleLabel.text isEqualToString:@"Crawl!"]) {
			[textField setText: @"http://"];
		}
	}
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	if (textField == urlField) {
		[textField becomeFirstResponder];
		[textField setText: @"http://thtouch.leberwurstsaft.de"];
	}
	return NO;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	[urlField setText: @"http://"];
	[urlField becomeFirstResponder];
	[alertView release];
}

- (void)crawl {
	if ([[urlField text] length] > 0) {
		[delegate crawl: [urlField text]];
	}
	else {
		myAlertView = [[UIAlertView alloc] init];
		myAlertView.delegate = self;
		myAlertView.title = @"Alarm!!!]";
		[myAlertView setMessage: @"Da fehlt eine URL..."];
		[myAlertView addButtonWithTitle: @"OK, na gut."];
		[myAlertView show];
	}
}

- (void)query {
	if ([[urlField text] length] > 0) {
		[delegate query: [urlField text]];
	}
	else {
		myAlertView = [[UIAlertView alloc] init];
		myAlertView.delegate = self;
		myAlertView.title = @"Alarm!!!]";
		[myAlertView setMessage: @"Da fehlt die Query..."];
		[myAlertView addButtonWithTitle: @"OK, na gut."];
		[myAlertView show];
	}

}

- (void)update:(NSMutableDictionary*)data {
	currentURL.text = [data objectForKey:@"url"];
	CGRect rect = visitedBar.frame;
	float newWidth = [[data objectForKey:@"visitedDocuments"] floatValue] / 2.0;
	[visitedBar setFrame: CGRectMake(rect.origin.x, rect.origin.y, newWidth, 5)];
	rect = toVisitBar.frame;
	newWidth = [[data objectForKey:@"documentsToVisit"] floatValue] / 2.0;
	[toVisitBar setFrame: CGRectMake(rect.origin.x, rect.origin.y, newWidth, 5)];
	rect = skippedBar.frame;
	newWidth = [[data objectForKey:@"skippedDocuments"] floatValue] / 2.0;
	[skippedBar setFrame: CGRectMake(rect.origin.x, rect.origin.y, newWidth, 5)];
	
	timeTotal.text = [NSString stringWithFormat:@"%.2f Gesamt",[[data objectForKey:@"crawlTime"] floatValue]];
	timePerDoc.text = [NSString stringWithFormat:@"%.2f s pro Dokument",[[data objectForKey:@"timePerDocument"] floatValue]];
	traffic.text = [[data objectForKey:@"traffic"] humanReadableBase2];
	numPDF.text = [NSString stringWithFormat:@"%d x PDF",[[data objectForKey:@"numberOfPDF"] intValue]];
	numHTML.text = [NSString stringWithFormat:@"%d x HTML",[[data objectForKey:@"numberOfHTML"] intValue]];
	numTerms.text = [NSString stringWithFormat:@"%d Terme",[[data objectForKey:@"numberOfTerms"] intValue]]; 
    entries.text = [NSString stringWithFormat:@"%d Einträge", [[data objectForKey: @"entries"] intValue]];
}

- (void)displayResults:(NSString*)result {
	textView.text = result;
	
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc {

	[textView release];
	[urlField release];
	
	[visitedBar release];;
	[toVisitBar release];
	[skippedBar release];
	
	[currentURL release];
	[timeTotal release];
	[timePerDoc release];
	[traffic release];
	[numTerms release];
	[numPDF release];
	[numHTML release];
	
    [super dealloc];
}


@end
