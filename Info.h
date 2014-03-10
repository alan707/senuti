#import "FileProcessingMacros.h"
#import "Source/SEUpdateURLMacros.h"

#ifdef BETA
	#define FEED_URL BETA_UPDATE_CHECK_URL_PLAIN
#else
	#define FEED_URL UPDATE_CHECK_URL_PLAIN
#endif