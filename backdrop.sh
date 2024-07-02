#!/bin/bash

# Backdrop is a script to help manage wallpapers
# author: SeidemTraum (J.P) @github.com/SeidemTraum
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# Global variables
declare -g CONFIG
declare -g WALLNAME
declare -g WALL_DIR
declare -g ENABLE_NOTIFICATIONS
declare -g ENABLE_FZF
declare -g WALL_CURRENT
declare -g WALL_LIST
declare -g WALL_LIST_CLEAN
declare -g NEWNAME

# Color codes
declare -r YELLOW="\033[0;33m"
declare -r RED="\033[0;31m"
declare -r BRED="\033[1;31m"
declare -r BLUE="\033[0;34m"
declare -r BBLUE="\033[1;34m"
declare -r GREEN="\033[0;32m"
declare -r PINK="\033[0;35m"
declare -r NC="\033[0m" # No Color

# Dependencies
declare -ga DEPENDENCIES
declare -ga OPTIONAL_DEPENDENCIES

# Functions for output messages
error_msg() { echo -e "${BRED}! $1${NC}"; }
warning_msg() { echo -e "${YELLOW}! $1${NC}"; } # I barely used this one, will refactor the code to use it more
info_msg() { echo -e "${BLUE}$1${NC}"; }
success_msg() { echo -e "${GREEN}$1${NC}"; }
debug_msg() { if [ "$DEBUG" == "true" ]; then echo -e "${PINK}:: $1${NC}"; fi }
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

config_create() {
    # Creates config file with default values
    local -A defaults
    # Checking every relevant variable exists
    if [ "$1" == "skip-touch" ]; then
        touch "$CONFIG"
    fi
    messageInfo "Configuration file created at '$CONFIG'"
    printf "[ Config ]\n" > "$CONFIG"
    defaults=([wallpaper_dir]="$HOME/Pictures/Wallpapers" \
                         [enable_notifications]="true" \
                         [enable_fzf]="true")

    for key in "${!defaults[@]}"; do
        printf "%s=%s\n" "$key" "${defaults[$key]}"
    done >> "$CONFIG"
    messageInfo "Configuration file populated with defaults"
}

config_add() {
    # Changes a value in the config file, $1 = key, $2 = value
    local key="$1"
    local value="$2"

    if checkEmpty "$key"; then
        messageError "Key cannot be empty"
        return 1
    fi
    if checkEmpty "$value"; then
        messageError "Value cannot be empty"
        return 1
    fi
    if ! grep -q "$key" "$CONFIG"; then
        messageError "Key does not exist"
        return 1
    fi

    sed -i "/$key/c$key=$value" "$CONFIG"
}

# Parse the config file
config_parse() {
    local key=$1
    local value
    # Checking if the bd.config file exists
    if [ ! -f "$CONFIG" ]; then
        error_msg "The config file does not exist"
        exit 1
    fi
    # key = variable name
    # value = value stored inside key
    value="$(sed -n "s/^$key = \(.*\)/\1/p" "$CONFIG")"
    # This regex is used to extract the value from the config file
    echo "$value" # Writing it to stdout
    return 0
}

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

randomizer() {
    # Randomly selects a wallpaper from a given list
    local list="$1"
    local result

    while true; do # Loops until a wallpaper other than the current one is selected
        result=$(echo "$list" | shuf -n 1)
        if [ "$result" != "$WALL_CURRENT" ]; then
            echo "$result"
            return 0
        fi
    done
    return 1
}

# Display help message
show_help() {
    info_msg "A simple script to manage wallpapers in ${YELLOW}Hyprland."
    info_msg "Usage: ${GREEN}backdrop ${YELLOW}[wallpaper name]${NC}   : Sets wallpaper"
    info_msg "       ${GREEN}backdrop ${YELLOW}-l, --list${NC}         : List all wallpapers"
    info_msg "       ${GREEN}backdrop ${YELLOW}-f, --fuzzy${NC}        : Fuzzy search for wallpaper"
    info_msg "       ${GREEN}backdrop ${YELLOW}-w, --wofi${NC}         : Use wofi to change wallpaper"
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
        # So it doesn't change the wallpaper to a invalid flag:
        # e.g.: backdrop -g | invalid argument -g
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

# Parsing config file
CONFIG="$HOME/.config/backdrop/bd.config"
WALL_DIR="$(config_parse "wallpaper_dir")"
ENABLE_NOTIFICATIONS="$(config_parse "enable_notifications")"
ENABLE_FZF="$(config_parse "enable_fzf")"

# Checking if variables are empty
if [ -z "$CONFIG" ] || [ -z "$WALL_DIR" ]; then
    error_msg "One or more variables are empty"
    exit 1
fi
if [ -z "$ENABLE_NOTIFICATIONS" ] || [ -z "$ENABLE_FZF" ]; then
    if DEBUG; then
        warning_msg "One or more optional flags are empty"
    fi
fi
debug_msg "Debug: $DEBUG"
debug_msg "Variables"
debug_msg "CONFIG: $CONFIG"
debug_msg "WALL_DIR: $WALL_DIR"
debug_msg "ENABLE_NOTIFICATIONS: $ENABLE_NOTIFICATIONS"
debug_msg "ENABLE_FZF: $ENABLE_FZF"

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
    declare result
    result=$(check_command "$cmd") # if not installed, exit
    if [ "$result" == 0 ]; then
        error_msg "The command '$cmd' is not installed"
        exit 1
    fi
    unset result
done
for cmd in "${OPTIONAL_DEPENDENCIES[@]}"; do
    check_command "$cmd"
done

WALL_CURRENT=$(readlink -fn "$WALL_DIR/current")
WALL_LIST=$(for file in "$WALL_DIR"/*; do [ "$(basename "$file")" != "current" ] && basename "$file"; done)
WALL_LIST_CLEAN=$(echo "$WALL_LIST" | sed -e 's/\.[^.]*$//' -e 's/-/ /g' -e 's/\b\(.\)/\u\1/g' | tr '[:upper:]' '[:lower:]')
NEWNAME="NONE" # Used for sanitizer

# Checking if config file exists
if [ ! -f "$CONFIG" ]; then
    error_msg "The config file does not exist"
    exit 1
fi

# Execute main function
WALLNAME="${1,,}"
wall_man "$@"

