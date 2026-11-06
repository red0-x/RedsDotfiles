// Tray overlay: the same rice colourway for every app icon.
// Waybar's tray is disabled; a matching spacer reserves this slot.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: tray
    required property var ctx
    property var items: (SystemTray.items ? SystemTray.items.values : [])
        .filter(t => t.status !== 0)
    readonly property int iconSize: 16
    readonly property int step: 24
    readonly property int maxW: 260
    // Click an app icon -> jump to its window (and workspace). Falls back to
    // launching the app, then to the tray item's own activate().
    function addr(t) {
        const a = t?.address ?? "";
        return a.startsWith("0x") ? a : "0x" + a;
    }
    function appKey(id) {
        return (id || "").toLowerCase()
            .replace(/_status_icon_\d+$/, "").replace(/_status_icon$/, "");
    }
    function focusApp(id) {
        const key = appKey(id);
        if (key.length < 3) return false;
        const top = (Hyprland.toplevels ? Hyprland.toplevels.values : []);
        let t = top.find(tl => {
            const cls = ((tl.lastIpcObject?.class ?? "") + " " + (tl.lastIpcObject?.initialClass ?? "")).toLowerCase();
            return cls.split(" ").some(c => c.length > 2 && (c.includes(key) || key.includes(c)));
        });
        if (!t && key.length > 3) t = top.find(tl => ((tl.title ?? "")).toLowerCase().includes(key));
        if (!t) return false;
        const ws = t.lastIpcObject?.workspace?.id ?? t.workspace?.id ?? 0;
        if (ws > 0) Hyprland.dispatch("workspace " + ws);
        Hyprland.dispatch("focuswindow address:" + addr(t));
        return true;
    }
    readonly property var commands: ({
        "discord": "discord", "spotify": "spotify", "slack": "slack",
        "obs": "obs", "steam": "steam", "mullvad": "mullvad-vpn",
        "claude": "claude-desktop", "easyeffects": "easyeffects"
    })
    function launchFor(id) {
        const key = appKey(id);
        for (const k in commands) {
            if (key.includes(k)) {
                Quickshell.execDetached(["sh", "-c", commands[k] + " >/dev/null 2>&1 < /dev/null &"]);
                return true;
            }
        }
        return false;
    }
    function pretty(t) {
        let s = t.title || t.id || "";
        s = s.replace(/_status_icon_\d+$/, "").replace(/_status_icon$/, "").replace(/[_-]+/g, " ").trim();
        return s.charAt(0).toUpperCase() + s.slice(1);
    }
    readonly property int wantW: Math.min(maxW, items.length * (iconSize + 8) + Math.max(0, items.length - 1) * 4 + 16)

    screen: Quickshell.screens.length ? Quickshell.screens[0] : null
    visible: true
    anchors.top: true
    anchors.right: true
    margins.top: 3
    margins.right: 6
    implicitWidth: Math.max(1, wantW)
    implicitHeight: 56
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:tray"
    color: "transparent"

    Rectangle {
        id: chip
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 30
        radius: 12
        color: ctx.glass(0.55)
        border.width: 1
        border.color: ctx.edge
        clip: true

        Row {
            anchors.centerIn: parent
            spacing: 4
            Repeater {
                model: tray.items
                delegate: Item {
                    required property var modelData
                    readonly property bool vpn: (modelData.id ?? "").toLowerCase().includes("mullvad")
                    // uniform rice glyphs for known apps; unknown ones keep a tinted icon
                    readonly property string glyph: {
                        const s = ((modelData.id ?? "") + " " + (modelData.title ?? "")).toLowerCase();
                        if (s.includes("mullvad")) return "\uf3ed";
                        if (s.includes("discord")) return "\uf392";
                        if (s.includes("slack")) return "\uf198";
                        if (s.includes("spotify")) return "\uf1bc";
                        if (s.includes("steam")) return "\uf1b6";
                        if (s.includes("claude")) return "\uf544";
                        if (s.includes("obs")) return "\uf03d";
                        if (s.includes("effeeffects") || s.includes("easyeffects")) return "\uf1de";
                        return "";
                    }
                    readonly property color tone: vpn
                        ? (ctx.vpnConnected ? ctx.cAccL : ctx.cRed)
                        : (ma.containsMouse ? ctx.cFg : ctx.cText)
                    readonly property string iconSrc: {
                        const s = modelData.icon ?? "";
                        if (!s) return "";
                        if (s.startsWith("/") || s.includes("://")) return s;
                        return Quickshell.iconPath(s, "");
                    }
                    width: tray.iconSize + 8; height: tray.iconSize + 4

                    // ColorOverlay keeps the icon's alpha shape but paints it in the
                    // rice colour; the VPN item gets green/red so its state is visible.
                    Image {
                        id: iconImg
                        anchors.fill: parent
                        anchors.margins: 2
                        source: iconSrc
                        sourceSize { width: tray.iconSize; height: tray.iconSize }
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        visible: false
                    }
                    ColorOverlay {
                        visible: glyph === ""
                        anchors.fill: iconImg
                        source: iconImg
                        color: vpn
                            ? (ctx.vpnConnected ? ctx.cAccL : ctx.cRed)
                            : (ma.containsMouse ? ctx.cFg : ctx.cText)
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: glyph !== ""
                        text: glyph
                        color: tone
                        font.family: "Font Awesome 6 Free"
                        font.weight: Font.Black
                        font.pixelSize: 13
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: glyph === "" && iconImg.status !== Image.Ready && iconImg.status !== Image.Loading
                        text: "\uf1b2"
                        color: tone
                        font.family: "Font Awesome 6 Free"
                        font.weight: Font.Black
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            ctx.trayClicks++;
                            ctx.trayLast = (modelData.id ?? "?") + ":" + mouse.button;
                            if (mouse.button === Qt.RightButton) { modelData.secondaryActivate(); return; }
                            if (mouse.button === Qt.MiddleButton) { modelData.activate(); return; }
                            if (!tray.focusApp(modelData.id) && !tray.launchFor(modelData.id))
                                modelData.activate();
                        }
                        onEntered: ctx.trayTip = tray.pretty(modelData)
                        onExited: if (ctx.trayTip.length) ctx.trayTip = ""
                    }
                    HoverHandler { id: muHover }
                }
            }
        }
    }

    Rectangle {
        visible: ctx.trayTip !== ""
        anchors { left: parent.left; right: parent.right; top: chip.bottom; topMargin: 4 }
        height: 20
        radius: 10
        color: ctx.glass(0.94)
        border.width: 1
        border.color: ctx.edge
        Text {
            anchors.centerIn: parent
            width: parent.width - 10
            text: ctx.trayTip
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            color: ctx.cText
            font.family: ctx.font; font.pixelSize: 10
        }
    }
}
