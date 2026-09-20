# Icon source and original assets

`new-icon-source.png` is the source image used to generate the custom app icon.
The `current-*` files are unchanged copies of the upstream icon assets kept as
a local fallback.

- `current-app-and-tray-icon.ico`: executable icon and notification-area icon. The ICO currently contains one 256 x 256, 32-bit image.
- `current-app-icon-256.png`: highest-resolution unplated app-list icon from the `logo-44` asset family.
- `current-square-tile-600.png`: 600 x 600 MSIX square-tile asset, including the existing safe-area padding.
- `current-protocol-icon-52.png`: 52 x 52 protocol-handler icon.

Run `scripts/Generate-AppIcons.ps1 -Source icon-export/new-icon-source.png` to
regenerate the scale and target-size PNG families under
`ThreeFingerDragOnWindows/Assets`.
