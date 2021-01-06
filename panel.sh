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

battery()
{
    if [ -e /sys/class/power_supply/BAT0 ]; then
        energy_now=0
        energy_full=0

        for bat in /sys/class/power_supply/BAT*; do
            now=$(cat $bat/energy_now || cat $bat/charge_now)
            full=$(cat $bat/energy_full || cat $bat/charge_full)
            energy_now=$((energy_now + $now))
            energy_full=$((energy_full + $full))
        done

        echo -e "^fg(#efefef)$(($energy_now * 100 / $energy_full))%"
    fi
}

{
    while true; do
        date=$(date +$'^fg(#efefef)%H:%M^fg(#909090), %Y-%m-^fg(#efefef)%d')
        battery=$(battery)
        echo -e "status\t$date\t$battery"
        sleep 1 || break
    done > >(uniq_linebuffered) &
    childpid=$!

    herbstclient --idle

    kill $childpid
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
                '%')
                    echo -n "^fg(#1793D0)[^fg(#FF0000)${i:1}^fg(#1793D0)]"
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
        echo -n " $date $separator "
        if [ ! -z "$battery" ]; then
            echo -n " battery: $battery $separator"
        fi
        echo

        IFS=$'\t' read -ra cmd || break
        case "$cmd[0]" in
            tag*)
                TAGS=($(herbstclient tag_status $monitor))
                ;;
            status*)
                date="${cmd[1]}"
                battery="${cmd[2]}"
                ;;
            reload*)
                break
                ;;
        esac
    done
} 2>/dev/null | dzen2 -dock -w $((panel_width / 2)) -x $((x + panel_width / 4)) &
