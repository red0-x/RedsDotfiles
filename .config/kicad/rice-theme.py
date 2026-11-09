#!/usr/bin/env python3
"""Regenerate KiCad's Rice Glass colour theme from the matugen palette.

Reads the hex values matugen writes to ~/.config/waybar/colors.css and remaps
the hue-bearing roles (wires, labels, copper, silkscreen) onto the rice accent
while keeping every structural key from the Eagle Soft Amber theme.
Run manually, or via matugen's waybar post_hook (see ~/.config/matugen/config.toml).
"""
import json
import re
from pathlib import Path

HOME = Path.home()
PALETTE = HOME / ".config/waybar/colors.css"
BASE = HOME / ".config/kicad/10.0/colors/eagle_soft_amber.json"
OUT = HOME / ".config/kicad/10.0/colors/rice_glass.json"


def palette():
    css = PALETTE.read_text()
    cols = dict(re.findall(r"@define-color\s+(\w+)\s+(#[0-9a-fA-F]{6})", css))
    need = ["surface", "surface_container_low", "surface_container",
            "surface_container_high", "surface_container_highest",
            "primary", "secondary", "tertiary", "on_surface",
            "on_surface_variant", "outline", "error"]
    missing = [k for k in need if k not in cols]
    if missing:
        raise SystemExit(f"palette missing {missing}")
    return cols


def rgba(hexcol, alpha):
    h = hexcol.lstrip("#")
    return f"rgba({int(h[0:2], 16)}, {int(h[2:4], 16)}, {int(h[4:6], 16)}, {alpha})"


def build():
    c = palette()
    t = json.loads(BASE.read_text())
    t["meta"].update(name="Rice Glass", filename="rice_glass", version=5)

    s = t["schematic"]
    s.update({
        "background": c["surface"],
        "sheet_background": c["surface_container_low"],
        "grid": c["surface_container_highest"],
        "grid_axes": c["outline"],
        "cursor": c["primary"],
        "worksheet": c["outline"],
        "wire": c["primary"],
        "bus": c["secondary"],
        "bus_junction": c["secondary"],
        "junction": c["primary"],
        "component_body": c["surface_container_high"],
        "component_outline": c["tertiary"],
        "pin": c["tertiary"],
        "pin_name": c["on_surface_variant"],
        "pin_number": c["on_surface_variant"],
        "fields": c["tertiary"],
        "reference": c["primary"],
        "value": c["primary"],
        "label_local": c["primary"],
        "label_global": c["tertiary"],
        "label_hier": c["secondary"],
        "net_name": c["tertiary"],
        "sheet": c["secondary"],
        "sheet_label": c["secondary"],
        "sheet_filename": c["secondary"],
        "sheet_name": c["tertiary"],
        "sheet_fields": c["surface_container_highest"],
        "note": c["on_surface"],
        "aux_items": c["on_surface"],
        "hidden": c["surface_container_highest"],
        "page_limits": c["surface_container_high"],
        "hovered": c["primary"],
        "brightened": c["on_surface"],
        "shadow": rgba(c["primary"], 0.55),
        "erc_error": c["error"],
        "erc_warning": c["secondary"],
        "no_connect": c["error"],
    })

    b = t["board"]
    b.update({
        "background": c["surface"],
        "grid": c["surface_container_highest"],
        "grid_axes": c["outline"],
        "cursor": c["primary"],
        "edge_cuts": c["outline"],
        "f_silks": c["on_surface"],
        "b_silks": c["on_surface_variant"],
        "f_fab": rgba(c["on_surface_variant"], 0.6),
        "b_fab": rgba(c["on_surface_variant"], 0.45),
        "f_crtyd": c["tertiary"],
        "b_crtyd": rgba(c["tertiary"], 0.6),
        "f_mask": rgba(c["primary"], 0.35),
        "b_mask": rgba(c["primary"], 0.25),
        "through_hole_pad": c["primary"],
        "via_hole": c["surface"],
        "via_through": c["primary"],
        "via_blind_buried": c["secondary"],
        "via_micro": c["tertiary"],
    })
    copper = b.setdefault("copper", {})
    copper.update({"f": c["primary"], "b": c["secondary"]})
    for i, key in enumerate([k for k in copper if k.startswith("in")], start=1):
        copper[key] = c["tertiary"] if i % 2 else c["secondary"]

    v = t["3d_viewer"]
    v.update({
        "background_top": c["surface_container_low"],
        "background_bottom": c["surface"],
        "board": rgba(c["surface_container_high"], 0.9),
        "copper": c["primary"],
        "silkscreen_top": c["on_surface"],
        "silkscreen_bottom": c["on_surface_variant"],
        "soldermask_top": rgba(c["surface"], 0.85),
        "soldermask_bottom": rgba(c["surface"], 0.9),
    })

    g = t["gerbview"]
    g.update({"background": c["surface"], "grid": c["surface_container_highest"],
              "axes": c["outline"], "dcodes": c["tertiary"]})

    OUT.write_text(json.dumps(t, indent=2) + "\n")
    print(f"wrote {OUT}")

    # Activate it. A running KiCad rewrites these files on exit, so re-run this after closing KiCad.
    for app in ("eeschema", "pcbnew"):
        p = HOME / f".config/kicad/10.0/{app}.json"
        d = json.loads(p.read_text())
        if d["appearance"].get("color_theme") != "rice_glass":
            d["appearance"]["color_theme"] = "rice_glass"
            p.write_text(json.dumps(d, indent=2) + "\n")
            print(f"activated in {app}")


if __name__ == "__main__":
    build()
