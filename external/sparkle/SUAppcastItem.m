//
//  SUAppcastItem.m
//  Sparkle
//
//  Created by Andy Matuschak on 3/12/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUAppcastItem.h"


@implementation SUAppcastItem

- initWithDictionary:(NSDictionary *)dict
{
	[super init];
	[self setTitle:[dict objectForKey:@"title"]];
	[self setDate:[dict objectForKey:@"pubDate"]];
	[self setDescription:[dict objectForKey:@"description"]];
	
	id enclosure = [dict objectForKey:@"enclosure"];
	[self setDSASignature:[enclosure objectForKey:@"sparkle:dsaSignature"]];
	[self setMD5Sum:[enclosure objectForKey:@"sparkle:md5Sum"]];
	
	[self setFileURL:[NSURL URLWithString:[[enclosure objectForKey:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	
	// Find the appropriate release notes URL.
	if ([dict objectForKey:@"sparkle:releaseNotesLink"])
	{
		[self setReleaseNotesURL:[NSURL URLWithString:[dict objectForKey:@"sparkle:releaseNotesLink"]]];
	}
	else if ([[self description] hasPrefix:@"http://"]) // if the description starts with http://, use that.
	{
		[self setReleaseNotesURL:[NSURL URLWithString:[self description]]];
	}
	else
	{
		[self setReleaseNotesURL:nil];
	}
	
	// Try to find a version string.
	// Finding the new version number from the RSS feed is a little bit hacky. There are two ways:
	// 1. A "sparkle:version" attribute on the enclosure tag, an extension from the RSS spec.
	// 2. If there isn't a version attribute, Sparkle will parse the path in the enclosure, expecting
	//    that it will look like this: http://something.com/YourApp_0.5.zip. It'll read whatever's between the last
	//    underscore and the last period as the version number. So name your packages like this: APPNAME_VERSION.extension.
	//    The big caveat with this is that you can't have underscores in your version strings, as that'll confuse Sparkle.
	//    Feel free to change the separator string to a hyphen or something more suited to your needs if you like.
	NSString *newVersion = [enclosure objectForKey:@"sparkle:version"];
	if (!newVersion) // no sparkle:version attribute
	{
		// Separate the url by underscores and take the last component, as that'll be closest to the end,
		// then we remove the extension. Hopefully, this will be the version.
		NSArray *fileComponents = [[enclosure objectForKey:@"url"] componentsSeparatedByString:@"_"];
		if ([fileComponents count] > 1)
			newVersion = [[fileComponents lastObject] stringByDeletingPathExtension];
	}
	[self setFileVersion:newVersion];
	
	NSString *shortVersionString = [enclosure objectForKey:@"sparkle:shortVersionString"];
	if (shortVersionString)
	{
		if (![[self fileVersion] isEqualToString:shortVersionString])
			shortVersionString = [shortVersionString stringByAppendingFormat:@"/%@", [self fileVersion]];
		[self setVersionString:shortVersionString];
	}
	else
		[self setVersionString:[self fileVersion]];
	
	return self;
}

// Attack of accessors!

- (NSString *)title { return [[title retain] autorelease]; }

- (void)setTitle:(NSString *)aTitle
{
    if (title != aTitle) // July 2006 Whitney Young (Memory Magement)
    {
        [title release];
        title = [aTitle copy];
    }
}


- (NSDate *)date { return [[date retain] autorelease]; }

- (void)setDate:(NSDate *)aDate
{
    if (date != aDate) // July 2006 Whitney Young (Memory Magement)
    {
        [date release];
        date = [aDate copy];
    }
}


- (NSString *)description { return [[description retain] autorelease]; }

- (void)setDescription:(NSString *)aDescription
{
    if (description != aDescription) // July 2006 Whitney Young (Memory Magement)
    {
        [description release];
        description = [aDescription copy];
    }
}


- (NSURL *)releaseNotesURL { return [[releaseNotesURL retain] autorelease]; }

- (void)setReleaseNotesURL:(NSURL *)aReleaseNotesURL
{
    if (releaseNotesURL != aReleaseNotesURL) // July 2006 Whitney Young (Memory Magement)
    {
        [releaseNotesURL release];
        releaseNotesURL = [aReleaseNotesURL copy];        
    }
}


- (NSString *)DSASignature { return [[DSASignature retain] autorelease]; }

- (void)setDSASignature:(NSString *)aDSASignature
{
    if (DSASignature != aDSASignature) // July 2006 Whitney Young (Memory Magement)
    {
        [DSASignature release];
        DSASignature = [aDSASignature copy];
    }
}


- (NSString *)MD5Sum { return [[MD5Sum retain] autorelease]; }

- (void)setMD5Sum:(NSString *)aMD5Sum
{
    if (MD5Sum != aMD5Sum) // July 2006 Whitney Young (Memory Magement)
    {
        [MD5Sum release];
        MD5Sum = [aMD5Sum copy];
    }
}


- (NSURL *)fileURL { return [[fileURL retain] autorelease]; }

- (void)setFileURL:(NSURL *)aFileURL
{
    if (fileURL != aFileURL) // July 2006 Whitney Young (Memory Magement)
    {
        [fileURL release];
        fileURL = [aFileURL copy];
    }
}


- (NSString *)fileVersion { return [[fileVersion retain] autorelease]; }

- (void)setFileVersion:(NSString *)aFileVersion
{
    if (fileVersion != aFileVersion) // July 2006 Whitney Young (Memory Magement)
    {
        [fileVersion release];
        fileVersion = [aFileVersion copy];
    }
}


- (NSString *)versionString { return [[versionString retain] autorelease]; }

- (void)setVersionString:(NSString *)aVersionString
{
    if (versionString != aVersionString) // July 2006 Whitney Young (Memory Magement)
    {
        [versionString release];
        versionString = [aVersionString copy];
    }
}


- (void)dealloc
{
    [self setTitle:nil];
    [self setDate:nil];
    [self setDescription:nil];
    [self setReleaseNotesURL:nil];
    [self setDSASignature:nil];
    [self setMD5Sum:nil];
    [self setFileURL:nil];
    [self setFileVersion:nil];
	[self setVersionString:nil];
    [super dealloc];
}

@end
