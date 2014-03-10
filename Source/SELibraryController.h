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

#import "SEObject.h"
#import "SEController.h"

@class SEITunesLibrary;
@protocol SELibrary;

@protocol SECrossReferenceObserver
- (void)didCross:(id <SELibrary>)firstLibrary with:(id <SELibrary>)secondLibrary;
@end

@class SEIPodLibrary;
@interface SELibraryController : SEObject <SEController> {
	SEITunesLibrary *iTunesLibrary;
	NSMutableSet *iPodLibraries;
	NSMutableSet *crossReferenceObservers;
	
	id iTunesLibraryFetcher, iPodLibraryFetcher;
	BOOL hasIPods;
}

- (SEITunesLibrary *)iTunesLibrary; /* returns nil if library isn't loaded yet */

- (NSSet *)iPodLibraries;
- (BOOL)hasIPods; /* At launch, this will be updated as
				   * soon as the controller has information
				   * about whether there are iPods plugged
				   * in or not.  It will not wait for them
				   * to load completely.  During normal
				   * operation, this will be updated when
				   * the iPod has been fully loaded. */

- (void)eject:(SEIPodLibrary *)library;

- (void)addCrossReferenceObserver:(id <SECrossReferenceObserver>)observer;
- (void)removeCrossReferenceObserver:(id <SECrossReferenceObserver>)observer;

@end
