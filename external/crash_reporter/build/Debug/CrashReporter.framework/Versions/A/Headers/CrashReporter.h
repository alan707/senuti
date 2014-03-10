/*
 *  CrashReporter.h
 *  CrashReporter
 *
 *  Created by Whitney Young on 8/4/06.
 *  Copyright 2006 Whitney Young. All rights reserved.
 *
 *
 *  -- To use the Crash Reporter:
 *  --------------------------------------------------------------------------------------
 *  1) In the Info.plist file of your main Application, include a key
 *     CrashReportURL that is a string containing the URL to which you
 *     want crash reports sent.
 *  2) Compile the framework and add it to your main project
 *     If you don't have a normal way of adding frameworks to your project,
 *     simply right click in the list of files and navigate to Add Existing Frameworks...
 *     You can add the framework that way.
 *  3) Add a copy files build phase to your main project.  Set the destination to
 *     Frameworks, and add the CrashReporter framework to that build phase so that
 *     your application contains the CrashReporter.
 *  4) At the earliest point in your code that you can (in an
 *	   applicationDidFinishLaunching: call or something similar), add the following calls
 *
 *     #include <CrashReporter/CrashReporter.h>
 *     ....
 *     [AICrashController enableCrashCatching];
 *     [AIExceptionController enableExceptionCatching];
 *
 *     to enable crash and exception catching.
 *  5) Implement a script on your server (at the CrashReportURL location from step 1)
 *     that will save the information.  Information that will be received via POST variables
 *     is as follows:
 *			version - The version of your application
 *			email - The email address of the user submitting the report
 *			short_desc - The short description the user gave
 *			desc - The long description the user gave
 *			log - The crash/exception log
 *
 *  That's it!  You're finished.  Enjoy using the crash reporter!
 *  --------------------------------------------------------------------------------------
 *
 *
 *
 *  -- Options:
 *  --------------------------------------------------------------------------------------
 *  You can supply a plist file called BuildInfo in the resources folder of your application
 *  containing a dictionary of keys and values.  The keys will be sent as post variables to
 *  your save script and the values will be the values of those variables.  An example is
 *  shown below.
 *
 *  If you use Sparkle, the CrashReporter framework can leverage Sparkle and check to make
 *  sure that the person using your application is using the most recent version of it.  If
 *  they're not using the most recent version, the CrashReporter will disable crash reporting
 *  and allow them to update it before relaunching the application.  In order to enable this
 *  support, you must be using a modified version of Sparkle which can be checked out from
 *  an subversion repository at FadingRed:
 *		svn co svn://fadingred.org/sparkle/trunk/
 *  This verion of Sparkle has a lot of changes and enhancements, but should be a drag and
 *  drop replacement for Sparkle versions 1.0 and 1.1 (and possibly versions to come).
 *  --------------------------------------------------------------------------------------
 *
 *
 *
 *  -- BuildInfo.plist example
 *  --------------------------------------------------------------------------------------
 *  The following BuildInfo.plist file will send
 *			date - "2006-08-15 20:33:31"
 *			revision - "r32"
 *  to your save script
 *
 *  <?xml version="1.0" encoding="UTF-8"?>
 *  <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 *  <plist version="1.0">
 *  <dict>
 *  	<key>date</key>
 *  	<date>2006-08-15T20:33:31Z</date>
 *  	<key>revision</key>
 *  	<string>r32</string>
 *  </dict>
 *  </plist>
 *  --------------------------------------------------------------------------------------
 *
 */

#import <CrashReporter/AICrashController.h>
#import <CrashReporter/AIExceptionController.h>