/* 
 * The FadingRed Shared Framework (FSFramework) is the legal property of its developers, whose names
 * are listed in the copyright file included with this source distribution.
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

@class FSControlledView;
@interface FSViewController : NSObject {
	IBOutlet FSControlledView *view;
	NSMutableArray *topLevelObjects;
}

+ (NSString *)nibName;

+ (id)controller;
- (id)init;
- (FSControlledView *)view; // load the nib (if not loaded) and return the view
- (BOOL)isViewLoaded;

// IMPORTANT NOTE: -------------------------------
// It is ESENTIAL that if you bind something to
// this controller that you unbind it when finished.
// The best practice for using bindings would be to
// bind when the view activates and unbind when it
// deactivates.  Activation and deactivation happen
// when the view is added or removed from a window
// so it shouldn't cause any performance hit (you
// wouldn't want to be observing changes when the view
// isn't visible anyway).  The alternative is that
// this object will never be released because whatever
// is bound to this will have retained it and you have
// no way of controlling the release of it except to
// unbind.
// -----------------------------------------------

// the following methods are for subclassers
// none of them should be called directly

// the following methods are not invoked when
// a view changes from one window to another
- (void)viewWillActivate;	// called before a view is added to a window
- (void)viewDidActivate;	// called after a view is added to a window

- (void)viewWillInactivate;	// called before a view is removed from a window
- (void)viewDidInactivate;	// called after a view is removed from a window

@end
