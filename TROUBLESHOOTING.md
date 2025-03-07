## 🛠️ Troubleshooting

**Known Issues**

1. **[TERMINFO](https://ghostty.org/docs/help/terminfo) `xterm-ghostty` not-set/breaks functionality**

   **Fix:** Set the TERMINFO value to `xterm-256color` at runtime by running the AppImage as follows,

   ```bash
   # Option 1
   ❯ TERM=xterm-256color ./Ghostty-${VERSION}-${ARCH}.AppImage

   # Option 2: Add `export TERM=xterm-256color` to your .bashrc or .zshrc and launch the appimage normally
   ```

1. **Gtk-CRITICAL \*\*: 13:43:27.628: gtk_widget_unparent: assertion 'GTK_IS_WIDGET (widget)' failed**

   **Fix:** Referenced in [#3267](https://github.com/ghostty-org/ghostty/discussions/3267), reported/resolved at [#32](https://github.com/psadi/ghostty-appimage/issues/32)

_If you encounter any errors, check the terminal for error messages that may indicate missing dependencies or other issues_
