//
// KFCompletingTextFormatter.m
// KFCompletingTextFormatter v. 1.0, 8/22, 2003
//
// Copyright (c) 2003 Ken Ferry. Some rights reserved.
// http://homepage.mac.com/kenferry/software.html
//
// This work is licensed under a Creative Commons license:
// http://creativecommons.org/licenses/by-nc/1.0/
//
// Send me an email if you have any problems (after you've read what there is to read).

#import "FSAutocompleteFormatter.h"

@implementation FSAutocompleteFormatter

-init
{
    if (self = [super init])
    {
        [self setCommaDelimited:NO];
        [self setCompletionMarkingAttributes:nil];
    }
    return(self);
}

- (void)dealloc
{
    [kfCompletionMarkingAttributes release];
    [super dealloc];
}

- (NSString *)stringForObjectValue:(id)anObject
{
    return([anObject description]);
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes
{
    NSString *baseString = [self stringForObjectValue:anObject];
    NSMutableAttributedString *result =
        [[[NSMutableAttributedString alloc] initWithString:baseString
                                                attributes:attributes]
            autorelease];

    if (kfCompletionMarkingAttributes)
    {
        NSMutableArray *components;
        NSRange  *componentRanges;
        NSString *component;
        NSRange componentRange;
        int i;

        if (kfCommaDelimited)
        {
            NSArray *componentsWithWhitespace = [baseString componentsSeparatedByString:@","];
            NSRange unscannedPortion;

            unscannedPortion.location = 0;
            unscannedPortion.length = [baseString length];

            components = [NSMutableArray array];
            componentRanges = malloc([componentsWithWhitespace count] * sizeof(NSRange));

            for (i = 0; i < [componentsWithWhitespace count]; i++)
            {
                NSString *componentWithWhitespace = [componentsWithWhitespace objectAtIndex:i];
                component = [NSMutableString stringWithString:componentWithWhitespace];
                CFStringTrimWhitespace((CFMutableStringRef)component);
                [components addObject:component];
                componentRanges[i] = [baseString rangeOfString:component options:0 range:unscannedPortion];

                unscannedPortion.location += [componentWithWhitespace length] + 1; // 1 for the comma
                unscannedPortion.length -= [componentWithWhitespace length] + 1;
            }
        }
        else
        {
            components = [NSArray arrayWithObject:baseString];
            componentRanges = malloc(sizeof(NSRange));
            componentRanges[0] = NSMakeRange(0, [baseString length]);
        }

        for (i = 0; i < [components count]; i++)
        {
            component = [components objectAtIndex:i];
            componentRange = componentRanges[i];

            if ([dataSource isACompletion:component])
            {
                [result addAttributes:kfCompletionMarkingAttributes range:componentRange];
                [result fixAttributesInRange:componentRange];
            }
        }
        free(componentRanges);
    }
    return(result);
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
    *anObject = string;
    return(YES);
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error
{
    NSRange componentRange;
    BOOL madeCompletion = NO;

    // discover the current component range. A component is the part we might be interested in completing:
    // the whole string if we aren't comma delimited, and the region from the insertion point to the next
    // comma in either direction if we are comma delimited.
    if (!kfCommaDelimited)
    {
        // this could use some work - if there is only whitespace after the insertion
        // point then perhaps the component optionally should not include that trailing whitespace
        componentRange.location = 0;
        componentRange.length = [*partialStringPtr length];
    }
    else
    {
        int componentEndInd, componentStartInd;
        NSString *insertionPtOnward, *toInsertionPt;
        NSCharacterSet *forwardStopCharacters  = [NSCharacterSet characterSetWithCharactersInString:@","];
        NSCharacterSet *backwardStopCharacters = forwardStopCharacters;
        NSCharacterSet *rewindCharacters       = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
        NSCharacterSet *fastForwardCharacters  = rewindCharacters;

        // separate into halves of the string broken at proposedSelRangePtr->location,
        // mostly for readability
        insertionPtOnward = [*partialStringPtr substringFromIndex:proposedSelRangePtr->location];
        toInsertionPt     = [*partialStringPtr substringToIndex:proposedSelRangePtr->location];

        // first we find the end of the component
        // first approximation: the next comma after the insertion point
        componentEndInd = [insertionPtOnward rangeOfCharacterFromSet:forwardStopCharacters].location;

        // if we didn't find a comma then the end of the string is the (approximate) end of the component
        if (componentEndInd == NSNotFound)
            componentEndInd = [insertionPtOnward length];

        // we cut off any trailing white space to get the real end of the component
        componentEndInd = [insertionPtOnward rangeOfCharacterFromSet:rewindCharacters
                                                             options:NSBackwardsSearch
                                                               range:NSMakeRange(0,componentEndInd)].location;
        if (componentEndInd == NSNotFound)
            componentEndInd = 0;
        else
            componentEndInd++;

        // now we have to find the beginning of the component
        // first approximation: comma before the insertion point
        componentStartInd = [toInsertionPt rangeOfCharacterFromSet:backwardStopCharacters
                                                           options:NSBackwardsSearch      ].location;

        // if we didn't find a comma, the beginning of the string is the desired index
        // if we did find a comma, we want the component to start with the next char
        if (componentStartInd == NSNotFound)
            componentStartInd = 0;
        else
            componentStartInd++;

        // cut off whitespace in the beginning of the component
        componentStartInd = [toInsertionPt rangeOfCharacterFromSet:fastForwardCharacters
                                                           options:0
                                                             range:NSMakeRange(componentStartInd,
                                                                               [toInsertionPt length]
                                                                               - componentStartInd)  ].location;

        // if we didn't find anything, the component begins at the insertion point.
        if (componentStartInd == NSNotFound)
            componentStartInd = [toInsertionPt length];

        // set the component range
        componentRange.location = componentStartInd;
        componentRange.length   = [toInsertionPt length] - componentStartInd + componentEndInd;
    }
    // we now have the component range

    // we complete if we're at the end of the current component and the user didn't just
    // backspace
    if (origSelRange.location < proposedSelRangePtr->location &&
        proposedSelRangePtr->location == componentRange.location + componentRange.length)
    {
        NSString *component, *completedComponent;
        NSMutableString *outputString;

        component = [*partialStringPtr substringWithRange:componentRange];

        // ask for a completion. If we can't get one we can just go; we're not going to mark a completion anyway
        if (!(completedComponent = [dataSource completionForPrefix:component]))
        {
            return YES;
        }

        // replace the affected range in the partial string
        outputString = [NSMutableString stringWithString:*partialStringPtr];
        [outputString replaceCharactersInRange:componentRange withString:completedComponent];
        *partialStringPtr = outputString;

        // compute the  new selected range - it's the newly completed portion of the component.
        proposedSelRangePtr->length = [completedComponent length] - [component length];

        // update the component range to reflect completion
        componentRange.length   = [completedComponent length];

        madeCompletion = YES;
    }

    // Lastly, we check if the current component is exactly a completion.
    // If so we're going to pretend we completed to it.  See next comment for why.
    // Due to what may qualify as a cocoa bug, we replace the partialString with a copy
    // of itself to avoid wacky behavior.
    if (!madeCompletion)
    {
        NSString *componentString = [*partialStringPtr substringWithRange:componentRange];
        if([dataSource isACompletion:componentString])
        {
            *partialStringPtr = [NSString stringWithString:*partialStringPtr];
            madeCompletion = YES;
        }
    }

    // error holds a description of the completed range.  The
    // delegate of the NSControl for which we are the formatter may implement
    // - control:didFailToValidatePartialString:errorDescription:
    // and use the info.
    if (madeCompletion)
        *error = NSStringFromRange(componentRange);
    return(!madeCompletion);
}

// accessors

- (id)dataSource
{
    return dataSource;
}

- (void)setDataSource:(id)inDataSource
{
    dataSource = inDataSource;
}

-(BOOL)commaDelimited
{
    return(kfCommaDelimited);
}

-(void)setCommaDelimited:(BOOL)flag
{
    kfCommaDelimited = flag;
}

- (NSDictionary *)completionMarkingAttributes
{
    return([[kfCompletionMarkingAttributes copy] autorelease]);
}

- (void)setCompletionMarkingAttributes:(NSDictionary *)attributesDictionary
{
    [kfCompletionMarkingAttributes autorelease];
    kfCompletionMarkingAttributes = [attributesDictionary copy];
}

@end
