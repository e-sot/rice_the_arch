#!/usr/bin/env bash

# Configuration stricte
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly SCRIPT_NAME=$(basename "$0")
readonly REQUIRED_SPACE=400  # En MB
readonly TEMP_PACMAN_DIR="/tmp/pacman"
readonly PACMAN_CACHE="/var/cache/pacman/pkg"
readonly COWSPACE="/run/archiso/cowspace"

# Fonctions de journalisation
log_info() { echo "[INFO] $*" | tee -a /var/log/desktop-install.log; }
log_error() { echo "[ERROR] $*" | tee -a /var/log/desktop-install.log; }
log_debug() { echo "[DEBUG] $*" | tee -a /var/log/desktop-install.log; }

# Configuration de l'espace temporaire
setup_temp_space() {
    log_info "Configuration de l'espace temporaire..."
    if ! mount -o remount,size=2G ${COWSPACE} 2>/dev/null; then
        mkdir -p ${TEMP_PACMAN_DIR}
        mount -o bind ${TEMP_PACMAN_DIR} ${PACMAN_CACHE}
    fi
}

# Nettoyage du cache pacman
clean_pacman_cache() {
    log_info "Nettoyage du cache pacman..."
    pacman -Scc --noconfirm
    rm -rf /var/cache/pacman/pkg/*
}

# Vérification des dépendances
check_dependencies() {
    local deps=(git base-devel)
    for dep in "${deps[@]}"; do
        if ! pacman -Qi "$dep" >/dev/null 2>&1; then
            log_error "Dépendance manquante: $dep"
            return 1
        fi
    done
}

# Installation des paquets X11
install_x11() {
    log_info "Installation des composants X11..."
    local retries=3
    local wait_time=5
    
    for ((i=1; i<=retries; i++)); do
        if pacman -S --needed --noconfirm \
            xorg-server xorg-xinit xorg-xsetroot xorg-xrandr xorg-xrdb \
            libx11 libxft libxinerama libxrandr libxss picom python-pywal xwallpaper; then
            return 0
        fi
        log_info "Tentative $i/$retries échouée, nouvelle tentative dans ${wait_time}s..."
        sleep "$wait_time"
    done
    return 1
}

# Définir les chemins de configuration
readonly CONFIG_ROOT="/tmp/suckless-config"
readonly DWM_CONFIG="${CONFIG_ROOT}/dwm"
readonly ST_CONFIG="${CONFIG_ROOT}/st"
readonly DMENU_CONFIG="${CONFIG_ROOT}/dmenu"

# Fonction de préparation des configurations
setup_config_dirs() {
    log_info "Préparation des configurations..."
    
    # Créer les répertoires
    mkdir -p "${DWM_CONFIG}" "${ST_CONFIG}" "${DMENU_CONFIG}"
    
    # Configuration DWM
    cat > "${DWM_CONFIG}/config.h" << 'EOF'
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

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
    { MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
    { MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
    { MODKEY|ShiftMask,            KEY,      tag,            {.ui = 1 << TAG} }, \
    { MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, NULL };
static const char *termcmd[]  = { "st", NULL };

static Key keys[] = {
    /* modifier                     key        function        argument */
    { MODKEY,                       XK_p,      spawn,          {.v = dmenucmd } },
    { MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
    { MODKEY,                       XK_b,      togglebar,      {0} },
    { MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
    { MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
    { MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
    { MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
    { MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
    { MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
    { MODKEY|ShiftMask,            XK_Return, zoom,           {0} },
    { MODKEY,                       XK_Tab,    view,           {0} },
    { MODKEY|ShiftMask,            XK_c,      killclient,     {0} },
    { MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
    { MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
    { MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
    { MODKEY,                       XK_space,  setlayout,      {0} },
    { MODKEY|ShiftMask,            XK_space,  togglefloating, {0} },
    { MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
    { MODKEY,                       XK_period, focusmon,       {.i = +1 } },
    { MODKEY|ShiftMask,            XK_comma,  tagmon,         {.i = -1 } },
    { MODKEY|ShiftMask,            XK_period, tagmon,         {.i = +1 } },
    TAGKEYS(                        XK_1,                      0)
    TAGKEYS(                        XK_2,                      1)
    TAGKEYS(                        XK_3,                      2)
    TAGKEYS(                        XK_4,                      3)
    TAGKEYS(                        XK_5,                      4)
    { MODKEY|ShiftMask,            XK_q,      quit,           {0} },
};

/* button definitions */
static Button buttons[] = {
    /* click                event mask      button          function        argument */
    { ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
    { ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
    { ClkWinTitle,          0,              Button2,        zoom,           {0} },
    { ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
    { ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
    { ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
    { ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
    { ClkTagBar,            0,              Button1,        view,           {0} },
    { ClkTagBar,            0,              Button3,        toggleview,     {0} },
    { ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
    { ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
EOF

    # Configuration ST
    cat > "${ST_CONFIG}/config.h" << 'EOF'
/* See LICENSE file for copyright and license details. */

/* Appearance */
char *font = "JetBrains Mono:pixelsize=14:antialias=true:autohint=true";
int borderpx = 2;

/* Terminal settings */
char *shell = "/bin/sh";
char *utmp = NULL;
char *scroll = NULL;
char *stty_args = "stty raw pass8 nl -echo -iexten -cstopb 38400";
char *vtiden = "\033[?6c";
float cwscale = 1.0;
float chscale = 1.0;
wchar_t *worddelimiters = L" ";
int allowaltscreen = 1;
int allowwindowops = 0;
unsigned int doubleclicktimeout = 300;
unsigned int tripleclicktimeout = 600;
unsigned int xfps = 120;
unsigned int actionfps = 30;
unsigned int blinktimeout = 800;
unsigned int cursorthickness = 2;
int bellvolume = 0;
char *termname = "st-256color";
unsigned int tabspaces = 8;
int cols = 80;
int rows = 24;

/* Internal mouse shortcuts */
static MouseShortcut mshortcuts[] = {
    /* button               mask            function        argument */
    { Button4,              XK_NO_MOD,      ttysend,       {.s = "\031"} },
    { Button5,              XK_NO_MOD,      ttysend,       {.s = "\005"} }
};



/* Internal keyboard shortcuts */
#define MODKEY Mod1Mask
static Shortcut shortcuts[] = {
    /* mask                 keysym          function        argument */
    { ShiftMask,           XK_Insert,      selpaste,       {.i =  0} },
    { MODKEY|ShiftMask,    XK_C,           clipcopy,       {.i =  0} },
    { MODKEY|ShiftMask,    XK_V,           clippaste,      {.i =  0} },
    { MODKEY,              XK_Num_Lock,    numlock,        {.i =  0} }
};

/* Internal variables */
static char *ascii_printable = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
static unsigned int cursorshape = 2;
static unsigned int mouseshape = XC_xterm;
static unsigned int mousefg = 7;
static unsigned int mousebg = 0;
static unsigned int defaultattr = 11;
unsigned int defaultfg = 7;
unsigned int defaultbg = 0;
unsigned int defaultcs = 256;
unsigned int defaultrcs = 257;
static int forcemousemod = ShiftMask;
static int maxlatency = 33;
static int minlatency = 1;
static unsigned int ignoremod = Mod2Mask;
static KeySym mappedkeys[] = { -1 };

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
    [255] = 0,
    [256] = "#cccccc",
    [257] = "#555555",
};

static uint selmasks[] = {
    [SEL_RECTANGULAR] = Mod1Mask,
};


/* Special keys (change & recompile st.info accordingly) */
static Key key[] = {
    /* keysym           mask            string      appkey appcursor */
    { XK_KP_Home,       ShiftMask,      "\033[2J",       0,   -1},
    { XK_KP_Home,       ShiftMask,      "\033[1;2H",     0,   +1},
    { XK_KP_Prior,      ShiftMask,      "\033[5;2~",     0,    0},
    { XK_KP_End,        ControlMask,    "\033[J",       -1,    0},
    { XK_KP_End,        ControlMask,    "\033[1;5F",    +1,    0},
    { XK_KP_End,        ShiftMask,      "\033[K",       -1,    0},
    { XK_KP_End,        ShiftMask,      "\033[1;2F",    +1,    0},
    { XK_KP_Next,       ShiftMask,      "\033[6;2~",     0,    0},
    { XK_KP_Insert,     ShiftMask,      "\033[2;2~",    +1,    0},
    { XK_KP_Insert,     ShiftMask,      "\033[4l",      -1,    0},
    { XK_KP_Insert,     ControlMask,    "\033[L",       -1,    0},
    { XK_KP_Insert,     ControlMask,    "\033[2;5~",    +1,    0},
};

EOF

    # Configuration DMENU
    cat > "${DMENU_CONFIG}/config.h" << 'EOF'
/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

static int topbar = 1;                      /* -b  option; if 0, dmenu appears at bottom     */
static int centered = 0;                    /* -c option; centers dmenu on screen */
static int min_width = 500;                    /* minimum width when centered */
/* -fn option overrides fonts[0]; default X11 font or font set */
static const char *fonts[] = {
	"JetBrains Mono:size=10"
};
static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
static const char *colors[SchemeLast][2] = {
	/*     fg         bg       */
	[SchemeNorm] = { "#bbbbbb", "#222222" },
	[SchemeSel] = { "#eeeeee", "#005577" },
	[SchemeOut] = { "#000000", "#00ffff" },
};
/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines      = 0;

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";
EOF
}

# Modifier la fonction install_suckless_component
install_suckless_component() {
    local name=$1
    local repo=$2
    local config_dir="${CONFIG_ROOT}/${name}"

    log_info "Installation de $name..."
    if [ -d "/usr/local/src/$name" ]; then
        rm -rf "/usr/local/src/$name"
    fi
    
    git clone "$repo" "/usr/local/src/$name" || return 1
    cd "/usr/local/src/$name" || return 1

    # Désactiver Xinerama dans config.mk
    sed -i 's/^XINERAMALIBS/#XINERAMALIBS/g' config.mk
    sed -i 's/^XINERAMAFLAGS/#XINERAMAFLAGS/g' config.mk
    
    # Copier la configuration depuis notre répertoire temporaire
    if [ -f "${config_dir}/config.h" ]; then
        cp "${config_dir}/config.h" config.h
    else
        # Si pas de config.h, utiliser config.def.h
        if [ -f "config.def.h" ]; then
            cp config.def.h config.h
        else
            log_error "Fichier de configuration manquant pour $name"
            return 1
        fi
    fi
    
    make clean install || return 1
}

# Configuration des répertoires utilisateur
setup_user_dirs() {
    local dirs=(
        "/home/vagrant/.dwm"
        "/home/vagrant/.config/dwm"
        "/home/vagrant/.config/X11"
        "/home/vagrant/.local/share"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
}


# Fonction principale
main() {
    log_info "Début de l'installation..."

    # Configuration de l'espace temporaire
    setup_temp_space
    
    # Nettoyage initial
    clean_pacman_cache

    # Initialisation de pacman
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Syy

    # Installation des dépendances de base
    pacman -S --noconfirm --needed git base-devel



    # Configuration X11
    log_info "Configuration de X11..."

    # Création du xinitrc
    cat > /home/vagrant/.xinitrc << 'EOF'

    # Source system xinitrc files
    if [ -d /etc/X11/xinit/xinitrc.d ]; then
        for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
            [ -x "$f" ] && . "$f"
        done
        unset f
    fi

    # Set keyboard layout
    setxkbmap us &

    # Set display resolution
    xrandr --output Virtual-1 --mode 1920x1080 &

    # Start compositor
    picom --config $HOME/.config/picom/picom.conf &

    # Set wallpaper and generate colorscheme
    wal -i "$(find $HOME/assets/wallpapers -type f | shuf -n 1)" &

    # Start status bar script
    $HOME/.config/dwm/autostart.sh &

    # Start window manager
    exec dwm
EOF

    # Création du Xresources
    cat > /home/vagrant/.Xresources << 'EOF'
    ! Basic settings
    *.foreground:   #c5c8c6
    *.background:   #1d1f21
    *.cursorColor:  #c5c8c6

    ! Include pywal colors
    #include ".cache/wal/colors.Xresources"

    ! Font configuration
    *.font: JetBrains Mono:size=10
    *.boldFont: JetBrains Mono:style=Bold:size=10
    *.italicFont: JetBrains Mono:style=Italic:size=10
    *.boldItalicFont: JetBrains Mono:style=Bold Italic:size=10

    ! DPI settings
    Xft.dpi: 96
    Xft.antialias: true
    Xft.hinting: true
    Xft.rgba: rgb
    Xft.autohint: false
    Xft.hintstyle: hintslight
    Xft.lcdfilter: lcddefault
EOF

    # Attribution des permissions
    chmod 644 /home/vagrant/.xinitrc
    chmod 644 /home/vagrant/.Xresources

    # Vérifications
    check_dependencies || exit 1
    install_x11 || exit 1
    setup_user_dirs

    mkdir -p /home/vagrant/.cache/wal

    # Générer une configuration de couleurs par défaut
    wal -n -i /usr/share/backgrounds/default.jpg || {
    wal --theme base16-default -n 
    }


    setup_config_dirs

    # Installation des composants suckless
    local components=(
        "dwm|https://git.suckless.org/dwm|/config/dwm/config.h"
        "st|https://git.suckless.org/st|/config/st/config.h"
        "dmenu|https://git.suckless.org/dmenu|/config/dmenu/config.h"
    )

    for component in "${components[@]}"; do
        IFS="|" read -r name repo config <<< "$component"
        install_suckless_component "$name" "$repo" "$config" || exit 1
    done

 

    # Permissions
    log_info "Configuration des permissions..."
    chown -R vagrant:vagrant /home/vagrant

    log_info "Installation terminée avec succès!"
}

# Nettoyage à la sortie
cleanup() {
    local exit_code=$?
    log_info "Nettoyage..."
    
    # Démontage du cache temporaire
    if mountpoint -q "${PACMAN_CACHE}"; then
        umount "${PACMAN_CACHE}"
    fi
    
    # Nettoyage des fichiers temporaires
    rm -rf "${TEMP_PACMAN_DIR}"
    
    exit $exit_code
}
trap cleanup EXIT

# Exécution
main "$@"
