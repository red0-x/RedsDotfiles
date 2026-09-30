#!/usr/bin/env python3
"""
wallcolors.py - Everforest-shaped palette that follows the wallpaper.

Picks the most vivid hue in the wallpaper, then rotates the Everforest
palette onto it in OKLCH (same lightness + softness, new hue). Muted /
greyscale wallpapers fall back to stock Everforest.

Usage:
  wallcolors.py IMAGE            generate from wallpaper
  wallcolors.py --hex '#d56367'  force an accent color
  wallcolors.py --everforest     stock Everforest
Prints the accent hex on stdout (fed to `matugen color hex`).

Pin an accent permanently: echo '#d56367' > ~/.config/ml4w/settings/rice-accent
Disable following (always Everforest): echo everforest > same file
"""
import math, os, sys
from pathlib import Path

HOME = Path.home()
CFG = HOME / ".config"

# sainnhe/everforest dark medium + extra tones used by the glass theme
EVERFOREST = {
    "bg_dim": "#232a2e", "bg0": "#2d353b", "bg1": "#343f44", "bg2": "#3d484d",
    "bg3": "#475258", "bg4": "#4b5a5f",
    "fg": "#d3c6aa", "fg_bright": "#e6dcc2", "fg_dim": "#c5c0a8",
    "grey0": "#7a8478", "grey1": "#859289", "grey2": "#9da9a0",
    "red": "#e67e80", "red_deep": "#c85a5c",
    "orange": "#e69875", "yellow": "#dbbc7f", "yellow_deep": "#b4965a",
    "green": "#a7c080", "aqua": "#83c092", "blue": "#7fbbb3", "purple": "#d699b6",
    # bright text accents for waybar modules
    "l_green": "#c2dba0", "l_blue": "#a8d5cf", "l_yellow": "#ecd49b",
    "l_aqua": "#a7dab2", "l_orange": "#efb89a", "l_purple": "#e6bbcd",
    "l_red": "#ee9ea0",
}
BACKGROUNDS = {"bg_dim", "bg0", "bg1", "bg2", "bg3", "bg4"}
NEUTRALS = {"fg", "fg_bright", "fg_dim", "grey0", "grey1", "grey2"}
FIXED = {"red", "red_deep"}          # semantic danger stays red
ANCHOR = "green"                     # everforest's primary accent

# ---------------------------------------------------------------- OKLab
def _lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
def _gam(c): return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055

def rgb_to_oklch(r, g, b):
    r, g, b = _lin(r), _lin(g), _lin(b)
    l = (0.4122214708*r + 0.5363325363*g + 0.0514459929*b) ** (1/3)
    m = (0.2119034982*r + 0.6806995451*g + 0.1073969566*b) ** (1/3)
    s = (0.0883024619*r + 0.2817188376*g + 0.6299787005*b) ** (1/3)
    L = 0.2104542553*l + 0.7936177850*m - 0.0040720468*s
    a = 1.9779984951*l - 2.4285922050*m + 0.4505937099*s
    bb = 0.0259040371*l + 0.7827717662*m - 0.8086757660*s
    return L, math.hypot(a, bb), math.degrees(math.atan2(bb, a)) % 360

def oklch_to_rgb(L, C, H):
    a, b = C * math.cos(math.radians(H)), C * math.sin(math.radians(H))
    l = (L + 0.3963377774*a + 0.2158037573*b) ** 3
    m = (L - 0.1055613458*a - 0.0638541728*b) ** 3
    s = (L - 0.0894841775*a - 1.2914855480*b) ** 3
    return (_gam(4.0767416621*l - 3.3077115913*m + 0.2309699292*s),
            _gam(-1.2684380046*l + 2.6097574011*m - 0.3413193965*s),
            _gam(-0.0041960863*l - 0.7034186147*m + 1.7076147010*s))

def in_gamut(rgb): return all(-1e-4 <= c <= 1 + 1e-4 for c in rgb)

def oklch_hex(L, C, H):
    lo, hi = 0.0, C                       # shrink chroma until in sRGB
    if not in_gamut(oklch_to_rgb(L, C, H)):
        for _ in range(25):
            mid = (lo + hi) / 2
            lo, hi = (mid, hi) if in_gamut(oklch_to_rgb(L, mid, H)) else (lo, mid)
        C = lo
    return "#" + "".join(f"{round(min(1, max(0, c)) * 255):02x}" for c in oklch_to_rgb(L, C, H))

def hex_rgb(h): h = h.lstrip("#"); return tuple(int(h[i:i+2], 16) / 255 for i in (0, 2, 4))
def hex_oklch(h): return rgb_to_oklch(*hex_rgb(h))

