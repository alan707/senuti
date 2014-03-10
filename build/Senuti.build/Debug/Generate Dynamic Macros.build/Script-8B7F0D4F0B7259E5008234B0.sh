#!/bin/sh
#/bin/sh

# don't specify any output files for this script.
# it won't run every time if there are any

OUTPUT="$SRCROOT/ImportedMacros.h"
TMP_OUTPUT="$SRCROOT/ImportedMacrosTemp.h"

#CONFIGURATION already defined
BETA=`egrep "^Beta" "$SCRIPT_INPUT_FILE_0" | awk '{print $2}'`

# create the file one way or another
if ( ! [ -e "$OUTPUT" ] ); then
	touch "$OUTPUT"
	chmod 555 "$OUTPUT"
fi

# write to a temp file
if ( [ "$CONFIGURATION" = "Release" ] ) ; then
	echo "#define RELEASE" > "$TMP_OUTPUT"
else
    echo "#define DEBUG" > "$TMP_OUTPUT"
fi
if ( [ "$BETA" = "true" ] ) ; then
	echo "#define BETA" >> "$TMP_OUTPUT"
fi

# write a new file only if there were changes
CHANGES=`diff "$OUTPUT" "$TMP_OUTPUT"`
if ( [ -n "$CHANGES" ] ) ; then
	chmod 755 "$OUTPUT"
	cat "$TMP_OUTPUT" > "$OUTPUT"
	chmod 555 "$OUTPUT"
fi

# remove the temp file
rm "$TMP_OUTPUT"
