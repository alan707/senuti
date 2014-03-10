//
//  SUUnarchiver.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/16/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUUnarchiver.h"


@implementation SUUnarchiver

// This method abstracts the types that use a command line tool piping data from stdin.
- (BOOL)_extractArchivePath:archivePath pipingDataToCommand:(NSString *)command serverConnection:(NSConnection *)connection
{
	// Get the file size.
	NSNumber *fs = [[[NSFileManager defaultManager] fileAttributesAtPath:archivePath traverseLink:NO] objectForKey:NSFileSize];
	if (fs == nil) { return NO; }
		
	// Thank you, Allan Odgaard!
	// (who wrote the following extraction alg.)
	
	long current = 0;
	FILE *fp, *cmdFP;
	sig_t oldSigPipeHandler = signal(SIGPIPE, SIG_IGN);
	if ((fp = fopen([archivePath UTF8String], "r")))
	{
		setenv("DESTINATION", [[archivePath stringByDeletingLastPathComponent] UTF8String], 1);
		if ((cmdFP = popen([command cString], "w")))
		{
			char buf[32*1024];
			long len;
			while((len = fread(buf, 1, 32 * 1024, fp)))
			{				
				current += len;
				
				NSEvent *event;
				while((event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES]))
					[NSApp sendEvent:event];
				
				fwrite(buf, 1, len, cmdFP);
				
                // July 2006 Whitney Young (Thread Safety)
				if ([(id)[connection rootProxy] respondsToSelector:@selector(unarchiver:extractedLength:)])
					[(id)[connection rootProxy] unarchiver:self extractedLength:len];
//				if ([delegate respondsToSelector:@selector(unarchiver:extractedLength:)])
//					[delegate unarchiver:self extractedLength:len];
			}
			pclose(cmdFP);
		}
		fclose(fp);
	}	
	signal(SIGPIPE, oldSigPipeHandler);
	return YES;
}

- (BOOL)_extractTAR:(NSString *)archivePath serverConnection:(NSConnection *)connection
{
	return [self _extractArchivePath:archivePath pipingDataToCommand:@"tar -xC \"$DESTINATION\"" serverConnection:connection];
}

- (BOOL)_extractTGZ:(NSString *)archivePath serverConnection:(NSConnection *)connection
{
	return [self _extractArchivePath:archivePath pipingDataToCommand:@"tar -zxC \"$DESTINATION\"" serverConnection:connection];
}

- (BOOL)_extractTBZ:(NSString *)archivePath serverConnection:(NSConnection *)connection
{
	return [self _extractArchivePath:archivePath pipingDataToCommand:@"tar -jxC \"$DESTINATION\"" serverConnection:connection];
}

- (BOOL)_extractZIP:(NSString *)archivePath serverConnection:(NSConnection *)connection
{
	return [self _extractArchivePath:archivePath pipingDataToCommand:@"ditto -x -k - \"$DESTINATION\"" serverConnection:connection];
}

- (BOOL)_extractDMG:(NSString *)archivePath serverConnection:(NSConnection *)connection
{
	sig_t oldSigChildHandler = signal(SIGCHLD, SIG_DFL);
	// First, we internet-enable the volume.
	NSTask *hdiTask = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/env" arguments:[NSArray arrayWithObjects:@"hdiutil", @"internet-enable", @"-quiet", archivePath, nil]];
	[hdiTask waitUntilExit];
	if ([hdiTask terminationStatus] != 0) { return NO; }
	
	// Now, open the volume; it'll extract into its own directory.
	hdiTask = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/env" arguments:[NSArray arrayWithObjects:@"hdiutil", @"attach", @"-idme", @"-noidmereveal", @"-noidmetrash", @"-noverify", @"-nobrowse", @"-noautoopen", @"-quiet", archivePath, nil]];
	[hdiTask waitUntilExit];
	if ([hdiTask terminationStatus] != 0) { return NO; }
	
	signal(SIGCHLD, oldSigChildHandler);
	
	return YES;
}

+ (void)_unarchivePath:(NSArray *)info
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSString *path = [info objectAtIndex:2];
    
    NSConnection *serverConnection = [NSConnection connectionWithReceivePort:[info objectAtIndex:0] sendPort:[info objectAtIndex:1]];
    SUUnarchiver *serverObject = [[self alloc] init];
    
    [serverConnection setRootObject:serverObject];
    
	// This dictionary associates names of methods responsible for extraction with file extensions.
	// The methods take the path of the archive to extract. They return a BOOL indicating whether
	// we should continue with the update; returns NO if an error occurred.
	NSDictionary *commandDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
																   @"_extractTBZ:serverConnection:", @"tbz",
																   @"_extractTGZ:serverConnection:", @"tgz",
																   @"_extractTAR:serverConnection:", @"tar", 
																   @"_extractZIP:serverConnection:", @"zip", 
																   @"_extractDMG:serverConnection:", @"dmg", nil];
	SEL command = NSSelectorFromString([commandDictionary objectForKey:[path pathExtension]]);
	
	BOOL result;
	if (command)
	{
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[serverObject methodSignatureForSelector:command]];
		[invocation setSelector:command];
		[invocation setArgument:&path atIndex:2]; // 0 and 1 are private!
		[invocation setArgument:&serverConnection atIndex:3];
		[invocation invokeWithTarget:serverObject];
		[invocation getReturnValue:&result];
	}
	else
		result = NO;
	
	if (result)
	{
        // July 2006 Whitney Young (Thread Safety)
        if ([(id)[serverConnection rootProxy] respondsToSelector:@selector(unarchiverDidFinish:)])
            [(id)[serverConnection rootProxy] performSelector:@selector(unarchiverDidFinish:) withObject:serverObject];
//		if ([delegate respondsToSelector:@selector(unarchiverDidFinish:)])
//			[delegate performSelector:@selector(unarchiverDidFinish:) withObject:self];
	}
	else
	{
        // July 2006 Whitney Young (Thread Safety)
		if ([(id)[serverConnection rootProxy] respondsToSelector:@selector(unarchiverDidFail:)])
			[(id)[serverConnection rootProxy] performSelector:@selector(unarchiverDidFail:) withObject:serverObject];
//		if ([delegate respondsToSelector:@selector(unarchiverDidFail:)])
//			[delegate performSelector:@selector(unarchiverDidFail:) withObject:self];
	}

    [serverObject release];
	[pool release];
}

// July 2006 Whitney Young (Thread Safety)
// Using distributed objects to ensure that all delegate messages are performed on the main thread
// there might be a simpler way to do this, but this works well, doesn't involve much change
// and should be pretty quick
+ (void)unarchivePath:(NSString *)path delegate:(id)delegate
{
    NSPort *port1 = [NSPort port];
    NSPort *port2 = [NSPort port];
    NSArray *info = nil;
    NSConnection* kitConnection = nil; 
    
    kitConnection = [[NSConnection alloc] initWithReceivePort:port1
                                                     sendPort:port2];
    [kitConnection setRootObject:delegate];
    
    // Ports switched here.
    info = [NSArray arrayWithObjects:port2, port1, path, nil];
    
	//[NSThread detachNewThreadSelector:@selector(_unarchivePath:) toTarget:self withObject:path];
    [NSThread detachNewThreadSelector:@selector(_unarchivePath:) toTarget:self withObject:info];
}

//- (void)setDelegate:del
//{
//	delegate = del;
//}

@end