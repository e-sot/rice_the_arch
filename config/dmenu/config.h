/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

static int topbar = 1;                      /* -b  option; if 0, dmenu appears at bottom     */
static int fuzzy = 1;                      /* -F  option; if 0, dmenu doesn't use fuzzy matching     */
static int centered = 0;                    /* -c  option; if 0, dmenu won't be centered on the screen */
static int min_width = 500;                    /* minimum width when centered */

/* -fn option overrides fonts[0]; default X11 font or font set */
static const char *fonts[] = {
    "JetBrains Mono:size=10",
    "FontAwesome:size=10"
};

static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */

/* Colors from pywal */
#include "/home/vagrant/.cache/wal/colors-wal-dmenu.h"

/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines      = 0;

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";
