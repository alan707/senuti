#!/bin/sh
#/bin/sh

# don't specify any output files for this script.
# it won't run every time if there are any

OUTPUT="$SRCROOT/FileProcessingMacros.h"

if ( [ -e "$OUTPUT" ] ); then
	chmod 755 "$OUTPUT"
fi

export PATH="/usr/local/bin/:/sw/bin:$PATH"

version=`egrep "^Version" "$SCRIPT_INPUT_FILE_0" | awk '{print $2}'`
revision="r`svn info | grep Revision | awk '{print $2}'`"
beta=`egrep "^Beta" "$SCRIPT_INPUT_FILE_0" | awk '{print $2}'`

echo "#define VERSION $version" > "$OUTPUT"
echo "#define BUILD_DATE `date "+%Y-%m-%dT%H:%M:%SZ"`" >> "$OUTPUT"
echo "#define BUILD_REVISION $revision" >> "$OUTPUT"
echo "#define BUILD_USER `whoami`" >> "$OUTPUT"
if ( [ "$beta" = "true" ] ) ; then
	echo "#define BETA" >> "$OUTPUT";
fi

chmod 555 "$OUTPUT"
