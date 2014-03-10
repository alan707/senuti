#define EXPLAIN												\
															\
/*  This file is used in processing the Info.plist file.	\
 *  The compiler does not go past preprocessing on it, so	\
 *  it cannot contain anything except macro definitions.	\
 *  The PLAIN URLs are for use in the Info.plist file 		\
 *  (since they don't use strings) and the other URLs are	\
 *  for use in other files.  Make sure the corresponding 	\
 *  URLs match when changing them.							\
 *  The Info.plist file needs the URL information so that   \
 *  the crash reporter can use it to enable sparkle         \
 *  support.
 */

#define BETA_UPDATE_CHECK_URL			@"http://www.fadingred.org/senuti/beta_updates.xml"
#define BETA_UPDATE_CHECK_URL_PLAIN		http://www.fadingred.org/senuti/beta_updates.xml

#define UPDATE_CHECK_URL				@"http://www.fadingred.org/senuti/updates.xml"
#define UPDATE_CHECK_URL_PLAIN			http://www.fadingred.org/senuti/updates.xml

#undef EXPLAIN
