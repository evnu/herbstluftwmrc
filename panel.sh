#!/bin/bash

# This should be somewhat similar to the font configured for dzen2 in Xresources
FONT="-*-terminus-*-*-*-*-14-*-*-*-*-*-*-*"

monitor=${1:-0}
geometry=($(herbstclient monitor_rect "$monitor"))
if [ -z "$geometry" ]; then
    echo "Invalid monitor $monitor"
    exit 1
fi
x=${geometry[0]}
panel_width=${geometry[2]}

function uniq_linebuffered()
{
    awk '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

{
    while true; do
        # "date" output is checked once a second, but an event is only
        # generated if the output changed compared to the previous run.
        date +$'date\t^fg(#efefef)%H:%M^fg(#909090), %Y-%m-^fg(#efefef)%d'
        sleep 1 || break
    done > >(uniq_linebuffered) &
    childpid1=$!

    while true; do
        energy_now=0
        energy_full=0

        for bat in /sys/class/power_supply/BAT*; do
            now=$(cat $bat/energy_now)
            full=$(cat $bat/energy_full)
            energy_now=$((energy_now + $now))
            energy_full=$((energy_full + $full))
        done

        echo -e "battery\t^fg(#efefef)$(($energy_now * 100 / $energy_full))%"
        sleep 1 || break
    done > >(uniq_linebuffered) &
    childpid2=$!

    herbstclient --idle

    kill $childpid1
    kill $childpid2
} | {
    date=""
    battery=""
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
        echo -n " date: $date $separator battery: $battery"
        echo

        IFS=$'\t' read -ra cmd || break
        case "$cmd[0]" in
            tag*)
                TAGS=($(herbstclient tag_status $monitor))
                ;;
            date*)
                date="${cmd[@]:1}"
                ;;
            battery*)
                battery="${cmd[@]:1}"
                ;;
            reload*)
                break
                ;;
        esac
    done
} 2>/dev/null | dzen2 -dock -w $((panel_width / 2)) -x $(( x + panel_width / 4)) &
