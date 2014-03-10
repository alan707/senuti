//
//  SUDelegatedExternalUpdater.m
//  Sparkle
//
//  Created by Whitney Young on 8/8/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SUDelegatedExternalUpdater.h"
#import "SUUnarchiver.h"
#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SUUpdateAlert.h"


@interface SUDelegatedExternalUpdater (PRIVATE)
- (void)abandonUpdate;
@end

@implementation SUDelegatedExternalUpdater

- (id)init {
	return [super init];
}

- (id)initWithAppPath:(NSString *)path delegate:(id)del {
	if ((self = [super initWithAppPath:path])) {
		delegate = del;
	}
	return self;
}

- (void)unarchiverDidFinish:(SUUnarchiver *)ua {
	if ([delegate respondsToSelector:@selector(updater:shouldContinueAfterExtractingUpdateAtPath:)] &&
		![delegate updater:self shouldContinueAfterExtractingUpdateAtPath:[self downloadPath]]) {
		// do not continue if the delegate says so
		[self abandonUpdate];
	} else {
		[super unarchiverDidFinish:ua];
	}
}

- (void)downloadDidFinish:(NSURLDownload *)download {
	if ([delegate respondsToSelector:@selector(updater:shouldContinueAfterDownloadingFileToPath:)] &&
		![delegate updater:self shouldContinueAfterDownloadingFileToPath:[self downloadPath]]) {
		// do not continue if the delegate says so
		[self abandonUpdate];
	} else {
		[super downloadDidFinish:download];
	}
}

- (void)appcastDidFinishLoading:(SUAppcast *)ac {
	if ([delegate respondsToSelector:@selector(updater:shouldContinueAfterRecievingVersion:isNew:)] &&
		![delegate updater:self shouldContinueAfterRecievingVersion:[[ac newestItem] fileVersion]
					 isNew:[[self class] compareVersion:[[ac newestItem] fileVersion]
											  toVersion:[self applicationVersion]] == NSOrderedAscending]) {
		// do not continue if the delegate says so
		[self abandonUpdate];
	} else {
		[super appcastDidFinishLoading:ac];
	}
}

- (void)appcastDidFailToLoad:(SUAppcast *)ac
{
	if ([delegate respondsToSelector:@selector(updaterShouldContinueAfterFailingToRecievingVersion:)] &&
		![delegate updaterShouldContinueAfterFailingToRecievingVersion:self]) {
		// do not continue if the delegate says so
		[self abandonUpdate];
	} else {
		[super appcastDidFailToLoad:ac];
	}
}

- (NSString *)titleTextForUpdateAlert:(id)alert {
	if ([delegate respondsToSelector:@selector(titleTextForUpdateAlert:)]) {
		return [delegate titleTextForUpdateAlert:alert];
	} else {
		return [super titleTextForUpdateAlert:alert];
	}
}

- (NSString *)descriptionTextForUpdateAlert:(id)alert {
	if ([delegate respondsToSelector:@selector(descriptionTextForUpdateAlert:)]) {
		return [delegate descriptionTextForUpdateAlert:alert];
	} else {
		return [super descriptionTextForUpdateAlert:alert];
	}
}

- (BOOL)showReleaseNotesForUpdateAlert:(id)alert {
	if ([delegate respondsToSelector:@selector(showReleaseNotesForUpdateAlert:)]) {
		return [delegate showReleaseNotesForUpdateAlert:alert];
	} else {
		return [super showReleaseNotesForUpdateAlert:alert];
	}
}

- (BOOL)allowAutomaticUpdateForUpdateAlert:(id)alert {
	if ([delegate respondsToSelector:@selector(allowAutomaticUpdateForUpdateAlert:)]) {
		return [delegate allowAutomaticUpdateForUpdateAlert:alert];
	} else {
		return [super allowAutomaticUpdateForUpdateAlert:alert];
	}
}

- (BOOL)displayCancelButtonForUpdateAlert:(id)alert {
	if ([delegate respondsToSelector:@selector(displayCancelButtonForUpdateAlert:)]) {
		return [delegate displayCancelButtonForUpdateAlert:alert];
	} else {
		return [super displayCancelButtonForUpdateAlert:alert];
	}
}

@end
