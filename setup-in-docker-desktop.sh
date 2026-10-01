#!/bin/bash
APK_CACHE_DIR="/mnt/host/c/.apk-cache"

mkdir -p "$APK_CACHE_DIR"

echo Installing fastfetch
apk --cache-dir "$APK_CACHE_DIR" add fastfetch

echo Installing bat
apk --cache-dir "$APK_CACHE_DIR" add bat

echo Installing lsd
apk --cache-dir "$APK_CACHE_DIR" add lsd

echo Installing micro
apk --cache-dir "$APK_CACHE_DIR" add micro

echo Installing superfile
apk --cache-dir "$APK_CACHE_DIR" add superfile

echo Installing curl
apk --cache-dir "$APK_CACHE_DIR" add curl

echo Installing fish
apk --cache-dir "$APK_CACHE_DIR" add fish

mkdir -p ~/.config/fish; cat > ~/.config/fish/config.fish <<'EOF'
if status is-interactive
    clear
    cd Downloads
    
    set -g fish_greeting ""
    fastfetch

    alias cat='bat'
    alias cls='clear'
    alias ls='lsd -lha --icon always --blocks size,name --size short --date "+%a %d.%m.%Y"'
    alias lsa='ls -lha'
    alias nano='micro'

    echo "____________________"
    lsd -lha --icon always --blocks size,date,name --size short --date '+%a %d.%m.%Y'
end

function fish_prompt
    printf '\n┌──(\e[1;32m%s\e[0m🐠\e[1;32m%s\e[0m)-[\e[1;34m%s\e[0m]\n└─❯ ' (whoami) (hostname) (prompt_pwd)
end
EOF

source ~/.config/fish/config.fish

sh -c "$(curl -sLo- https://raw.githubusercontent.com/OxFF00FF/docker-config/refs/heads/main/install-superfile.sh)"
fish_add_path "$APK_CACHE_DIR"/Tools/superfile/bin
