/* -----------------------------------------------------
 * Walker — Everforest Glass theme
 * Palette: sainnhe/everforest (dark medium)
 * TEMPLATE: edit style.css.tpl, not style.css. The @ef_* palette
 * is prepended by ~/.config/hypr/scripts/wallcolors.py and
 * follows the wallpaper.
 * ----------------------------------------------------- */

@define-color window_bg_color  alpha(@ef_bg_dim, 0.55);
@define-color accent_bg_color  @ef_green;
@define-color theme_fg_color   @ef_fg;
@define-color error_bg_color   @ef_red;
@define-color error_fg_color   @ef_bg0;

* {
    all: unset;
    font-family: "JetBrainsMono Nerd Font", "Fira Sans Semibold", sans-serif;
}

.normal-icons { -gtk-icon-size: 16px; }
.large-icons  { -gtk-icon-size: 32px; }

scrollbar { opacity: 0; }

/* outer wrapper — the glass card */
.box-wrapper {
    background: alpha(@ef_bg0, 0.55);
    border: 1px solid alpha(@ef_green, 0.30);
    border-radius: 18px;
    padding: 16px;
    box-shadow:
        inset 0 1px 0 alpha(@ef_fg, 0.10),
        0 18px 40px rgba(0, 0, 0, 0.45),
        0 0 0 1px alpha(@ef_fg, 0.04);
    color: @ef_fg;
}

.preview-box,
.elephant-hint,
.placeholder {
    color: @ef_grey1;
}

.box { }

/* search bar */
.search-container {
    background: alpha(@ef_bg_dim, 0.55);
    border: 1px solid alpha(@ef_green, 0.30);
    border-radius: 12px;
    padding: 2px 8px;
    margin-bottom: 12px;
    box-shadow: inset 0 1px 0 alpha(@ef_fg, 0.08);
}

.input {
    background: transparent;
    padding: 10px 6px;
    color: @ef_fg;
    caret-color: @ef_green;
    font-size: 15px;
}

.input placeholder { color: @ef_grey0; opacity: 1; }
.input:focus,
.input:active { }

.content-container { }
.placeholder { color: @ef_grey0; padding: 16px; }
.scroll { }

.list { color: @ef_fg; }

child { }

/* result rows */
.item-box {
    background: transparent;
    border: 1px solid transparent;
    border-radius: 10px;
    padding: 8px 10px;
    margin: 2px 0;
    transition: all 150ms ease;
}

.item-box:hover {
    background: alpha(@ef_green, 0.08);
    border-color: alpha(@ef_green, 0.18);
}

child:selected .item-box,
.item-box:selected {
    background: alpha(@ef_green, 0.18);
    border-color: alpha(@ef_green, 0.45);
    box-shadow:
        inset 0 1px 0 alpha(@ef_green, 0.22),
        0 0 10px alpha(@ef_green, 0.18);
    color: @ef_fg;
}

.item-text {
    color: @ef_fg;
    font-weight: 500;
}

.item-sub,
.item-subtext {
    color: @ef_grey1;
    font-size: 11px;
}

child:selected .item-text { color: #ffffff; }
child:selected .item-sub,
child:selected .item-subtext { color: @ef_green; }

.item-icon { -gtk-icon-size: 24px; padding-right: 10px; }

/* keybind / shortcut hint chips */
.activation-label,
.keybind,
.shortcut {
    background: alpha(@ef_blue, 0.18);
    color: @ef_blue;
    border: 1px solid alpha(@ef_blue, 0.35);
    border-radius: 6px;
    padding: 1px 6px;
    font-size: 11px;
    margin-left: 6px;
}

/* category headers */
.category,
.list-section-header {
    color: @ef_grey1;
    font-size: 11px;
    padding: 6px 4px 2px 4px;
    margin-top: 6px;
}
