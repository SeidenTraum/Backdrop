#!/bin/bash

# This script is designed to change the desktop wallpaper on a system using the Sway window manager.
# The wallpapers are stored in the directory specified by the $WALL_DIR variable.
# The script utilizes the 'swaybg' command to set the wallpaper.
# It creates a symbolic link to the selected wallpaper in the $WALL_DIR/current directory and sets it as the active wallpaper.
# Note: Wallpapers should be named in a format that is either 'wallpaper' or 'wall-paper', using only lowercase letters and no spaces.
# It can sanitize the wallpaper name tho.
# Author: SeidenTraum (J.P.) @ github.com/SeidenTraum
# Date: 2024-03-15

declare YELLOW
declare RED
declare BRED
declare BLUE
declare BBLUE
declare GREEN
declare PINK
declare NC

declare -gr CONFIG
declare -gr WALL_DIR
declare -gr ENABLE_NOTIFICATIONS
declare -gr ENABLE_FZF

# Parse the config file
parse_config() {
    local key=$1
    local value
    # key = variable name
    # value = value stored inside key
    value="$(sed -n "s/^$key = \(.*\)/\1/p" "$CONFIG")"
    # This regex is used to extract the value from the config file
    echo "$value" # Writing it to stdout
    return 0
}

CONFIG="$HOME/.config/backdrop/bd.config"
WALL_DIR="$(parse_config "wallpaper_dir")"
ENABLE_NOTIFICATIONS="$(parse_config "enable_notifications")"
ENABLE_FZF="$(parse_config "enable_fzf")"

YELLOW="\033[0;33m"
RED="\033[0;31m"
BRED="\033[1;31m"
BLUE="\033[0;34m"
BBLUE="\033[1;34m"
GREEN="\033[0;32m"
PINK="\033[0;35m"
NC="\033[0m" # No Color

# Functions for output messages
error_msg() { echo -e "${BRED}! $1${NC}"; }
warning_msg() { echo -e "${YELLOW}! $1${NC}"; } # I barely used this one, will refactor the code to use it more
info_msg() { echo -e "${BLUE}$1${NC}"; }
success_msg() { echo -e "${GREEN}$1${NC}"; }
notify_user() {
    if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
        notify-send "Wallpaper changed" "New wallpaper: $1" -i "$WALL_DIR/$1" -u low -t 1000
    fi
    return 0
}

# Check for required commands
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" > /dev/null; then
        warning_msg "The command '$cmd' is not installed" # Using warning since it is not critical
        return 1
    fi
    return 0
}

# Dependency check
DEPENDENCIES=(
    "swaybg"
    )
OPTIONAL_DEPENDENCIES=(
    "wofi"
    "fzf"
    "kitty"
    )

for cmd in "${DEPENDENCIES[@]}"; do
    check_command "$cmd"
done
for cmd in "${OPTIONAL_DEPENDENCIES[@]}"; do
    declare result
    result=$(check_command "$cmd")
done

declare -g WALL_CURRENT
declare -g WALL_LIST
declare -g WALL_LIST_CLEAN
declare -g NEWNAME

