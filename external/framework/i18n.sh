# The FadingRed Framework is the legal property of its developers, whose names are listed in the copyright file included
# with this source distribution.
# 
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the License,
# or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# This file was originaly created by David Kocher for Cyberduck and released under the GNU GPL.
# It has been modified for use with the FadingRed Framework. The origianal copyright is below.
#
# Copyright (c) 2003 David Kocher. All rights reserved.
# http://cyberduck.ch/


#!/bin/bash

base_language="en.lproj"

usage() {
	echo ""
	echo "	  Usage: i18n.sh --extractstrings"
	echo "	  Usage: i18n.sh [-l <language>] --init"
	echo "	  Usage: i18n.sh [-l <language>] [-n <nib>] [--force] --update"
	echo ""
	echo "<language> must be Japanese.lproj, French.lproj, Spanish.lproj, ..."
	echo "<nib> must be Preferences.nib, Main.nib, ..."
	echo ""
	echo "Call with no parameters to update all languages and all nib files"
	echo ""
}

init() {
	mkdir -p Resources/$language
	for nibfile in `ls Resources/$base_language | grep .nib | grep -v ~.nib | grep -v .local.nib | grep -v .new.nib | grep -v .base.nib`; do
	{
		echo "Copying $nibfile"
		nib=`basename Resources/$nibfile .nib`
		cp -R Resources/$base_language/$nibfile Resources/$language/$nibfile
		rm -rf Resources/$language/$nibfile/.svn
	}
	done
	cp Resources/$base_language/*.strings Resources/$language/
}

extractstrings() {
	echo "*** Extracting strings from Obj-C source files (genstrings)..."
	genstrings -a -s FSLocalizedString -o Resources/$base_language Source/*.m
}

nib() {
	rm -rf \
		Resources/$language/$nib.local.nib \
		Resources/$language/$nib.new.nib \
		Resources/$language/$nib.base.nib;
	if [ "$language" = "$base_language" ]; then
		cp -R Resources/$language/$nibfile Resources/$language/$nib.local.nib;
	else
		mv Resources/$language/$nibfile Resources/$language/$nib.local.nib;
	fi;
	last=`svn info Resources/$language/$nib.local.nib | grep 'Last Changed Rev' | awk '{print $4}'`;
	repos=`svn info Resources/$language/$nib.local.nib | grep 'Repository Root' | awk '{print $3}'`;
	svn export -r $last $repos/trunk/Resources/$base_language/$nibfile Resources/$language/$nib.base.nib &> /dev/null;
	
	updateNibFromStrings; # Changes to the .strings has precedence over the NIBs
	udpateStringsFromNib; # Update the .strings with new values from NIBs
	
	rm -Rf Resources/$language/$nibfile/.svn;
	cp -R Resources/$language/$nib.local.nib/.svn Resources/$language/$nibfile/.svn;
	rm -rf Resources/$language/$nib.local.nib Resources/$language/$nib.base.nib;
}

updateNibFromStrings() {
	if($force == true); then
	{
		# force update
		echo "*** Updating $nib... (force) in $language...";
		ibtool --strings-file Resources/$language/$nib.strings \
				--write Resources/$language/$nib.new.nib \
				Resources/$base_language/$nibfile;
	}
	else
	{
		# incremental update
		echo "*** Updating $nib... (incremental) in $language...";
		ibtool --localize-incremental \
				--previous-file Resources/$language/$nib.base.nib \
				--incremental-file Resources/$language/$nib.local.nib \
				--strings-file Resources/$language/$nib.strings \
				--write Resources/$language/$nib.new.nib \
				Resources/$base_language/$nibfile;
				
	}
	fi;
	rm -Rf Resources/$language/$nibfile;
	mv Resources/$language/$nib.new.nib Resources/$language/$nibfile;
}

udpateStringsFromNib() {
	if($force == true); then
	{
		echo "*** Updating $nib.strings (force) in $language...";
		ibtool --generate-strings-file Resources/$language/$nib.strings \
				Resources/$base_language/$nibfile;
	}
	else
	{
		echo "*** Updating $nib.strings (incremental) in $language...";
		ibtool --localize-incremental \
				--previous-file Resources/$language/$nib.base.nib \
				--incremental-file Resources/$language/$nibfile \
				--generate-strings-file Resources/$language/$nib.strings \
				Resources/$base_language/$nibfile;
	}
	fi;
}

update() {
	if [ "$language" = "all" ] ; then
	{
		echo "*** Updating all localizations...";
		for lproj in `ls ./Resources | grep lproj`; do
			language=$lproj;
			if [ $language != $base_language ]; then
			{
				echo "*** Updating $language Localization...";
				if [ "$nibfile" = "all" ] ; then
					echo "*** Updating all NIBs...";
					for nibfile in `ls Resources/$language | grep .nib | grep -v ~.nib | grep -v .local.nib | grep -v .new.nib | grep -v .base.nib`; do
						nib=`basename $nibfile .nib`
						nib;
					done;
					nibfile="all";
				fi;
				if [ "$nibfile" != "all" ] ; then
						nib=`basename $nibfile .nib`
						nib;
				fi;
			}
			fi;
		done;
	}
	else
	{
		echo "*** Updating $language Localization...";
		if [ "$nibfile" = "all" ] ; then
			echo "*** Updating all NIBs...";
			for nibfile in `ls Resources/$language | grep .nib | grep -v ~.nib | grep -v .local.nib | grep -v .new.nib | grep -v .base.nib`; do
				nib=`basename $nibfile .nib`;
				nib;
			done;
		fi;
		if [ "$nibfile" != "all" ] ; then
		{
			nib=`basename $nibfile .nib`;
			nib;
		}
		fi;
	}
	fi;
}

language="all";
nibfile="all";
force=false;

while [ "$1" != "" ] # When there are arguments...
	do case "$1" in 
			-l | --language)
				shift;
				language=$1;
				echo "Using Language:$language";
				shift;
			;;
			-n | --nib) 
				shift;
				nibfile=$1;
				echo "Using Nib:$nibfile";
				shift;
			;;
			-f | --force) 
				force=true;
				shift;
			;;
			-g | --extractstrings)
				extractstrings;
				exit 0;
				echo "*** DONE. ***";
			;;
			-h | --help) 
				usage;
				exit 0;
				echo "*** DONE. ***";
			;; 
			-i | --init)
				echo "Init new localization...";
				init;
				echo "*** DONE. ***";
				exit 0;
			;; 
			-u | --update)
				echo "Updating localization...";
				update;
				echo "*** DONE. ***";
				exit 0;
			;;
			*)	
				echo "Option [$1] not one of  [--extractstrings, --update, --init]"; # Error (!)
				exit 1
			;; # Abort Script Now
	esac;
done;

usage;
