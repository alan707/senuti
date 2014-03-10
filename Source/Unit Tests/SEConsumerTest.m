/* 
 * Senuti is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "SEConsumerTest.h"
#import "SEConsumer.h"
#import "SEThreadTestMacros.h"

BOOL started;
BOOL finished;
BOOL asleep;
BOOL wake;
BOOL cancel;

@interface Impl : SEConsumer { int count; int scount; }
@property int count; @property int scount;
@end

@protocol C
- (void)setupObject:(Impl *)consumer;
- (BOOL)processObject:(Impl *)consumer;
- (BOOL)shouldProcessObject:(Impl *)consumer;
@end

@implementation Impl
@synthesize count; @synthesize scount;
- (void)setupObject:(id <C>)o { [o setupObject:self]; }
- (BOOL)processObject:(id <C>)o { return [o processObject:self]; }
- (BOOL)shouldProcessObject:(id <C>)o { return [o shouldProcessObject:self]; }
- (void)consumerWillSleep { asleep = TRUE; }
- (void)consumerDidWake { wake = TRUE; }
- (void)willCancel { cancel = TRUE; }
@end


@interface O : NSObject <C> { int should; int process; int setup; }
@property int should; @property int process; @property int setup;
@end
@implementation O
@synthesize should; @synthesize process; @synthesize setup;
// setup object must be called before process object is called
- (void)setupObject:(Impl *)c { if (self.process == 0) { self.setup += ++c.count; } }
// processing must occur after shouldProcessObject and setupObject are called
- (BOOL)processObject:(Impl *)c { if (self.should != 0 && self.setup != 0) { self.process += ++c.count; } return TRUE; }
// should process object must be called before process object is called
- (BOOL)shouldProcessObject:(Impl *)c { if (self.should == 0 && self.process == 0) { self.should -= ++c.scount; } return TRUE; }
@end

@interface A : NSObject <C> { SEConsumer *delegate; }
@property (assign) SEConsumer *delegate;
@end
@implementation A
@synthesize delegate;
- (void)setupObject:(Impl *)c { }
- (BOOL)processObject:(Impl *)c { [delegate abort]; return TRUE; }
- (BOOL)shouldProcessObject:(Impl *)c { return TRUE; }
@end

@interface P : NSObject <C> { SEConsumer *delegate; }
@property (assign) SEConsumer *delegate;
@end
@implementation P
@synthesize delegate;
- (void)setupObject:(Impl *)c { }
- (BOOL)processObject:(Impl *)c { [delegate pause]; return TRUE; }
- (BOOL)shouldProcessObject:(Impl *)c { return TRUE; }
@end

@implementation SEConsumerTest

- (void)testSimpleUse {
	O *o_1 = [[O alloc] init];
	O *o_2 = [[O alloc] init];
	O *o_3 = [[O alloc] init];

	Impl *consumer = [[Impl alloc] initWithDelegate:self];
	[consumer execute];

	[consumer addObjects:[NSArray arrayWithObjects:o_1, o_2, o_3, nil]];
	SERunLoopWait(0.5, started = FALSE; finished = FALSE, started && finished,
				  @"Should have called consumerDidStart: and consumerDidFinish: while adding and processing objects");

	STAssertEquals(o_1.should, -1, @"value not what was expected");
	STAssertEquals(o_2.should, -2, @"value not what was expected");
	STAssertEquals(o_3.should, -3, @"value not what was expected");

	STAssertEquals(o_1.setup, 1, @"value not what was expected");
	STAssertEquals(o_2.setup, 2, @"value not what was expected");
	STAssertEquals(o_3.setup, 3, @"value not what was expected");

	STAssertEquals(o_1.process, 4, @"value not what was expected");
	STAssertEquals(o_2.process, 5, @"value not what was expected");
	STAssertEquals(o_3.process, 6, @"value not what was expected");
}

- (void)testRepeatUse {
	O *o_1 = [[O alloc] init];
	O *o_2 = [[O alloc] init];
	O *o_3 = [[O alloc] init];
	
	Impl *consumer = [[Impl alloc] initWithDelegate:self];
	[consumer execute];
	
	[consumer addObjects:[NSArray arrayWithObjects:o_1, o_2, o_3, o_2, o_1, o_3, o_1, o_2, o_3, nil]];
	SERunLoopWait(0.5, started = FALSE; finished = FALSE, started && finished,
				  @"Should have called consumerDidStart: and consumerDidFinish: while adding and processing objects");
	
	STAssertEquals(o_1.should, -1, @"value not what was expected");
	STAssertEquals(o_2.should, -2, @"value not what was expected");
	STAssertEquals(o_3.should, -3, @"value not what was expected");
	
	STAssertEquals(o_1.setup, 13, @"value not what was expected");
	STAssertEquals(o_2.setup, 14, @"value not what was expected");
	STAssertEquals(o_3.setup, 18, @"value not what was expected");
	
	STAssertEquals(o_1.process, 40, @"value not what was expected");
	STAssertEquals(o_2.process, 41, @"value not what was expected");
	STAssertEquals(o_3.process, 45, @"value not what was expected");
}

- (void)testPauseContinue {
	O *o_1 = [[O alloc] init];
	O *o_2 = [[O alloc] init];
	P *pause = [[P alloc] init];
	O *o_3 = [[O alloc] init];
	
	Impl *consumer = [[Impl alloc] initWithDelegate:self];
	[pause setDelegate:consumer];
	[consumer execute];
	
	[consumer addObjects:[NSArray arrayWithObjects:o_1, o_2, pause, o_3, nil]];
	SERunLoopWait(0.5,, [consumer completedCount] >= 3,
				  @"Should have completed 3 objects before pause");
	
	STAssertEquals(o_1.should, -1, @"value not what was expected");
	STAssertEquals(o_2.should, -2, @"value not what was expected");
	STAssertEquals(o_3.should, -3, @"value not what was expected");
	
	STAssertEquals(o_1.setup, 1, @"value not what was expected");
	STAssertEquals(o_2.setup, 2, @"value not what was expected");
	STAssertEquals(o_3.setup, 3, @"value not what was expected");
	
	STAssertEquals(o_1.process, 4, @"value not what was expected");
	STAssertEquals(o_2.process, 5, @"value not what was expected");
	STAssertEquals(o_3.process, 0, @"value not what was expected");
		
	[consumer continue];
	SERunLoopWait(0.5,, [consumer completedCount] == 0,
				  @"Completed count should drop back to 0 when complete");

	STAssertEquals(o_3.process, 6, @"value not what was expected");
	
	// count's now been reset
	[consumer addObjects:[NSArray arrayWithObjects:o_1, o_2, pause, o_3, nil]];
	SERunLoopWait(0.5,, [consumer completedCount] >= 3,
				  @"Should have completed 3 objects before pause");
	
	STAssertEquals(o_1.should, -1, @"value not what was expected");
	STAssertEquals(o_2.should, -2, @"value not what was expected");
	STAssertEquals(o_3.should, -3, @"value not what was expected");
	
	STAssertEquals(o_1.setup, 1, @"value not what was expected");
	STAssertEquals(o_2.setup, 2, @"value not what was expected");
	STAssertEquals(o_3.setup, 3, @"value not what was expected");
	
	STAssertEquals(o_1.process, 11, @"value not what was expected");
	STAssertEquals(o_2.process, 13, @"value not what was expected");
	STAssertEquals(o_3.process, 6, @"value not what was expected");	

	[consumer addObjects:[NSArray arrayWithObjects:o_1, o_2, pause, o_3, nil]];
	[consumer continue];
	SERunLoopWait(0.5,, [consumer completedCount] >= 7,
				  @"Should have completed 7 objects before pause");

	STAssertEquals(o_3.process, 15, @"value not what was expected");

	STAssertEquals(o_1.should, -1, @"value not what was expected");
	STAssertEquals(o_2.should, -2, @"value not what was expected");
	STAssertEquals(o_3.should, -3, @"value not what was expected");
	
	STAssertEquals(o_1.setup, 1, @"value not what was expected");
	STAssertEquals(o_2.setup, 2, @"value not what was expected");
	STAssertEquals(o_3.setup, 3, @"value not what was expected");
	
	STAssertEquals(o_1.process, 21, @"value not what was expected");
	STAssertEquals(o_2.process, 24, @"value not what was expected");
	STAssertEquals(o_3.process, 15, @"value not what was expected");
	
	[consumer continue];
	SERunLoopWait(0.5,, [consumer completedCount] == 0,
				  @"Completed count should drop back to 0 when complete");

	STAssertEquals(o_3.process, 27, @"value not what was expected");
}


- (void)testAbort {	
	O *o_1 = [[O alloc] init];
	O *o_2 = [[O alloc] init];
	A *aborter = [[A alloc] init];
	O *o_3 = [[O alloc] init];
		
	Impl *consumer = [[Impl alloc] initWithDelegate:self];
	[aborter setDelegate:consumer];
	[consumer execute];
	
	[consumer addObjects:[NSArray arrayWithObjects:o_1, o_2, aborter, o_3, nil]];
	SERunLoopWait(0.5,, [consumer completedCount] >= 3,
				  @"Should have completed 3 objects before abort");
	
	STAssertEquals(o_1.should, -1, @"value not what was expected");
	STAssertEquals(o_2.should, -2, @"value not what was expected");
	STAssertEquals(o_3.should, -3, @"value not what was expected");
	
	STAssertEquals(o_1.setup, 1, @"value not what was expected");
	STAssertEquals(o_2.setup, 2, @"value not what was expected");
	STAssertEquals(o_3.setup, 3, @"value not what was expected");
	
	STAssertEquals(o_1.process, 4, @"value not what was expected");
	STAssertEquals(o_2.process, 5, @"value not what was expected");
	STAssertEquals(o_3.process, 0, @"value not what was expected");
}

- (void)consumerDidStart:(SEConsumer *)consumer { started = TRUE; }
- (void)consumerDidFinish:(SEConsumer *)consumer { finished = TRUE; }

@end
