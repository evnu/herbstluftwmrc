#!/bin/bash

# This should be somewhat similar to the font configured for dzen2 in Xresources
FONT="-*-terminus-*-*-*-*-14-*-*-*-*-*-*-*"

monitor=${1:-0}
geometry=( $(herbstclient monitor_rect "$monitor") )
if [ -z "$geometry" ] ;then
    echo "Invalid monitor $monitor"
    exit 1
fi
panel_width=${geometry[2]}

pkill dzen2
pkill conky

function uniq_linebuffered()
{
    awk '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

{
    conky | while read -r; do
        echo -e "conky $REPLY"
    done > >(uniq_linebuffered) &
    childpid=$!
    herbstclient --idle
    kill $childpid
} | {
    TAGS=($(herbstclient tag_status $monitor))
    separator="^fg(#1793D0)^ro(1x16)^fg()"
    while true; do
        for i in "${TAGS[@]}"; do
            echo -n "^ca(1,herbstclient use ${i:1}) "
            case ${i:0:1} in
                '#')
                    echo -n "^fg(#1793D0)[^fg(#FFFFFF)${i:1}^fg(#1793D0)]"
                    ;;
                ':')
                    echo -n "^fg(#FFFFFF) ${i:1} "
                    ;;
                *)
                    echo -n "^fg(#123456) ${i:1} "
                    ;;
            esac
            echo -n "^ca()"
        done
        echo -n " $separator "
        echo -n "$conky"
        echo
        read line || break
        cmd=($line)
        case "$cmd[0]" in
            tag*)
                TAGS=($(herbstclient tag_status $monitor))
                ;;
            conky*)
                conky="${cmd[@]:1}"
                ;;
        esac
    done
} 2>/dev/null | dzen2 -dock -w $((panel_width / 2)) -x $((panel_width / 4)) &
