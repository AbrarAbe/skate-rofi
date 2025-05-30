# Skate-Rofi

A Rofi-based interface for interacting with the `skate` key-value store.

![bitmap](https://github.com/user-attachments/assets/d06283be-bcfa-406e-98f0-822b6a4158ab)


## Description

This script provides a convenient way to manage your `skate` data using Rofi, a versatile window switcher and application launcher. It allows you to set, get, list, and manage databases within your `skate` store through a user-friendly menu. This project is inspired by the simplicity of `skate` and the flexibility of `rofi`.

## Dependencies

*   [Rofi](https://github.com/davatorium/rofi)
*   [Skate](https://github.com/charmbracelet/skate)
*   `gpg` (for password encryption)
*   `wl-copy` (or `xclip` for X11)
*   `jq`
*   `hyprctl` (optional, for dynamic positioning)

## Installation

1.  Install dependencies (check your distribution's package manager).
2.  Copy the `.local/bin/skate.sh` script to a location in your `$PATH` (e.g., `~/.local/bin/`).
3.  Make the script executable: `chmod +x ~/.local/bin/skate.sh`.
4.  Copy the `.config/rofi/skate.rasi` file to `~/.config/rofi/`.
5. Alternatively, you can clone the repository to your home directory.

## Configuration

1.  **GPG Password Encryption:**
    *   Create a file with your desired password.
    *   Encrypt it using GPG: `gpg --encrypt --armor --recipient "Your Name <your.email@example.com>"` your_password_file
    *   Replace `"Your Name <your.email@example.com>"` with your GPG User ID.
    *   Securely delete the original password file.
    *   Update the `SKATE_PASSWORD_FILE` variable in `skate.sh` with the path to your GPG encrypted file.
2.  **Rofi Theme:**
    *   The script uses `~/.config/rofi/skate.rasi` for its Rofi theme. Customize this file to match your desktop.

## Hyprdots Configuration

If you're using [Hyprdots](https://github.com/prasanthrangan/hyprdots), Hyprdots-specific configurations are available in the `hyprdots` branch of this repository.

To use the Hyprdots configuration:

*  **Clone the branch:** `git clone https://AbrarAbe/skate-rofi -b hyprdots --single-branch`

Alternatively, if you already have the repository cloned:

*  **Checkout the `hyprdots` branch:** `git checkout hyprdots`

## Usage

1.  Bind the `skate.sh` script to a key combination in your window manager (e.g., Hyprland).
2.  When you run the script, it will prompt for your password (decrypted from the GPG file).
3.  After successful authentication, a Rofi menu will appear, allowing you to:
    *   Set a new key-value pair.
    *   Get the value of a key (and copy it to the clipboard).
    *   List all keys and values.
    *   List available databases.

## Security Considerations

*   **Password Security:** This script uses GPG to encrypt the password, but remember that the security of your setup depends on the strength of your GPG passphrase and the security of your GPG key.
*   **Screen Exposure:** Be mindful of screen exposure when listing all key-value pairs, as this will display all your `skate` data.

## Credits

*   This project uses [Rofi](https://github.com/davatorium/rofi) as its core interface.
*   This project provides a convenient interface to [Skate](https://github.com/charmbracelet/skate), a personal key-value store.
