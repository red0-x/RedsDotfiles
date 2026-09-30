#!/usr/bin/env bash
# Run from either the deployed tree or a checkout. Does not reload the desktop.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
if grep -Eq '^env = (AQ_DRM_DEVICES|WLR_DRM_DEVICES|NVD_BACKEND),' "$root/hypr/conf/custom.conf"; then
    echo 'FAIL: desktop-specific GPU override remains' >&2
    exit 1
fi
grep -q 'size = 3' "$root/hypr/conf/decorations/everforest-glass.conf"
grep -q 'passes = 1' "$root/hypr/conf/decorations/everforest-glass.conf"
grep -q '/usr/bin/python3.*wallcolors.py' "$root/hypr/scripts/wallpaper.sh"
bash -n "$root/hypr/scripts/wallpaper.sh"
/usr/bin/python3 - "$root" <<'PY'
import os, pathlib, subprocess, sys, tempfile
from PIL import Image
root = pathlib.Path(sys.argv[1])
with tempfile.TemporaryDirectory(prefix="dotfiles-check-", dir=os.environ.get("JCODE_SCRATCH_DIR")) as tmp:
    home = pathlib.Path(tmp)
    for app in ("hypr", "waybar", "tmux"):
        (home / ".config" / app).mkdir(parents=True)
    image = home / "wallpaper with spaces.png"
    Image.new("RGB", (32, 32), (60, 140, 80)).save(image)
    accent = subprocess.check_output(
        ["/usr/bin/python3", str(root / "hypr/scripts/wallcolors.py"), str(image)],
        env={**os.environ, "HOME": tmp}, text=True).strip()
    assert len(accent) == 7 and accent.startswith("#"), accent
    int(accent[1:], 16)
    assert "$rice_active_border" in (home / ".config/hypr/colors-rice.conf").read_text()
    assert "@define-color ef_green" in (home / ".config/waybar/rice-palette.css").read_text()
    assert (home / ".config/tmux/rice-colors.conf").is_file()
    assert (home / ".cache/rice/nvim-palette.json").is_file()
print("PASS: laptop settings, wallpaper syntax, and palette generation")
PY
