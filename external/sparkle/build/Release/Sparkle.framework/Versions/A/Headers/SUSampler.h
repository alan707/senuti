//
//  SUSampler.h
//  Sparkle
//
//  Created by Whitney Young on 7/14/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SUSampler : NSObject {
    NSDate *startTime;
    NSDate **sampleStartTimes;
    unsigned *samples;
    unsigned numSamples;
    float sampleInterval;
    
    BOOL currentSample;
    float currentSampleLength;
    unsigned currentSampleBytes;
}
 
// create a sampler which takes a number of samplers
// each of which will end a certain interval away from each other
- (id)initWithSamples:(unsigned)numSamples interval:(float)interval;
// create a sampler which takes a number of samples
// each of which will last length
- (id)initWithSamples:(unsigned)numSamples sampleLength:(float)length;
// create a sampler which takes samples that each last a cerain
// length and will end a certain interval away from each other
// long sample lengths and short intervals will slow calculations
// down a lot
- (id)initWithSampleLength:(float)length interval:(float)interval;

// allows you to reuse a sampler by starting it over
- (void)beginNewSample;
// tells the sampler that bytes were recieved (now)
- (void)recieveBytes:(unsigned)length;

// the first sample doesn't occur until after
// the first interval has elapsed
- (BOOL)hasCurrentSample;
// get info on the current sample
- (unsigned)bytesInCurrentSample;
- (float)lengthOfCurrentSample;

@end
