//
//  SUExternalUpdater.h
//  Sparkle
//
//  Created by Whitney Young on 8/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SUBaseUpdater.h"

@interface SUExternalUpdater : SUBaseUpdater {
	BOOL firstCheck;
	NSString *appPath;
	NSString *appIdent;
}

- (id)initWithAppPath:(NSString *)path;

@end
