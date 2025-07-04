#! /usr/bin/env sh
# luadocs.sh
# Open Lua documentation in a browser.
set -e

# Global parameters
luadocs_version=0.1.0
lua_top="$HOME/builds/lua"

script_fail() {
    printf "*** %s : %s ***\n" "$1" "$2" >&2
    exit 2
}

# Detect resource opener.
OPENER=
if type firefox > /dev/null ; then
    OPENER='firefox --new-window'
elif type xdg-open > /dev/null ; then
    OPENER='xdg-open'
elif type gio > /dev/null ; then
    OPENER='gio open'
elif type lynx > /dev/null ; then
    OPENER='lynx'
else
    type firefox
    type xdg-open
    type gio
    type lynx
    script_fail "no resource opener" "\`firefox\`, \`xdg-open\` or \`gio\` must be installed"
fi

match_version='[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+'

usage() {
    printf "luadocs version %s\n" $luadocs_version
    printf "\n"
    printf "%s\n" "Usage:"
    printf "%s\n" "------"
    printf "%s\n" "luadocs [options] [version]"
    printf "%s\n" ""
    printf "%s\n" "Opens Lua documentation for the specified version,"
    printf "%s\n" "or documentation for the installed version by default"
    printf "%s\n" ""
    printf "%s\n" "Options:"
    printf "%s\n" "--------"
    printf "%s\n" "-l | --list ... List available documentation versions"
    printf "%s\n" "-h | --help ... Show this help screen"
}

display_version() {
    if [ "$1" = "$lua_installed_ver" ]
    then printf "> %s <\n" "$1"
    else printf "  %s\n" "$1"
    fi
}

# Get available version numbers.
lua_available_ver=$(find "$lua_top" -maxdepth 1 -type d |
                 grep "lua" |
                 grep -Eo $match_version |
                 sort -t. -k 1,1nr -k 2,2nr -k 3,3nr -k 4,4nr)

if [ -z "$lua_available_ver" ] ; then
    script_fail "no Lua files found" "$lua_top"
fi

lua_latest_ver=$(echo $lua_available_ver | awk '{print $1}')

# Get installed version number.
lua_installed_ver=
if type lua > /dev/null ; then
    lua_installed_ver=$(lua -v | grep -Eo $match_version)
fi

# Parse script options.
# Check long options for required arguments.
require_arg() {
    if [ -z "$OPTARG" ] ; then
        script_fail "Argument required" "--$OPT"
    fi
}

while getopts hl-: OPT
do
    if [ $OPT = "-" ]  ; then
        OPT=${OPTARG%%=*}      # get long option
        OPTARG=${OPTARG#$OPT}  # get long option argument
        OPTARG=${OPTARG#=}
    fi
    case "$OPT" in
        h | help )
            usage ; exit 0 ;;
        l | list )
            for ver in $lua_available_ver ; do
                display_version $ver
            done
            exit 0
            ;;
        \?)
            usage  # short option fail reported by `getopts`
            shift $((OPTIND - 2))
            script_fail "Unrecognized option" "$@"   # short option fail
            ;;
        *)  usage
            script_fail "Unrecognized option" "--$OPT"  # long option fail
            ;;
    esac
done

# Get user-specified version number.
shift $((OPTIND - 1))
select_ver="$(echo $@)"

if [ -z "$select_ver" ] ; then
    select_ver="$lua_installed_ver"
elif ! $(echo "$select_ver" | grep -E ^$match_version > /dev/null) ; then
    script_fail "not a version number" "$select_ver"
elif ! $(echo "$lua_available_ver" | grep "$select_ver" > /dev/null) ; then
    script_fail "Lua version not found" "$select_ver"
fi

if [ "$OPENER" = "lynx" ] ; then
    $OPENER "$lua_top/lua-$select_ver/doc/readme.html"
else
    $OPENER "$lua_top/lua-$select_ver/doc/readme.html" &
fi

