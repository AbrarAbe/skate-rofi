#!/usr/bin/env sh

# Set variables
# Path to the GPG encrypted password file
SKATE_PASSWORD_FILE="your_gpg_encrypted_password.gpg"
roconf="${HOME}/.config/rofi/skate.rasi"

# Decrypt the password from the GPG file
# Use --batch and --no-tty to prevent gpg from trying to prompt for passphrase
# Assumes gpg-agent is running and configured to handle passphrase prompting (e.g., via pinentry)
if [ ! -f "$SKATE_PASSWORD_FILE" ]; then
    notify-send "Skate" "Error: GPG password file not found at $SKATE_PASSWORD_FILE."
    exit 1
fi
decrypted_password=$(gpg --quiet --batch --no-tty --decrypt "$SKATE_PASSWORD_FILE" 2>/dev/null | tr -d '[:space:]')

# Check if decryption was successful
if [ -z "$decrypted_password" ]; then
    notify-send "Skate" "Failed to decrypt password file. Make sure gpg-agent is running and configured to handle passphrase prompting."
    exit 1
fi

# Set default values for Rofi and Hyprland variables
rofiScale=10
hypr_border=2
hypr_width=3

# Set rofi scaling
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=10
r_scale="configuration {font: \"JetBrainsMono Nerd Font 9\";}"
wind_border=$((hypr_border * 3))
elem_border=$([ $hypr_border -eq 0 ] && echo "5" || echo $hypr_border)

# Evaluate spawn position
readarray -t curPos < <(hyprctl cursorpos -j | jq -r '.x,.y')
readarray -t monRes < <(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width,.height,.scale,.x,.y')
readarray -t offRes < <(hyprctl -j monitors | jq -r '.[] | select(.focused==true).reserved | map(tostring) | join("\n")')
monRes[2]="$(echo "${monRes[2]}" | sed "s/\.//")"
monRes[0]="$(( ${monRes[0]} * 100 / ${monRes[2]} ))"
monRes[1]="$(( ${monRes[1]} * 100 / ${monRes[2]} ))"
curPos[0]="$(( ${curPos[0]} - ${monRes[3]} ))"
curPos[1]="$(( ${curPos[1]} - ${monRes[4]} ))"

if [ "${curPos[0]}" -ge "$((${monRes[0]} / 2))" ] ; then
    x_pos="east"
    x_off="-$(( ${monRes[0]} - ${curPos[0]} - ${offRes[2]} ))"
else
    x_pos="west"
    x_off="$(( ${curPos[0]} - ${offRes[0]} ))"
fi

if [ "${curPos[1]}" -ge "$((${monRes[1]} / 2))" ] ; then
    y_pos="south"
    y_off="-$(( ${monRes[1]} - ${curPos[1]} - ${offRes[3]} ))"
else
    y_pos="north"
    y_off="$(( ${curPos[1]} - ${offRes[1]} ))"
fi

r_override="window{location:${x_pos} ${y_pos};anchor:${x_pos} ${y_pos};x-offset:${x_off}px;y-offset:${y_off}px;border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
pass_override="window{height:6.6em;width:25%;location:${x_pos} ${y_pos};anchor:${x_pos} ${y_pos};x-offset:${x_off}px;y-offset:${y_off}px;border:${hypr_width}px;border-radius:${wind_border}px;} mainbox{children: [ "wallbox" ];} wallbox{expand:true;border-radius:${elem_border}px;} element{border-radius:${elem_border}px;} listbox{enabled:false;} element{enabled:false;}"
value_override="window{width:50%;}"

# Password prompt using Rofi
entered_password=$(echo "" | rofi -dmenu -password -theme-str "entry { placeholder: \"Enter password\";}" -theme-str "${r_scale}" -theme-str "${pass_override}" -config "${roconf}")

# Check if password is correct
if [ -z "$entered_password" ]; then
    exit 0 # Script was likely cancelled
elif [ "$entered_password" != "$decrypted_password" ]; then
    notify-send "skate-rofi" "Incorrect password."
    exit 1
fi

# Show main menu if no arguments are passed
if [ $# -eq 0 ]; then
main_action=$(echo -e "Store a key\\nGet a key\\nList keys\\nList databases" | rofi -dmenu -theme-str "entry { placeholder: \"Skate - Choose action...\";}" -theme-str "${r_scale}" -theme-str "${r_override}" -config "${roconf}")
else
    # Default action if an argument is passed (e.g., skate set key value)
    # Note: This assumes the first argument is the command and rest are arguments
    command="$1"
    shift # remove command from arguments
    case "$command" in
        set|get|list|list-dbs)
            skate "$command" "$@"
            notify-send "Executed: skate $command $@"
            ;;
        *)
            notify-send "Unknown command: $command"
            echo "Unknown command: $command"
            exit 1
            ;;
    esac
    exit 0 # Exit after processing arguments
fi

case "${main_action}" in
"Store a key")
    # Prompt for key
    key=$(echo "" | rofi -dmenu -theme-str "entry { placeholder: \"Enter key...\";}" -theme-str "${r_scale}" -theme-str "${pass_override}" -config "${roconf}")
    if [ -n "$key" ]; then
        # Prompt for value (allow multi-line input if needed, Rofi handles this)
        value=$(echo "" | rofi -dmenu -theme-str "entry { placeholder: \"Enter value...\";}" -theme-str "${r_scale}" -theme-str "${pass_override}" -theme-str "${value_override}" -config "${roconf}")
        if [ -n "$value" ]; then
            skate set "$key" "$value"
            notify-send "Key '$key' set."
        else
            notify-send "Set cancelled: No value entered."
        fi
    else
        notify-send "Set cancelled: No key entered."
    fi
    ;;
"Get a key")
    # List available keys using skate list -k
    selected_key=$(skate list -k | rofi -dmenu -theme-str "entry { placeholder: \"Select key to get...\";}" -theme-str "${r_scale}" -theme-str "${r_override}" -config "${roconf}")
    if [ -n "$selected_key" ]; then
        # Get the value for the selected key and copy to clipboard
        skate get "$selected_key" | wl-copy
        notify-send "Value for key '$selected_key' copied to clipboard."
    fi
;;
"List keys")
    # List all key-value pairs
        skate_list_output=$(skate list)
    if [ -n "$skate_list_output" ]; then
        echo "$skate_list_output" | rofi -dmenu -theme-str "entry { placeholder: \"Skate List...\";}" -theme-str "${r_scale}" -theme-str "${r_override}" -config "${roconf}"
    else
        notify-send "Skate is empty."
    fi
    ;;
"List databases")
    # List available databases
    skate_db_list_output=$(skate list-dbs)
    if [ -n "$skate_db_list_output" ]; then
        echo "$skate_db_list_output" | rofi -dmenu -theme-str "entry { placeholder: \"Skate Databases...\";}" -theme-str "${r_scale}" -theme-str "${r_override}" -config "${roconf}"
    else
        notify-send "No databases found."
    fi
    ;;
"Process_Args")
    # If arguments were passed, treat them as skate commands
    # Example: skate.sh set key value
    # This simple implementation assumes the first argument is the command (set, get, list, list-dbs)
    # and the rest are arguments to that command.
    command="$1"
    shift # remove command from arguments
    case "$command" in
        set|get|list|list-dbs)
            skate "$command" "$@"
            notify-send "Executed: skate $command $@"
            ;;
        *)
            notify-send "Unknown command: $command"
            echo "Unknown command: $command"
            exit 1
            ;;
    esac
    ;;
*)
    exit 1
    ;;
esac