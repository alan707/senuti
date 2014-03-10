//
//  SUSampler.m
//  Sparkle
//
//  Created by Whitney Young on 7/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SUSampler.h"


@implementation SUSampler

- (id)init
{
    [self initWithSamples:4 interval:0.4];
    return self;
}

- (id)initWithSamples:(unsigned)num sampleLength:(float)length
{
    [self initWithSamples:num interval:length / (float)numSamples];
    return self;    
}

- (id)initWithSampleLength:(float)length interval:(float)interval
{
    [self initWithSamples:length / interval interval:interval];
    return self;
}

- (id)initWithSamples:(unsigned)num interval:(float)interval
{
    [super init];
    numSamples = num;
    sampleInterval = interval;
    sampleStartTimes = malloc(sizeof(NSDate *) * numSamples);
    samples = malloc(sizeof(unsigned) * numSamples);
    unsigned int i;
    for (i = 0; i < numSamples; i++)
    {
        sampleStartTimes[i] = nil;
    }        

    [self beginNewSample];
    return self;
}

- (void)dealloc
{
    unsigned int i;
    for (i = 0; i < numSamples; i++)
    {
        [sampleStartTimes[i] release];
    }
    free(sampleStartTimes);
    free(samples);
    [super dealloc];
}

- (void)beginNewSample
{
    [startTime release];
    startTime = [[NSDate date] retain];
    
    currentSample = FALSE;
    unsigned int i;
    for (i = 0; i < numSamples; i++)
    {
        [sampleStartTimes[i] release];
        sampleStartTimes[i] = [[startTime addTimeInterval:-(float)i * (float)sampleInterval] retain];
        samples[i] = 0;
    }
}

- (void)recieveBytes:(unsigned)length
{
    unsigned int i;
    for (i = 0; i < numSamples; i++)
    {
        float difference = [[NSDate date] timeIntervalSinceDate:sampleStartTimes[i]];
        samples[i] += length;
        
        if (difference >= sampleInterval * numSamples)
        {
            currentSample = TRUE;
            currentSampleLength = ([sampleStartTimes[i] earlierDate:startTime]) ? [[NSDate date] timeIntervalSinceDate:startTime] : difference;
            currentSampleBytes = samples[i];
            
            [sampleStartTimes[i] release];
            // need to start at more accurate time
            sampleStartTimes[i] = [[NSDate date] retain];
            samples[i] = 0;
        }
    }    
}

- (BOOL)hasCurrentSample
{
    return currentSample;
}

- (unsigned)bytesInCurrentSample
{
    return currentSampleBytes;
}

- (float)lengthOfCurrentSample
{
    return currentSampleLength;
}

@end
