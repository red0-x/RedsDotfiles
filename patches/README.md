# Application rice patches

These patches contain only the rice changes, with no local paths, account data, or generated assets. Apply them to the pinned base commit shown for each project. Run `git apply --check` before `git apply`.

## Jcode status islands

Base commit: `0b03b8e995859d96ecec4bd497c28b91ba16ffed`.

```bash
git clone https://github.com/red0-x/isodev.git
cd isodev
git checkout 0b03b8e995859d96ecec4bd497c28b91ba16ffed
git apply --check /path/to/RedsDotfiles/patches/jcode-rice-islands.patch
git apply /path/to/RedsDotfiles/patches/jcode-rice-islands.patch
cargo build --release
install -m755 target/release/jcode ~/.local/bin/jcode
```

The patch adds matugen-painted status and notification islands, responsive clipping, and spinner fast-path coverage. It preserves the fork's voice input, Discord RPC, and word-level inline diffs.

## Quickshell overview styling

Base commit: `0f59ce38a3e528df66e46203d9e19a6a924761fc`.

```bash
git clone https://github.com/Shanu-Kumawat/quickshell-overview.git
cd quickshell-overview
git checkout 0f59ce38a3e528df66e46203d9e19a6a924761fc
git apply --check /path/to/RedsDotfiles/patches/quickshell-overview-rice.patch
git apply /path/to/RedsDotfiles/patches/quickshell-overview-rice.patch
```

Install the resulting overview at `~/.config/quickshell/overview`. The Matugen template at `.config/matugen/templates/quickshell-overview.qml` regenerates its `common/Appearance.colors.qml` on wallpaper changes. Restart the overview after applying the patch or changing its template.
