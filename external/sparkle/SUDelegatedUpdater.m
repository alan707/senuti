//
//  SUDelegatedUpdater.m
//  Sparkle
//
//  Created by Whitney Young on 8/21/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "SUDelegatedUpdater.h"
#import "SUUnarchiver.h"
#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SUUpdateAlert.h"

@interface SUDelegatedUpdater (PRIVATE)
- (void)abandonUpdate;
@end

@implementation SUDelegatedUpdater

- (id)init {
	return [super init];
}

- (id)initWithDelegate:(id)del {
	if ((self = [super init])) {
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

- (NSString *)appcastURL {
	if ([delegate respondsToSelector:@selector(appcastURLForUpdater:)]) {
		return [delegate appcastURLForUpdater:self];
	} else {
		return [super appcastURL];
	}	
}
- (SUFirstCheckType)firstCheckAction {
	if ([delegate respondsToSelector:@selector(firstCheckActionForUpdater:)]) {
		return [delegate firstCheckActionForUpdater:self];
	} else {
		return [super firstCheckAction];
	}	
}
- (BOOL)automaticallyUpdates {
	if ([delegate respondsToSelector:@selector(automaticallyUpdatesForUpdater:)]) {
		return [delegate automaticallyUpdatesForUpdater:self];
	} else {
		return [super automaticallyUpdates];
	}	
}
- (NSTimeInterval)checkInterval {
	if ([delegate respondsToSelector:@selector(checkIntervalForUpdater:)]) {
		return [delegate checkIntervalForUpdater:self];
	} else {
		return [super checkInterval];
	}	
}
- (NSString *)skippedVersion {
	if ([delegate respondsToSelector:@selector(skippedVersionForUpdater:)]) {
		return [delegate skippedVersionForUpdater:self];
	} else {
		return [super skippedVersion];
	}	
}
- (NSDate *)lastCheck {
	if ([delegate respondsToSelector:@selector(lastCheckForUpdater:)]) {
		return [delegate lastCheckForUpdater:self];
	} else {
		return [super lastCheck];
	}	
}
- (BOOL)shouldCheckAtStartup {
	if ([delegate respondsToSelector:@selector(shouldCheckAtStartupForUpdater:)]) {
		return [delegate shouldCheckAtStartupForUpdater:self];
	} else {
		return [super shouldCheckAtStartup];
	}	
}
- (BOOL)DSAEnabled {
	if ([delegate respondsToSelector:@selector(DSAEnabledForUpdater:)]) {
		return [delegate DSAEnabledForUpdater:self];
	} else {
		return [super DSAEnabled];
	}	
}
- (NSString *)DSAPublicKey {
	if ([delegate respondsToSelector:@selector(DSAPublicKeyForUpdater:)]) {
		return [delegate DSAPublicKeyForUpdater:self];
	} else {
		return [super DSAPublicKey];
	}	
}

- (void)saveSkippedVersion:(NSString *)version {
	if ([delegate respondsToSelector:@selector(saveSkippedVersion:forUpdater:)]) {
		[delegate saveSkippedVersion:version forUpdater:self];
	} else {
		[super saveSkippedVersion:version];
	}	
}
- (void)saveLastCheck:(NSDate *)last {
	if ([delegate respondsToSelector:@selector(saveLastCheck:forUpdater:)]) {
		[delegate saveLastCheck:last forUpdater:self];
	} else {
		[super saveLastCheck:last];
	}	
}
- (void)saveShouldCheckAtStartup:(BOOL)flag {
	if ([delegate respondsToSelector:@selector(saveShouldCheckAtStartup:forUpdater:)]) {
		[delegate saveShouldCheckAtStartup:flag forUpdater:self];
	} else {
		[super saveShouldCheckAtStartup:flag];
	}	
}

@end
