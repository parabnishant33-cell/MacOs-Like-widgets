# macOS-Like Widgets for Linux

A clean, macOS-inspired desktop widget collection built with **Eww** for Linux.

## Features

- 📅 Date, clock, and calendar
- 🔆 Brightness and volume controls
- 🎵 Music player with playback controls
- ✅ Interactive to-do list
- 🌑 Translucent dark styling inspired by macOS

## Requirements

- Linux with Eww installed
- `playerctl`
- `brightnessctl`
- `wireplumber`
- `zenity`
- `util-linux`
- `curl`

## Installation

Clone this repository:
git clone https://github.com/parabnishant33-cell/MacOs-Like-widgets.git
cd MacOs-Like-widgets


Run the installer:

chmod +x install.sh
./install.sh


Start the widgets:


~/.config/eww/run.sh


Close the widgets:

eww close-all

## Notes

- Review `install.sh` before running it.
- The installer creates configuration files in `~/.config/eww`.
- Some dependencies and Eww settings may need adjustments for your Linux desktop environment.
- These are community-made widgets and are not affiliated with Apple.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
