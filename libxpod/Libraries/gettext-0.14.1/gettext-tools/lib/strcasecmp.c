/* Copyright (C) 1991-1992, 1995-1997, 2002 Free Software Foundation, Inc.

   NOTE: The canonical source of this file is maintained with the GNU C Library.
   Bugs can be reported to bug-glibc@gnu.org.

   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 2, or (at your option) any
   later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
   USA.  */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <ctype.h>
#include <string.h>

#ifndef weak_alias
# define __strcasecmp strcasecmp
# define TOLOWER(Ch) tolower (Ch)
#else
# ifdef USE_IN_EXTENDED_LOCALE_MODEL
#  define __strcasecmp __strcasecmp_l
#  define TOLOWER(Ch) __tolower_l ((Ch), loc)
# else
#  define TOLOWER(Ch) tolower (Ch)
# endif
#endif

#ifdef USE_IN_EXTENDED_LOCALE_MODEL
# define LOCALE_PARAM , __locale_t loc
#else
# define LOCALE_PARAM
#endif

/* Compare S1 and S2, ignoring case, returning less than, equal to or
   greater than zero if S1 is lexicographically less than,
   equal to or greater than S2.  */
int
__strcasecmp (const char *s1, const char *s2 LOCALE_PARAM)
{
  const unsigned char *p1 = (const unsigned char *) s1;
  const unsigned char *p2 = (const unsigned char *) s2;
  unsigned char c1, c2;

  if (p1 == p2)
    return 0;

  do
    {
      c1 = TOLOWER (*p1++);
      c2 = TOLOWER (*p2++);
      if (c1 == '\0')
	break;
    }
  while (c1 == c2);

  return c1 - c2;
}
#ifndef __strcasecmp
weak_alias (__strcasecmp, strcasecmp)
#endif
