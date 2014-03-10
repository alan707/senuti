# Copyright 2006 Whitney Young

#!/bin/bash

startdir=`pwd`

if [ -e "$1" ] && [ -n "$1" ] && [ -e "$2" ] && [ -n "$2" ] ; then
	from="`pwd`/$1";
	to="`pwd`/$2";

	cd "$from";
	found=`find -E . -regex ".*\.svn$"`;

	echo "copying files";
	for svndir in $found ; do
		test="$to/${svndir%.svn}";
		if [ -e "$test" ] ; then
			cp -R "$from/$svndir" "$test";
		else
			echo "skipping $svndir";
		fi
	done
else
	echo "script takes two arguments, a directory to copy .svn folders from and one to copy to"
fi

