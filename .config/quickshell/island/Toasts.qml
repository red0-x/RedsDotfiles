// Modern toast overlay: top-right under the tray slot.
// Fed by ~/.cache/rice-toasts.json (notify-watch.py sniffs the session bus;
// rice-toast writes directly, e.g. from the jcode turn_end hook).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var ctx

    readonly property string home: Quickshell.env("HOME")
    property var shown: []          // [{ts, app, summary, body}]
    property real seenTs: 0
    property bool primed: false
    readonly property int cardH: 78
    readonly property int cardW: 344

    screen: Quickshell.screens.length ? Quickshell.screens[0] : null
    visible: shown.length > 0
    anchors.top: true
    anchors.right: true
    margins.top: 40
    margins.right: 6
    implicitWidth: cardW
    implicitHeight: Math.max(1, shown.length * cardH + Math.max(0, shown.length - 1) * 8)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:toasts"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    function accentFor(app) {
        const a = (app || "").toLowerCase();
        if (a.indexOf("discord") >= 0) return ctx.cAccL;
        if (a.indexOf("slack") >= 0) return ctx.cYellow;
        if (a.indexOf("signal") >= 0) return ctx.cBlue;
        if (a.indexOf("claude") >= 0) return ctx.cOrange;
        if (a.indexOf("jcode") >= 0) return ctx.cAccL;
        if (a.indexOf("spotify") >= 0) return ctx.cAcc;
        if (a.indexOf("mail") >= 0 || a.indexOf("thunder") >= 0) return ctx.cBlue;
        return ctx.cDim;
    }
    function glyphFor(app) {
        const a = (app || "").toLowerCase();
        if (a.indexOf("discord") >= 0) return "\uf392";
        if (a.indexOf("slack") >= 0) return "\uf198";
        if (a.indexOf("signal") >= 0) return "\uf012";
        if (a.indexOf("claude") >= 0) return "\uf544";
        if (a.indexOf("jcode") >= 0) return "\uf120";
        if (a.indexOf("spotify") >= 0) return "\uf1bc";
        if (a.indexOf("mail") >= 0 || a.indexOf("thunder") >= 0) return "\uf0e0";
        return "\uf0f3";
    }
    function glyphFont(app) {
        const a = (app || "").toLowerCase();
        return (a.indexOf("discord") >= 0 || a.indexOf("slack") >= 0 || a.indexOf("spotify") >= 0)
            ? "Font Awesome 6 Brands" : "Font Awesome 6 Free";
    }

    FileView {
        path: root.home + "/.cache/rice-toasts.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let data;
            try { data = JSON.parse(text()); } catch (e) { return; }
            const list = Array.isArray(data.toasts) ? data.toasts : [];
            if (!root.primed) {          // do not replay history on startup
                root.primed = true;
                root.seenTs = Date.now();
                return;
            }
            const fresh = list.filter(t => (t.ts || 0) > root.seenTs);
            if (!fresh.length) return;
            root.seenTs = Math.max(root.seenTs, ...fresh.map(t => t.ts || 0));
            let next = root.shown.slice();
            for (const t of fresh) next.push(t);
            root.shown = next.slice(-3);
        }
    }

    Timer {
        interval: 250; repeat: true; running: root.shown.length > 0; triggeredOnStart: true
        onTriggered: {
            const now = Date.now();
            const live = root.shown.filter(t => now - (t.ts || 0) < 5500);
            if (live.length !== root.shown.length) root.shown = live;
        }
    }

    Column {
        anchors.fill: parent
        spacing: 8
        Repeater {
            model: root.shown.slice().reverse()
            delegate: Rectangle {
                required property var modelData
                readonly property color accent: root.accentFor(modelData.app)
                width: root.cardW
                height: root.cardH
                radius: 18
                color: ctx.glass(0.82)
                border.width: 1
                border.color: ctx.edge
                clip: true
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: 180 } }

                // glass edge, same recipe as the bar chips
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.10)
                }
                // accent rail
                Rectangle {
                    width: 3
                    radius: 2
                    color: accent
                    anchors { left: parent.left; leftMargin: 10; top: parent.top; topMargin: 16; bottom: parent.bottom; bottomMargin: 22 }
                }
                // glyph tile
                Rectangle {
                    width: 36; height: 36; radius: 12
                    color: ctx.a(accent, 0.15)
                    border.width: 1
                    border.color: ctx.a(accent, 0.32)
                    anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter }
                    Text {
                        anchors.centerIn: parent
                        text: root.glyphFor(modelData.app)
                        color: accent
                        font.family: root.glyphFont(modelData.app)
                        font.weight: Font.Black
                        font.pixelSize: 14
                    }
                }
                // text block
                Item {
                    anchors { left: parent.left; leftMargin: 66; right: parent.right; rightMargin: 14; top: parent.top; topMargin: 12 }
                    height: parent.height - 22

                    Text {
                        id: appName
                        text: (modelData.app || "Notification").toUpperCase()
                        color: accent
                        font.family: ctx.font
                        font.pixelSize: 9
                        font.letterSpacing: 0.8
                        font.weight: Font.DemiBold
                    }
                    Text {
                        id: summary
                        anchors { left: parent.left; right: parent.right; top: appName.bottom; topMargin: 2 }
                        text: modelData.summary || modelData.body || ""
                        color: ctx.cFg
                        font.family: ctx.font
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    Text {
                        anchors { left: parent.left; right: parent.right; top: summary.bottom; topMargin: 1 }
                        visible: (modelData.body || "") !== "" && modelData.body !== modelData.summary
                        text: modelData.body
                        color: ctx.cText
                        opacity: 0.8
                        font.family: ctx.font
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }
                // lifetime hairline
                Rectangle {
                    height: 2
                    radius: 1
                    color: ctx.a(accent, 0.55)
                    anchors { left: parent.left; bottom: parent.bottom }
                    width: parent.width
                    NumberAnimation on width {
                        from: parent.width; to: 0; duration: 5500; running: true; easing.type: Easing.Linear
                    }
                }
            }
        }
    }
}
