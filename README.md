# PureShell

A [Quickshell](https://quickshell.org) shell for Hyprland in creamy white (`#edeae4`) and one warm charcoal ink:
Google Sans Flex, Material Symbols, soft round shapes and springy motion.

It's the shell half of the `pure` rice in my [dotfiles](https://github.com/BugzySleeps/bugzysdotfiles), which
provide the colours (the `rice` theme switcher writes `~/.local/state/rice/palette.json`), the fonts and the
helper scripts it calls. `rice pure` switches to it.

## What's in it

- **the island** (the default): a cream pill at the top that's the clock, with the workspaces and the status
  either side. It springs open for what's happening, then shrinks back: volume and brightness, a new track (the
  cover, the title, a few bars moving with it), notifications.
- **the bar** (`barStyle: "bar"`): a slim cream bar along the top instead, the workspaces on the left, the
  status on the right and the island in the middle.
- **the wallpaper**: drawn by the shell, fading between them. Any wallpaper works; the cream stays cream.

More is on the way: the control centre, a launcher, music, shaped desktop widgets, settings.

## Run it

```sh
rice pure                         # from the dotfiles: the theme, then this shell
qs -c pureshell                   # or just the shell
qs -c pureshell ipc call settings barStyle bar     # the bar instead of the island ("island" back)
```

## Needs

- Quickshell (Qt 6.9+), Hyprland 0.57+ (its Lua config)
- Google Sans Flex and Material Symbols Rounded (in the dotfiles' `fonts/`)
- PipeWire, NetworkManager, UPower; `brightnessctl` for brightness; `cava` for the moving bars

## Licence

See [LICENSE](LICENSE): free to run and to change for yourself, not to copy into other projects or republish.
