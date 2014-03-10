//
// KFCompletingTextFormatter.h
// KFCompletingTextFormatter v. 1.0, 8/22, 2003
//
// Copyright (c) 2003 Ken Ferry. Some rights reserved.
// http://homepage.mac.com/kenferry/software.html
//
// This work is licensed under a Creative Commons license:
// http://creativecommons.org/licenses/by-nc/1.0/
//
// Send me an email if you have any problems (after you've read what there is to read).

#import <Cocoa/Cocoa.h>

// KFCompletionsDataSource informal protocol
@interface NSObject ( KFCompletionsDataSource )

// should return nil if there is no valid completion
- (NSString *)completionForPrefix:(NSString *)prefix;
- (BOOL)isACompletion:(NSString *)aString;

@end

@interface FSAutocompleteFormatter : NSFormatter 
{
    IBOutlet id dataSource;
    
    NSDictionary *kfCompletionMarkingAttributes;	// defaults to nil
    BOOL kfCommaDelimited;				// defaults to NO
}

- (id)dataSource;
- (void)setDataSource:(id)dataSource;
- (BOOL)commaDelimited;
- (void)setCommaDelimited:(BOOL)flag;
- (NSDictionary *)completionMarkingAttributes;
- (void)setCompletionMarkingAttributes:(NSDictionary *)attributesDictionary;

@end
