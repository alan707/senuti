/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
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

#define RELATIVE_PATH_TO_CRASH_REPORTER			@"/Contents/Frameworks/CrashReporter.framework/Resources/Crash Reporter.app"

@class AITextViewWithPlaceholder;

@class SUExternalStatusChecker;
@interface AICrashReporter : NSObject {
	IBOutlet	NSWindow                    *window_MainWindow;
	IBOutlet	NSTextField                 *textField_emailAddress;
	IBOutlet	NSTextField                 *textField_description;
	
	IBOutlet	NSScrollView				*scrollView_details;
	IBOutlet	AITextViewWithPlaceholder   *textView_details;
	
	IBOutlet	NSProgressIndicator         *progress_sending;
	IBOutlet	NSTextField					*textField_title;
	IBOutlet	NSTextField					*textField_info;
	IBOutlet	NSTextField					*textField_contactInfo;
	IBOutlet	NSTextField					*textField_emailLabel;
	IBOutlet	NSTextField					*textField_additionalInfo;
	IBOutlet	NSTextField					*textField_descriptionLabel;
	IBOutlet	NSTextField					*textField_explanationLabel;
	IBOutlet	NSButton					*button_privacy;
	IBOutlet	NSButton					*button_close;
	IBOutlet	NSButton					*button_send;
	
	IBOutlet	NSPanel                     *panel_privacySheet;
	IBOutlet	NSTextField					*textField_privacyInfo;
	IBOutlet	NSButton					*button_closeSheet;
	IBOutlet	NSTextView                  *textView_crashLog;
    
	NSString                                *crashLog;		//Current crash log
	NSDictionary							*buildInfo;
	//	NSString                                *buildDate, *buildNumber, *buildUser;
	NSString								*crashedApplicationName, *crashedApplicationPath;
	NSBundle								*crashedApplicationBundle;
	
	BOOL									transitioning;
	int										logDirectoryFileCount;
	SUExternalStatusChecker					*statusChecker;
	NSString								*newVersionString;
}
	
- (void)awakeFromNib;

- (IBAction)showPrivacyDetails:(id)sender;
- (IBAction)closePrivacyDetails:(id)sender;

- (BOOL)reportCrashForLogAtPath:(NSString *)inPath;
- (BOOL)reportCrashForLogInDir:(NSString *)inPath withPrefix:(NSString *)prefix;
- (void)sendReport:(NSDictionary *)crashReport;
- (IBAction)send:(id)sender;

@end
