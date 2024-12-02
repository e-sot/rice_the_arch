/* See LICENSE file for copyright and license details. */

/* appearance */
static char *font = "JetBrains Mono:pixelsize=14:antialias=true:autohint=true";
static int borderpx = 2;

/* identification sequence returned in DA and DECID */
char *vtiden = "\033[?6c";

/* Kerning / character bounding-box multipliers */
static float cwscale = 1.0;
static float chscale = 1.0;

/* word delimiter string */
wchar_t *worddelimiters = L" ";

/* selection timeouts (in milliseconds) */
static unsigned int doubleclicktimeout = 300;
static unsigned int tripleclicktimeout = 600;

/* alt screens */
int allowaltscreen = 1;

/* allow certain non-interactive (insecure) window operations such as:
   setting the clipboard text */
int allowwindowops = 0;

/* frames per second st should at maximum draw to the screen */
static unsigned int xfps = 120;
static unsigned int actionfps = 30;

/* blinking timeout (set to 0 to disable blinking) for the terminal blinking
 * attribute. */
static unsigned int blinktimeout = 800;

/* thickness of underline and bar cursors */
static unsigned int cursorthickness = 2;

/* bell volume. It must be a value between -100 and 100. Use 0 for disabling it */
static int bellvolume = 0;

/* default TERM value */
char *termname = "st-256color";

/* spaces per tab */
unsigned int tabspaces = 8;

/* Terminal colors */
static const char *colorname[] = {
    "#000000",  /*  0: black    */
    "#ff0000",  /*  1: red      */
    "#33ff00",  /*  2: green    */
    "#ff0099",  /*  3: yellow   */
    "#0066ff",  /*  4: blue     */
    "#cc00ff",  /*  5: magenta  */
    "#00ffff",  /*  6: cyan     */
    "#d0d0d0",  /*  7: white    */
    "#808080",  /*  8: brblack  */
    "#ff0000",  /*  9: brred    */
    "#33ff00",  /* 10: brgreen  */
    "#ff0099",  /* 11: bryellow */
    "#0066ff",  /* 12: brblue   */
    "#cc00ff",  /* 13: brmagenta*/
    "#00ffff",  /* 14: brcyan   */
    "#ffffff",  /* 15: brwhite  */
};

/* Terminal colors for alternate (light) palette */
static const char *altcolorname[] = {
    "#000000",  /*  0: black    */
    "#ff0000",  /*  1: red      */
    "#33ff00",  /*  2: green    */
    "#ff0099",  /*  3: yellow   */
    "#0066ff",  /*  4: blue     */
    "#cc00ff",  /*  5: magenta  */
    "#00ffff",  /*  6: cyan     */
    "#d0d0d0",  /*  7: white    */
    "#808080",  /*  8: brblack  */
    "#ff0000",  /*  9: brred    */
    "#33ff00",  /* 10: brgreen  */
    "#ff0099",  /* 11: bryellow */
    "#0066ff",  /* 12: brblue   */
    "#cc00ff",  /* 13: brmagenta*/
    "#00ffff",  /* 14: brcyan   */
    "#ffffff",  /* 15: brwhite  */
};

/* Default colors (colorname index) */
static unsigned int defaultfg = 7;
static unsigned int defaultbg = 0;
static unsigned int defaultcs = 256;
static unsigned int defaultrcs = 257;
