/* See LICENSE file for copyright and license details. */
#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx  = 2;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar           = 1;        /* 0 means no bar */
static const int topbar            = 1;        /* 0 means bottom bar */
static const int lockfullscreen    = 1;        /* 1 will force focus on the fullscreen window */
static const char *fonts[]         = { "JetBrains Mono:size=10", "FontAwesome:size=10" };
static const char dmenufont[]      = "JetBrains Mono:size=10";

/* colors */
static const char norm_fg[]       = "#bbbbbb";
static const char norm_bg[]       = "#222222";
static const char norm_border[]   = "#444444";
static const char sel_fg[]        = "#eeeeee";
static const char sel_bg[]        = "#005577";
static const char sel_border[]    = "#005577";

static const char *colors[][3]      = {
    /*               fg           bg           border   */
    [SchemeNorm] = { norm_fg,     norm_bg,     norm_border },
    [SchemeSel]  = { sel_fg,      sel_bg,      sel_border  },
};

/* tagging */
static const char *tags[] = { "", "", "", "", "" };

static const Rule rules[] = {
    /* class      instance    title       tags mask     isfloating   monitor */
    { "Firefox",  NULL,       NULL,       1 << 1,       0,           -1 },
    { "St",       NULL,       NULL,       0,            0,           -1 },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */

static const Layout layouts[] = {
    /* symbol     arrange function */
    { "[]=",      tile },    /* first entry is default */
    { "><>",      NULL },    /* no layout function means floating behavior */
    { "[M]",      monocle },
};
