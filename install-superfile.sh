#!/bin/bash

green='\033[0;32m'
red='\033[0;31m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
white='\033[0;37m'
bright_red='\033[1;31m'
bright_green='\033[1;32m'
bright_yellow='\033[1;33m'
bright_blue='\033[1;34m'
bright_purple='\033[1;35m'
bright_cyan='\033[1;36m'
bright_white='\033[1;37m'
nc='\033[0m'

echo -e '
\033[0;31m                                                    ______   __  __
\033[1;31m                                                   /      \ /  |/  |
\033[0;33m  _______  __    __   ______    ______    ______  /$$$$$$  |$$/ $$ |  ______
\033[1;33m /       |/  |  /  | /      \  /      \  /      \ $$ |_ $$/ /  |$$ | /      \
\033[0;32m/$$$$$$$/ $$ |  $$ |/$$$$$$  |/$$$$$$  |/$$$$$$  |$$   |    $$ |$$ |/$$$$$$  |
\033[1;32m$$      \ $$ |  $$ |$$ |  $$ |$$    $$ |$$ |  $$/ $$$$/     $$ |$$ |$$    $$ |
\033[0;34m $$$$$$  |$$ \__$$ |$$ |__$$ |$$$$$$$$/ $$ |      $$ |      $$ |$$ |$$$$$$$$/
\033[1;34m/     $$/ $$    $$/ $$    $$/ $$       |$$ |      $$ |      $$ |$$ |$$       |
\033[0;35m$$$$$$$/   $$$$$$/  $$$$$$$/   $$$$$$$/ $$/       $$/       $$/ $$/  $$$$$$$/
\033[1;35m                    $$ |
\033[0;31m                    $$ |
\033[1;31m                    $$/
'

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------

install_root="/mnt/host/c/.apk-cache/Tools/superfile"
install_dir="${install_root}/bin"
temp_root="${install_root}/tmp"

# -------------------------------------------------------------------
# Create directories
# -------------------------------------------------------------------

if ! mkdir -p "$install_dir" "$temp_root"; then
    echo -e "${red}❌ Failed to create installation directories.${nc}"
    exit 1
fi

# -------------------------------------------------------------------
# Temporary directory
# -------------------------------------------------------------------

temp_dir=$(mktemp -d "${temp_root}/superfile.XXXXXX")

if [ $? -ne 0 ]; then
    echo -e "${red}❌ Failed to create temporary directory.${nc}"
    exit 1
fi

cleanup() {
    rm -rf "$temp_dir"
}

trap cleanup EXIT

# -------------------------------------------------------------------
# Get latest version
# -------------------------------------------------------------------

fetch_latest_version() {
    local response
    local version

    if ! response=$(curl -fsSL --max-time 10 \
        "https://api.github.com/repos/yorukot/superfile/releases/latest"); then

        echo -e "${red}❌ Failed to fetch latest version from GitHub API.${nc}" >&2
        exit 1
    fi

    version=$(echo "$response" |
        grep '"tag_name"' |
        head -n 1 |
        cut -d'"' -f4 |
        sed 's/^v//')

    if [ -z "$version" ]; then
        echo -e "${red}❌ Failed to parse latest version.${nc}" >&2
        exit 1
    fi

    echo "$version"
}

# -------------------------------------------------------------------
# Detect version, architecture and OS
# -------------------------------------------------------------------

package="superfile"

version="${SPF_INSTALL_VERSION:-$(fetch_latest_version)}"

arch=$(uname -m)
os=$(uname -s)

case "$arch" in
    x86_64|amd64)
        arch="amd64"
        ;;

    arm*|aarch64|arm64)
        arch="arm64"
        ;;

    *)
        echo -e "${red}❌ Unsupported architecture: ${arch}${nc}"
        exit 1
        ;;
esac

case "$os" in
    Linux)
        os="linux"
        ;;

    Darwin)
        os="darwin"
        ;;

    *)
        echo -e "${red}❌ Unsupported operating system: ${os}${nc}"
        exit 1
        ;;
esac

file_name="${package}-${os}-v${version}-${arch}"

url="https://github.com/yorukot/superfile/releases/download/v${version}/${file_name}.tar.gz"

# -------------------------------------------------------------------
# Download
# -------------------------------------------------------------------

cd "$temp_dir" || exit 1

echo -e "${bright_yellow}Downloading ${cyan}${package} v${version} for ${os} (${arch})...${nc}"

if command -v curl >/dev/null 2>&1; then
    if ! curl -fL -O "$url"; then
        echo -e "${red}❌ Failed to download superfile.${nc}"
        exit 1
    fi

elif command -v wget >/dev/null 2>&1; then
    if ! wget -q "$url"; then
        echo -e "${red}❌ Failed to download superfile.${nc}"
        exit 1
    fi

else
    echo -e "${red}❌ Neither curl nor wget is installed.${nc}"
    exit 1
fi

# -------------------------------------------------------------------
# Extract
# -------------------------------------------------------------------

echo -e "${bright_yellow}Extracting ${cyan}${package}...${nc}"

if ! tar -xzf "${file_name}.tar.gz"; then
    echo -e "${red}❌ Failed to extract superfile.${nc}"
    exit 1
fi

# -------------------------------------------------------------------
# Locate binary
# -------------------------------------------------------------------

binary="./dist/${file_name}/spf"

if [ ! -f "$binary" ]; then
    echo -e "${red}❌ Binary not found:${nc} ${binary}"
    exit 1
fi

# -------------------------------------------------------------------
# Install
# -------------------------------------------------------------------

echo -e "${bright_yellow}Installing ${cyan}${package}...${nc}"
echo -e "${white}Destination: ${cyan}${install_dir}/spf${nc}"

chmod +x "$binary"

if ! mv "$binary" "${install_dir}/spf"; then
    echo -e "${red}❌ Failed to move binary to:${nc}"
    echo -e "${red}${install_dir}/spf${nc}"
    exit 1
fi

# -------------------------------------------------------------------
# Add to PATH
# -------------------------------------------------------------------

case "$SHELL" in

    */fish)
        fish_config="${HOME}/.config/fish/config.fish"

        mkdir -p "$(dirname "$fish_config")"

        if ! grep -Fq "$install_dir" "$fish_config" 2>/dev/null; then
            echo "fish_add_path ${install_dir}" >> "$fish_config"
            echo -e "${yellow}${install_dir}${yellow} has been added to Fish PATH.${nc}"
        fi

        ;;

    */bash)
        bash_config="${HOME}/.bashrc"

        if ! grep -Fq "$install_dir" "$bash_config" 2>/dev/null; then
            echo "export PATH=\"${install_dir}:\${PATH}\"" >> "$bash_config"
            echo -e "${yellow}${install_dir}${yellow} has been added to Bash PATH.${nc}"
        fi

        ;;

    */zsh)
        zsh_config="${HOME}/.zshrc"

        if ! grep -Fq "$install_dir" "$zsh_config" 2>/dev/null; then
            echo "export PATH=\"${install_dir}:\${PATH}\"" >> "$zsh_config"
            echo -e "${yellow}${install_dir}${yellow} has been added to Zsh PATH.${nc}"
        fi

        ;;

    *)
        echo -e "${yellow}Unsupported shell: ${SHELL}${nc}"
        echo -e "${yellow}Add this directory to your PATH manually:${nc}"
        echo -e "${cyan}${install_dir}${nc}"
        ;;

esac

# -------------------------------------------------------------------
# Finish
# -------------------------------------------------------------------

echo
echo -e "🎉 ${bright_green}Installation complete!${nc}"
echo
echo -e "${bright_cyan}Binary:${nc}"
echo -e "  ${white}${install_dir}/spf${nc}"
echo
echo -e "${bright_cyan}Run:${nc}"
echo -e "  ${bright_yellow}spf${nc}"
echo

case "$SHELL" in
    */fish)
        echo -e "${yellow}Run this to reload Fish configuration:${nc}"
        echo -e "  ${cyan}source ~/.config/fish/config.fish${nc}"
        ;;

    */bash)
        echo -e "${yellow}Run this to reload Bash configuration:${nc}"
        echo -e "  ${cyan}source ~/.bashrc${nc}"
        ;;

    */zsh)
        echo -e "${yellow}Run this to reload Zsh configuration:${nc}"
        echo -e "  ${cyan}source ~/.zshrc${nc}"
        ;;
esac
