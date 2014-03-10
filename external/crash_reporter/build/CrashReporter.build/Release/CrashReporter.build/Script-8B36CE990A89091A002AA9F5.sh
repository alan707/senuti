#!/bin/sh
# Create the symlink: Crash Reporter.app/Frameworks
# to the Frameworks of the project that's including this one (for Sparkle support)

cd "${BUILT_PRODUCTS_DIR}/CrashReporter.framework/Resources/Crash Reporter.app/Contents/"
if [ -e Frameworks ] ; then
    rm Frameworks
fi

echo "Symlinking framework..."
ln -fns "../../../../../../../Frameworks" "Frameworks"

