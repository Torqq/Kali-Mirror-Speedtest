#!/usr/bin/env bash

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

# Mirrors to test
MIRRORS=(
    "https://kali.download/kali"
    "https://mirror.telecom-paris.fr/kali"
    "https://ftp.belnet.be/pub/kali"
    "https://ftp.halifax.rwth-aachen.de/kali"
    "https://mirror.serverion.com/kali"
    "https://mirrorservice.org/sites/archive.kali.org/kali"
)

TEST_FILE="/pool/main/k/kali-archive-keyring/kali-archive-keyring_2023.2_all.deb"
SLEEP_TIME=30   # seconds between refresh

speed_test() {
    local url="$1/$TEST_FILE"
    
    SPEED=$(curl -w "%{speed_download}" -o /dev/null -s --max-time 5 "$url")
    echo "$SPEED"
}

while true; do
    clear
    echo -e "${BLUE}Kali Mirror Speed Test (Real speed + ping) - $(date)${RESET}"
    echo

    RESULTS=()

    for mirror in "${MIRRORS[@]}"; do
        echo -e "Testing: $mirror"

        # Ping test
        PING=$(ping -c 3 -W 1 "$(echo "$mirror" | cut -d'/' -f3)" 2>/dev/null | awk -F'/' '/rtt/ {print $5}')
        [[ -z "$PING" ]] && PING="9999"

        # Real speed test
        SPEED=$(speed_test "$mirror")

        RESULTS+=("$SPEED $PING $mirror")
    done

    echo
    echo -e "${BLUE}Results (sorted by real speed):${RESET}"
    echo
    printf "%-45s | %-12s | %-12s\n" "Mirror" "Speed (Mbit/s)" "Ping (ms)"
    printf "%-45s | %-12s | %-12s\n" "------" "--------------" "---------"

    for line in $(printf '%s\n' "${RESULTS[@]}" | sort -nr); do
        SPEED=$(echo $line | awk '{print $1}')
        PING=$(echo $line | awk '{print $2}')
        MIRROR=$(echo $line | cut -d' ' -f3-)

        SPEED_MB=$(echo "$SPEED / 125000" | bc -l)   # Convert bytes/sec → Mbit/s

        COLOR="$RED"
        if (( $(echo "$SPEED_MB > 10" | bc -l) )); then COLOR="$GREEN"
        elif (( $(echo "$SPEED_MB > 3" | bc -l) )); then COLOR="$YELLOW"
        fi

        printf "${COLOR}%-45s | %10.2f Mbit/s | %9.2f ms${RESET}\n" "$MIRROR" "$SPEED_MB" "$PING"
    done

    echo
    echo -e "${BLUE}Refreshing in ${SLEEP_TIME}s... (Ctrl+C to stop)${RESET}"
    sleep $SLEEP_TIME
done

