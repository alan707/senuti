#!/bin/bash

svn info &> /dev/null
if [ "$?" -ne "0" ]; then
  echo "Need to run from project directory"
  exit 1
fi

CHANGES=`svn st | egrep "^(M|C)" | wc -l`
if [ "$CHANGES" -ne "0" ]; then
  echo "Cannot run when there are changes.  Please commit all changes."
  exit 1
fi

APP_VERSION=`egrep "^Version" Version.txt | awk '{print $2}'`

echo "Tagging external frameworks..."
{
  svn cp external "https://fsframework.googlecode.com/svn/tags/senutimark$APP_VERSION" -m "tagging senuti mark $APP_VERSION"
} &> /dev/null
if [ "$?" -ne "0" ]; then
  echo "Tagging external frameworks failed."
  exit 1
fi

echo "Setting externals..."
{
  svn propset svn:externals "external https://fsframework.googlecode.com/svn/tags/senutimark$APP_VERSION" . 
  svn up
} &> /dev/null
if [ "$?" -ne "0" ]; then
  echo "Setting externals failed."
  exit 1
fi

echo "Tagging project..."
{
  svn commit -m "setting up for tag"
  svn cp . "https://senuti.googlecode.com/svn/tags/senuti$APP_VERSION" -m "tagging $APP_VERSION"
} &> /dev/null
if [ "$?" -ne "0" ]; then
  echo "Tagging project failed."
  exit 1
fi

echo "Bringing back to trunk..."
{
  svn propset svn:externals "external https://fsframework.googlecode.com/svn/trunk" .
  svn commit -m "bringing back to trunk"
  svn up
} &> /dev/null
if [ "$?" -ne "0" ]; then
  echo "Bringing back to trunk failed."
  exit 1
fi

echo "Successfully tagged project at: https://senuti.googlecode.com/svn/tags/senuti$APP_VERSION"
exit 0