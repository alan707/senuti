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

/*
 * This code is orinally from Adium.
 * Visit http://www.adiumx.com/ for more information.
 */

@interface NSAppleScript (FSAppleScriptAdditions)

+ (NSAppleEventDescriptor *)descriptorForArray:(NSArray *)argumentArray;

/*!
 * @brief Execute a function
 *
 * Executes a function <b>functionName</b> within the <tt>NSAppleScript</tt>, returning error information if necessary
 * @param functionName An <tt>NSString</tt> of the function to be called. It is case sensitive.
 * @param errorInfo A reference to an <tt>NSDictionary</tt> variable, which will be filled with error information if needed. It may be nil if error information is not requested.
 * @return An <tt>NSAppleEventDescriptor</tt> generated by executing the function.
 */
- (NSAppleEventDescriptor *)executeFunction:(NSString *)functionName error:(NSDictionary **)errorInfo;

/*!
 * @brief Execute a function with arguments
 *
 * Executes a function <b>functionName</b> within the <tt>NSAppleScript</tt>, returning error information if necessary. Arguments in <b>argumentArray</b> are passed to the function.
 * @param functionName An <tt>NSString</tt> of the function to be called. It is case sensitive.
 * @param argumentArray An <tt>NSArray</tt> of <tt>NSString</tt>s and/or <tt>NSNumbers</tt>s (used for ints) and/or <tt>NSArray</tt>s (of the previous types) to be passed to the function when it is called.
 * @param errorInfo A reference to an <tt>NSDictionary</tt> variable, which will be filled with error information if needed. It may be nil if error information is not requested.
 * @return An <tt>NSAppleEventDescriptor</tt> generated by executing the function.
 */
- (NSAppleEventDescriptor *)executeFunction:(NSString *)functionName withArguments:(NSArray *)argumentArray error:(NSDictionary **)errorInfo;

@end

@interface NSAppleEventDescriptor (FSAppleScriptAdditions)

+ (NSAppleEventDescriptor *)descriptorWithDate:(NSDate *)date;
- (id)initWithDate:(NSDate *)date;

@end