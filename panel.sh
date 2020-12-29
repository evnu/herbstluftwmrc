#!/bin/bash

FG='white'
BG='black'
DEFAULT_FONT="-*-fixed-medium-*-*-*-12-*-*-*-*-*-*-*"
FONT=$(grep dzen2.font ~/.Xresources | cut -f2- -d ' ' || echo "$DEFAULT_FONT")

pkill dzen2

herbstclient --idle | {
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
        echo -n " $separator"
        echo
        read line || break
        cmd=($line)
        case "$cmd[0]" in
            tag*)
                TAGS=($(herbstclient tag_status $monitor))
                ;;
        esac
    done
} 2>/dev/null | dzen2 -ta l -y 0 -x 0 -h 16 -w 1286 &
