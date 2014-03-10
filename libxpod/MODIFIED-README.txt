Most issues have been resolved in the config files.  Guard them with your life!

Issues resolved outside a config file should be listed here, so we can avoid them when we update the dependencies in the future.

LIBGPOD
  Nested functions don't work on OS X
  Needed a SPLACTION_VIDEO_UNKNOWN = 0x00000400 in itdb.h to handle issues with Video items in smart playlists
  Also added to itdb_spl_action_known in itdb_playlist.c

LIBICONV
  Not compiling (srclib) unsetenv.c/h, setenv.c/h, relocwrapper.c, memmove.c
  Not compiling (lib) genaliases.c, genaliases2.c, genflags.c, gentranslit.c

GLIB
  Not compiling (gmodule) any of the gmodule- files
  Not compiling (gthread) any of the gthread- files
  Not compiling (gobject) gmarshal.c/h
  Not using several *w32 files

GETTEXT
  Not compiling (runtime/lib) setenv.c, unsetenv.c, (tools/lib) setenv.c/h unsetenv.c
  Not compiling (tools/lib) javaexec.c/h, mbswidth.c/h relocwrapper.c
  Not compiling (tools/src) msgfmt.c, msginit.c, po-lex.c/h, read-java.c/h, read-tcl.c/h
                            urlget.c, write-po.c/h, x-csharp.c/h, 
  Not using intl-csharp, intl-java
  Not using several windows / *w32 files
  Not using several .y files
! Comment out the atexit method in (tools/lib) atexit.c