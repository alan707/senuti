//
//  AIFileManagerAdditions.h
//  Adium
//
//  Created by Adam Iser on Tue Dec 23 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * @category NSFileManager(AIFileManagerAdditions)
 * @brief Additions to <tt>NSFileManager</tt> for trashing files and creating directories
 */
@interface NSFileManager (AIFileManagerAdditions)

	/*
	 * @brief Move a file or directory to the trash
	 *
	 * sourcePath does not need to be tildeExpanded; it will be expanded if necessary.
	 * @param sourcePath Path to the file or directory to trash
	 * @result YES if trashing was successful or the file already does not exist; NO if it failed
	 */
- (BOOL)trashFileAtPath:(NSString *)sourcePath;

@end
