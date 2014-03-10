#!/bin/sh
#!/bin/sh

echo linking external frameworks...

sparkle="sparkle Sparkle.framework"
fs_framework="framework FSFramework.framework"
applescript="framework FSAppleScriptServer"
crash_reporter="crash_reporter CrashReporter.framework"
libxpod="libxpod Libxpod.framework"

for framework in "$sparkle" "$fs_framework" "$applescript" "$crash_reporter" "$libxpod"
do
  dir="`echo $framework | awk '{print $1}'`"
  name="`echo $framework | awk '{print $2}'`"
  orig_path="$SRCROOT/$dir/build/$CONFIGURATION/$name"
  ln -fs "$orig_path" "$BUILT_PRODUCTS_DIR/$name";
done
