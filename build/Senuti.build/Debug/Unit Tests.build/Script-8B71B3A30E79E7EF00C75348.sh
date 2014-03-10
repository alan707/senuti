#!/bin/sh
# Run the unit tests in this test bundle.
"${SYSTEM_DEVELOPER_DIR}/Tools/RunUnitTests"

if [ "$CONFIGURATION" == "Coverage" ]; then
    OBJ_DIR="$TEMP_FILES_DIR/Objects-normal/${NATIVE_ARCH}"
    mkdir -p coverage
    pushd coverage > /dev/null
    find "${OBJROOT}" -name *.gcda | while read f; do
        DIR=`dirname "$f"`
        ARCH=`dirname "$DIR"`
        OBJS=`dirname "$ARCH"`
        TARGET=`basename "$OBJS" .build`
        STRIPED=`basename "$TARGET" .framework`
        if [ "$TARGET" != "$STRIPED" ]; then
            TARGET="$STRIPED.frmwork"
        fi
        if [ "$TARGET" != "$TARGET_NAME" ]; then
            mkdir -p "$TARGET"
            pushd "$TARGET" > /dev/null
            gcov -o "$DIR" "$f"
            popd > /dev/null
        fi
    done
    popd > /dev/null
fi

# Touch a runtime file so that XCode can figure out
# it last ran the tests.  This script will only be
# run when the Unit Tests executable has been built
# more recently than the tests have been run.
touch "$SCRIPT_OUTPUT_FILE_0"

exit 0