# ---------------------------------------------------------------- hue pick
def dominant_hue(path):
    """Chroma-weighted circular hue histogram. Returns (hue, vividness) or None."""
    from PIL import Image
    img = Image.open(path).convert("RGB")
    img.thumbnail((160, 160))
    bins = [0.0] * 72                    # 5 deg bins
    total = 0.0
    for r, g, b in img.getdata():
        L, C, H = rgb_to_oklch(r / 255, g / 255, b / 255)
        if C < 0.03 or L < 0.18 or L > 0.95:
            continue
        w = C * C * (1 - abs(L - 0.62))  # favour vivid, mid-light pixels
        bins[int(H // 5) % 72] += w
        total += w
    n = len(img.getdata())
    if total == 0:
        return None
    smooth = [sum(bins[(i + k) % 72] * wk for k, wk in ((-2, .4), (-1, .8), (0, 1), (1, .8), (2, .4)))
              for i in range(72)]
    i = max(range(72), key=smooth.__getitem__)
    # weighted mean hue inside the peak window for precision
    xs = ys = 0.0
    for k in range(-3, 4):
        j = (i + k) % 72; ang = math.radians(j * 5 + 2.5)
        xs += bins[j] * math.cos(ang); ys += bins[j] * math.sin(ang)
    hue = math.degrees(math.atan2(ys, xs)) % 360
    return hue, total / n

# everforest-nvim "hard" dark palette (neovim uses background = "hard")
NVIM_BASE = {
    "bg_dim": "#1e2326", "bg0": "#272e33", "bg1": "#2e383c", "bg2": "#374145",
    "bg3": "#414b50", "bg4": "#495156", "bg5": "#4f5b58",
    "bg_visual": "#4c3743", "bg_red": "#493b40", "bg_green": "#3c4841",
    "bg_blue": "#384b55", "bg_yellow": "#45443c", "bg_purple": "#463f48",
    "fg": "#d3c6aa", "red": "#e67e80", "orange": "#e69875", "yellow": "#dbbc7f",
    "green": "#a7c080", "aqua": "#83c092", "blue": "#7fbbb3", "purple": "#d699b6",
    "grey0": "#7a8478", "grey1": "#859289", "grey2": "#9da9a0",
    "statusline1": "#a7c080", "statusline2": "#d3c6aa", "statusline3": "#e67e80",
}
NVIM_BG = {"bg_dim", "bg0", "bg1", "bg2", "bg3", "bg4", "bg5"}
NVIM_NEUTRAL = {"fg", "grey0", "grey1", "grey2", "statusline2"}
NVIM_FIXED = {"red", "statusline3", "bg_red"}

# ---------------------------------------------------------------- palette
def build(target_hue, base=EVERFOREST, bgs=BACKGROUNDS, neutrals=NEUTRALS, fixed=FIXED):
    if target_hue is None:
        return dict(base)
    anchor_h = hex_oklch(EVERFOREST[ANCHOR])[2]
    delta = target_hue - anchor_h
    out = {}
    for k, hx in base.items():
        L, C, H = hex_oklch(hx)
        if k in fixed:
            out[k] = hx
        elif k in bgs:
            out[k] = oklch_hex(L, max(C, 0.012), target_hue)       # tinted glass
        elif k in neutrals:
            out[k] = oklch_hex(L, min(C, 0.03), (target_hue + 40) % 360)  # warm-ish text
        else:
            out[k] = oklch_hex(L, C, (H + delta) % 360)
    return out

# ---------------------------------------------------------------- writers
def rgb255(hx): return ",".join(str(round(c * 255)) for c in hex_rgb(hx))

def write_if(path, text):
    path = Path(path)
    if path.parent.exists():
        path.write_text(text)

def cava_gradient(p, target_hue):
    """Stock: everforest rainbow. Wallpaper: analogous ramp of the accent hue,
    deep/saturated at the bar base -> bright/pale at the peaks."""
    if target_hue is None:
        return [p["blue"], p["aqua"], p["green"], p["yellow"], p["orange"], p["red"]]
    out = []
    for i in range(6):
        t = i / 5
        L = 0.56 + 0.30 * t                 # 0.56 -> 0.86
        C = 0.13 - 0.06 * t                 # vivid base, softer tips
        H = (target_hue - 18 + 36 * t) % 360  # slight analogous sweep
        out.append(oklch_hex(L, C, H))
    return out

def write_all(p, source, target_hue=None):
    hdr = f"generated by wallcolors.py from {source}"
    css = f"/* {hdr} */\n" + "".join(f"@define-color ef_{k} {v};\n" for k, v in p.items())
    write_if(CFG / "waybar/rice-palette.css", css)

    # walker: GTK4 theme = palette + template body
    wdir = CFG / "walker/themes/everforest"
    tpl = wdir / "style.css.tpl"
    if tpl.exists():
        (wdir / "style.css").write_text(css + "\n" + tpl.read_text())

    h = {k: v.lstrip("#") for k, v in p.items()}
    hypr = (f"# {hdr}\n"
            + "".join(f"$ef_{k} = rgb({v})\n" for k, v in h.items())
            + f"$rice_active_border = rgba({h['green']}ee) rgba({h['aqua']}cc) rgba({h['blue']}aa) 45deg\n"
            + f"$rice_inactive_border = rgba({h['bg0']}88)\n"
            + f"$rice_rim_inner = rgba({h['aqua']}cc)\n"
            + f"$rice_rim_outer = rgba({h['bg0']}66)\n")
    write_if(CFG / "hypr/colors-rice.conf", hypr)

    # tmux: full color block, sourced by ~/.tmux.conf and live-reloaded
    t = p
    tmux = f"""# {hdr}
set -g status-style "bg=default,fg={t['fg']}"
set -g status-left "#[fg={t['green']}]\ue0b6#[bg={t['green']},fg={t['bg0']},bold] #S #[bg=default,fg={t['green']}]\ue0b4#[default] "
set -g status-right "#[fg={t['bg1']}]\ue0b6#[bg={t['bg1']},fg={t['grey1']}] #{{b:pane_current_path}} #[bg={t['bg1']},fg={t['bg2']}]|#[bg={t['bg1']},fg={t['blue']}] #h #[bg=default,fg={t['bg1']}]\ue0b4#[default] #[fg={t['bg1']}]\ue0b6#[bg={t['bg1']},fg={t['yellow']}] %H:%M #[bg=default,fg={t['bg1']}]\ue0b4#[default] "
setw -g window-status-format "#[fg={t['bg_dim']}]\ue0b6#[bg={t['bg_dim']},fg={t['grey1']}] #I #W #[bg=default,fg={t['bg_dim']}]\ue0b4#[default]"
setw -g window-status-current-format "#[fg={t['bg2']}]\ue0b6#[bg={t['bg2']},fg={t['green']},bold] #I #W #[bg=default,fg={t['bg2']}]\ue0b4#[default]"
setw -g window-status-activity-style "fg={t['yellow']}"
setw -g window-status-bell-style "fg={t['yellow']}"
set -g pane-border-style "fg={t['bg2']}"
set -g pane-active-border-style "fg={t['green']}"
set -g message-style "bg={t['bg1']},fg={t['fg']}"
set -g message-command-style "bg={t['bg1']},fg={t['fg']}"
set -g mode-style "bg={t['green']},fg={t['bg0']}"
set -g display-panes-active-colour "{t['green']}"
set -g display-panes-colour "{t['grey1']}"
set -g clock-mode-colour "{t['green']}"
"""
    (CFG / "tmux").mkdir(exist_ok=True)
    (CFG / "tmux/rice-colors.conf").write_text(tmux)

    # cava gradient (in place)
    cava = CFG / "cava/config"
    if cava.exists():
        grad = cava_gradient(p, target_hue)
        lines, out = cava.read_text().splitlines(), []
        for ln in lines:
            s = ln.strip()
            for i in range(1, 7):
                if s.startswith(f"gradient_color_{i} ") or s.startswith(f"gradient_color_{i}="):
                    ln = f"gradient_color_{i} = '{grad[i-1]}'"
            out.append(ln)
        cava.write_text("\n".join(out) + "\n")

def main(argv):
    pin = CFG / "ml4w/settings/rice-accent"
    target, source = None, "everforest"
    forced = pin.read_text().strip() if pin.exists() else ""
    if len(argv) > 1 and argv[1] == "--hex":
        forced = argv[2]
    elif len(argv) > 1 and argv[1] == "--everforest":
        forced = "everforest"

    if forced == "everforest":
        pass
    elif forced.startswith("#"):
        target, source = hex_oklch(forced)[2], forced
    elif len(argv) > 1:
        res = dominant_hue(argv[1])
        # threshold: below this the wallpaper is basically grey -> stock
        if res and res[1] > 0.0004:
            target, source = res[0], os.path.basename(argv[1])
    p = build(target)
    write_all(p, source, target)

    # neovim: everforest-nvim palette override (watched live by nvim)
    import json
    nv = build(target, NVIM_BASE, NVIM_BG, NVIM_NEUTRAL, NVIM_FIXED)
    nvf = HOME / ".cache/rice/nvim-palette.json"
    nvf.parent.mkdir(parents=True, exist_ok=True)
    tmp = nvf.with_suffix(".tmp")
    tmp.write_text(json.dumps({"source": source, "palette": nv}, indent=1))
    tmp.replace(nvf)                     # atomic: nvim never reads a half file

    print(p["green"])

if __name__ == "__main__":
    main(sys.argv)