WALL_CURRENT=$(readlink -fn "$WALL_DIR/current")
WALL_LIST=$(for file in "$WALL_DIR"/*; do [ "$(basename "$file")" != "current" ] && basename "$file"; done)
WALL_LIST_CLEAN=$(echo "$WALL_LIST" | sed -e 's/\.[^.]*$//' -e 's/-/ /g' -e 's/\b\(.\)/\u\1/g' | tr '[:upper:]' '[:lower:]')
NEWNAME="NONE" # Used for sanitizer

# Sanitizes the wallpaper name
sanitizer() {
    local filename
    local sanitized_name

    filename="${1%.*}" # Remove file extension
    sanitized_name=$(echo "$filename" | sed -e 's/-/ /g' -e 's/\b\(.\)/\u\1/g' | tr '[:upper:]' '[:lower:]')
    NEWNAME="${sanitized_name// /-}" # Change whitespaces to `-`
    [ "$extension" ] && NEWNAME="$NEWNAME.$extension"
}

sanitize_dir() {
    local file
    for file_path in "$WALL_DIR"/*; do
        file="$(basename "$file_path")"
        printf "${BLUE}File: ${GREEN}%s${NC}\n" "$file"

        if [ "$file" = "current" ]; then
            info_msg "Skipped"
            continue
        fi

        sanitizer "$file"
        local new_file_path="$WALL_DIR/$NEWNAME"

        if [ -f "$new_file_path" ]; then
            success_msg "Wallpaper follows patterns."
            continue
        fi

        info_msg "Renaming $file to $NEWNAME"
        if mv "$file_path" "$new_file_path"; then
            success_msg "Successfully renamed $file to $NEWNAME"
        else
            error_msg "An error occurred while renaming $file to $NEWNAME"
            return 1
        fi
    done
}

wofi_set() {
    # Uses wofi to change the wallpaper
    local result
    result=$(echo "$WALL_LIST_CLEAN" | wofi --dmenu --prompt "Change wallpaper")
    echo "$result"
    return 0
}

fuzzy_search() {
    if [ "$ENABLE_FZF" = "true" ]; then
        local input="$1"
        local pattern="$2"
        local result
        if [ -z "$input" ]; then
            return 1
        fi
        result=$(echo "$input" | fzf -i -1 -0 -f "$pattern")
        echo "$result"
        return 0
    fi
    return 0
}

# Adds a wallpaper to WALL_DIR
add_wallpaper() {
    if [ -z "$1" ]; then
        error_msg "No argument was given"
        return 1
    fi

    if [ ! -e "$1" ]; then
        error_msg "The wallpaper does not exist"
        return 1
    fi

    sanitizer "$1"

    if [ -f "$WALL_DIR/$NEWNAME" ]; then
        error_msg "The wallpaper already exists"
        return 1
    fi

    mv "$1" "$WALL_DIR/$NEWNAME"
    success_msg "Wallpaper added to $WALL_DIR"
    return 0
}

# Removes a wallpaper from WALL_DIR
remove_wallpaper() {
    if [ -z "$1" ]; then
        error_msg "No argument was given"
        return 1
    fi

    sanitizer "$1"

    if [ ! -e "$WALL_DIR/$NEWNAME" ]; then
        error_msg "The wallpaper does not exist"
        return 1
    fi

    rm "$WALL_DIR/$NEWNAME"
    success_msg "The wallpaper: $WALL_DIR/$NEWNAME has been removed"
    return 0
}

# Display help message
show_help() {
    info_msg "A simple script to manage wallpapers in ${YELLOW}Hyprland."
    info_msg "Author: ${YELLOW}Cookie${RED}Fiend${NC}"
    info_msg "Usage: ${GREEN}backdrop ${YELLOW}[wallpaper name]${NC}   : Sets wallpaper"
    info_msg "       ${GREEN}backdrop ${YELLOW}-l, --list${NC}         : List all wallpapers"
    info_msg "       ${GREEN}backdrop ${YELLOW}-f, --fuzzy${NC}        : Fuzzy search for wallpaper"
    info_msg "       ${GREEN}backdrop ${YELLOW}-w, --wofi${NC}        : Use wofi to change wallpaper"
    info_msg "       ${GREEN}backdrop ${YELLOW}-c, --current${NC}      : Display current wallpaper"
    info_msg "       ${GREEN}backdrop ${YELLOW}-a, --add${NC}          : Add wallpaper"
    info_msg "       ${GREEN}backdrop ${YELLOW}-r, --remove${NC}       : Remove wallpaper"
    info_msg "       ${GREEN}backdrop ${YELLOW}-p, --preview${NC}      : Preview wallpaper"
    info_msg "       ${GREEN}backdrop ${YELLOW}-h, --help${NC}         : Display this help"
    info_msg "       ${GREEN}backdrop ${YELLOW}-ss, --sanitize${NC}    : Sanitize wallpaper directory"
    info_msg "       ${GREEN}backdrop ${YELLOW}-rr, --reset${NC}       : Reset wallpaper"
    info_msg "       ${GREEN}backdrop ${YELLOW}-dd, --dir${NC}         : Echoes wallpaper directory"
}

# Main function to manage wallpapers
wall_man() {
    if [ -z "$WALLNAME" ]; then
        error_msg "No argument was given"
        return 1
    fi

    case "$WALLNAME" in
        -l|--list)
            info_msg "${BBLUE}ALL WALLPAPERS:${NC}"
            info_msg "${BBLUE}--------------${NC}"
            local -i color=0
            while IFS= read -r wallpaper; do
                if [ "$color" -eq 0 ]; then
                    info_msg "${GREEN}$wallpaper${NC}"
                    color+=1
                elif [ "$color" -eq 1 ]; then
                    info_msg "${YELLOW}$wallpaper${NC}"
                    color+=1
                elif [ "$color" -eq 2 ]; then
                    info_msg "${RED}$wallpaper${NC}"
                    color+=1
                elif [ "$color" -eq 3 ]; then
                    info_msg "${PINK}$wallpaper${NC}"
                    color+=1
                else 
                    color=0
                fi
            done <<< "$WALL_LIST_CLEAN"
            info_msg "${BBLUE}--------------${NC}"
            return 0
            ;;
        -h|--help)
            show_help
            return 0
            ;;
        -c|--current)
            CLEAN_NAME=$(echo "$WALL_CURRENT" | sed -e 's/\.[^.]*$//' -e 's/-/ /g' -e 's/\b\(.\)/\u\1/g' -e 's|^.*/||')
            info_msg "Current Wallpaper: ${GREEN}$CLEAN_NAME${NC}"
            return 0
            ;;
        -a|--add)
            if [ -z "$2" ]; then
                error_msg "No argument was given"
                return 1
            fi
            add_wallpaper "$2"
            return 0
            ;;
        -r|--remove)
            if [ -z "$2" ]; then
                error_msg "No argument was given"
                return 1
            fi
            remove_wallpaper "$2"
            return 0
            ;;
        -p|--preview)
            if [ -z "$2" ]; then
                error_msg "No argument was given"
                return 1
            fi
            check_command "kitty"
            sanitizer "$2"
            kitty +kitten icat --silent "$WALL_DIR/$NEWNAME"
            return 0
            ;;
        -rr|--reset)
            killall swaybg
            swaybg -i "$WALL_DIR/current" -m fill &>/dev/null & disown
            return 0
            ;;
        -dd|--dir)
            echo "$WALL_DIR"
            return 0
            ;;
        -f|--fuzzy)
            WALLNAME=$(echo "$WALL_LIST" | fzf -i -1 -0)
            ;;
        -ss|--sanitize)
            info_msg "Sanitizing wallpaper directory..."
            sanitize_dir
            info_msg "Sanitization complete"
            return 0
            ;;
        -w|--wofi)
            WALLNAME=$(wofi_set)
            ;;
        *)
            # Concatenate all arguments if no flag is provided
            if [ "$#" -gt 1 ]; then
                WALLNAME="$*"
            fi
            ;;
    esac

    # Checking if it has any '-' in the start of the argument
    if [[ "$WALLNAME" =~ ^-.* ]]; then
        error_msg "Invalid argument: $WALLNAME"
        return 1
    fi

    WALLNAME="${WALLNAME,,}"
    WALLNAME="${WALLNAME// /-}"

    # Check if the wallpaper exists
    if [ ! -f "$WALL_DIR/$WALLNAME" ]; then
        error_msg "The wallpaper ${YELLOW}${WALLNAME}${RED} does not exist"
        info_msg "Trying to find the wallpaper by pattern matching..."
        WALLNAME=${WALLNAME%.png} # removing .png from $WALLNAME
        WALLNAME=$(fuzzy_search "$WALL_LIST" "$WALLNAME")
        if [ -z "$WALLNAME" ]; then
            error_msg "The wallpaper ${YELLOW}${WALLNAME}${RED} was not found by pattern matching"
            return 1
        fi
        # checking if the list is bigger than 1
        if [ "$(echo "$WALLNAME" | wc -l)" -gt 1 ]; then
            warning_msg "The wallpaper was found multiple times\n${YELLOW}${WALLNAME}${NC}"
            return 1
        fi
        success_msg "The wallpaper was found by pattern matching!!"
    fi

    if pgrep -f "swaybg" &> /dev/null; then
        pkill -f "swaybg" >/dev/null 2>&1
    fi

    # Removing the path from $WALL_CURRENT
    WALL_CURRENT=${WALL_CURRENT##*/}    

    if [ "$WALLNAME" != "$WALL_CURRENT" ]; then
        ln -fsn "$WALL_DIR/$WALLNAME" "$WALL_DIR/current"
        if (swaybg -i "$WALL_DIR/current" -m fill &>/dev/null & disown); then
            success_msg "Wallpaper was changed successfully!!"
            info_msg "> $WALLNAME"
            notify_user "$WALLNAME"
        else
            error_msg "An error occurred while changing wallpaper"
            exit 1
        fi
    else
        if (swaybg -i "$WALL_DIR/current" -m fill &>/dev/null & disown); then
            success_msg "Wallpaper was changed successfully!!"
            info_msg "> $WALLNAME"
            notify_user "$WALLNAME"
        else
            error_msg "An error occurred while changing wallpaper"
            exit 1
        fi
    fi
}

# Checking if config file exists
if [ ! -f "$CONFIG" ]; then
    error_msg "The config file does not exist"
    exit 1
fi

# Execute main function
WALLNAME="${1,,}"
wall_man "$@"
