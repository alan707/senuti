#!/bin/bash

if [ -f "Version.txt" ]; then
  VERSION=`egrep "^Version" Version.txt | awk '{print $2}'`
else
  echo "Version.txt missing!"
  exit 1
fi

if [ -f "build/senuti_$VERSION.dmg" ]; then
  echo "Uploading binary as a dmg..."
  googlecode_upload.py -p senuti -s "Senuti $VERSION" \
    -l Featured,Type-Executable,OpSys-OSX \
    build/senuti_$VERSION.dmg
else
  echo "Binary dmg missing!"
fi

echo

if [ -f "build/senuti_$VERSION.tbz" ]; then
  echo "Uploading binary as a tbz..."
  googlecode_upload.py -p senuti -s "Senuti $VERSION" \
    -l Type-Archive,OpSys-OSX \
    build/senuti_$VERSION.tbz
else
  echo "Binary tbz missing!"
fi

echo

if [ -f "build/source_$VERSION.tbz" ]; then
  echo "Uploading source code..."
  googlecode_upload.py -p senuti -s "Senuti Source $VERSION" \
    -l Type-Source,OpSys-OSX \
    build/source_$VERSION.tbz
else
  echo "Source missing!"
fi
