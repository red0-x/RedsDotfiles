// One "dynamic island" window per screen. Owned by shell.qml (property R).
// Collapsed: a thin pill over the bar centre (title + cava, or update progress).
// Hover / pinned: morphs into the music, updates, wifi or bluetooth card.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth

PanelWindow {
    id: win
    required property var ctx
    required property var modelData

    // "" | music | updates | wifi | bt | hub
    property bool hovered: false
    property string pskFor: ""
    property string pskText: ""
    property string appQuery: ""
    property int appSel: 0
    property int dSel: 0
    property string dReply: ""
    property bool barDiscordHover: false
    readonly property int discordRowH: 46
    readonly property var appList: {
        const q = appQuery.trim().toLowerCase();
        const list = ctx.apps ?? [];
        return (q ? list.filter(a => a.name.toLowerCase().includes(q)) : list).slice(0, 60);
    }
    onAppSelChanged: appListView.positionViewAtIndex(appSel, ListView.Contain)
    readonly property string mode: ctx.pinned !== "" ? ctx.pinned
        : (barDiscordHover && !ctx.hoverSuppressed && ctx.discordAny) ? "discord"
        : (hovered && !ctx.hoverSuppressed && ctx.playing) ? "music"
        : ""
    readonly property bool pill: mode === "" && ctx.shownForBar

    visible: true
    anchors.top: true
    screen: modelData
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:island"
    WlrLayershell.keyboardFocus: ctx.wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    implicitWidth: Math.max(220, maskW)
    implicitHeight: Math.max(32, maskH)
    color: "transparent"
    // The window itself is sized to the card (a mask stayed at its startup size,
    // which made only the top 32px clickable). Sizes are per-state, not animated,
    // so the surface is not resized on every frame.
    // The collapsed pill sizes itself to its content (workspace chips + cava +
    // title). A fixed 220px mask clipped long track titles at the window edge.
    readonly property int pillContentWidth: Math.max(64, pillRow.implicitWidth + 30)
    readonly property int maskW: win.mode === "" ? Math.max(220, pillContentWidth)
        : win.mode === "music" ? 460 : win.mode === "updates" ? 470
        : win.mode === "discord" ? 470
        : win.mode === "apps" ? 460 : win.mode === "hub" ? 330 : 410
    readonly property int maskH: win.mode === "" ? 32
        : win.mode === "music" ? 156
        : win.mode === "updates" ? ((ctx.upState === "running" || ctx.upState === "done"
            || ctx.upState === "failed" || ctx.upState === "checking") ? 168 : 316)
        : win.mode === "apps" ? 424
        : win.mode === "discord" ? 452
        : win.mode === "hub" ? 118 : win.mode === "bt" ? 290 : 300

    onModeChanged: {
        ctx.cardOpen = mode !== "";
        // scan only while the wifi card is up
        if (ctx.wifiDev) ctx.wifiDev.scannerEnabled = (mode === "wifi");
        if (mode === "apps") {
            win.appQuery = ""; win.appSel = 0;
            ctx.wantsKeyboard = true;
            Qt.callLater(() => appField.forceActiveFocus());
        }
        if (mode === "discord") {
            win.dSel = 0;
            ctx.wantsKeyboard = true;
        }
        if (mode !== "discord" && ctx.pinned !== "discord") win.dReply = "";
    }

    HyprlandFocusGrab {
        windows: [win]
        active: ctx.pinned !== "" && ctx.pinned !== "music"
        onCleared: ctx.unpin()
    }


    // Qt/Wayland delivers clicks but no hover events to this layer surface,
    // so track the cursor ourselves. 150ms poll, only while a card can expand.
    function pointerMoved(line) {
        const m = line.match(/(-?\d+),\s*(-?\d+)/);
        if (!m) return;
        const px = +m[1], py = +m[2];
        const x0 = Math.round((win.screen ? win.screen.width - win.width : 0) / 2) + shell.x;
        const r = win.mode === "" ? pillRect : card;
        const inside = x0 + r.x <= px && px < x0 + r.x + r.width
                    && shell.y + r.y <= py && py < shell.y + r.y + r.height;
        // waybar RPC chip: first module in modules-left, fixed 150px at x=8
        // waybar RPC chip: first module (x=8, ~32px wide, icon-only)
        // hover the bar chip, then keep it open while the pointer is on the card
        // (otherwise moving from the chip to the card would switch to music)
        const onRpcChip = (px >= 2 && px <= 48 && py <= 34)
            || (win.mode === "discord" && inside);
        if (onRpcChip !== win.barDiscordHover) win.barDiscordHover = onRpcChip;
        ctx.barHover = onRpcChip;
        ctx.polls++;
        // dismissed with the pointer still on it? stay shut until it leaves
        if (!inside && !onRpcChip) ctx.hoverSuppressed = false;
        if (inside && ctx.hoverSuppressed) return;
        if (inside !== win.hovered) win.hovered = inside;
        ctx.anyHovered = win.hovered;
    }
    // The loop exits when qs dies (kill -0 $PPID), so restarts do not leave
    // orphaned hyprctl pollers behind.
    Process {
        running: ctx.pinned === ""
        command: ["sh", "-c", "while kill -0 $PPID 2>/dev/null; do hyprctl cursorpos; sleep 0.15; done"]
        stdout: SplitParser { onRead: data => win.pointerMoved(data) }
    }

    Item {
        id: shell
        anchors.fill: parent

        // ---------------------------------------------------------- the pill
        Rectangle {
            id: pillRect
            visible: win.pill
            anchors.horizontalCenter: parent.horizontalCenter
            y: 1
            height: 30
            width: win.pillContentWidth
            radius: 15
            color: win.mode === "" ? ctx.glass(0.82) : ctx.glass(0.55)
            border.width: 1
            border.color: ctx.edge
            clip: true
            Behavior on width { SpringAnimation { spring: 4; damping: 0.35 } }
            Behavior on color { ColorAnimation { duration: 220 } }

            // progress hairline while updating
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 2
                visible: ctx.upState === "running"
                color: ctx.a(ctx.cAcc, 0.25)
                Rectangle {
                    height: parent.height
                    width: parent.width * ctx.upProgress
                    color: ctx.cAcc
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }
            }

            Row {
                id: pillRow
                anchors.centerIn: parent
                spacing: 6
                height: parent.height

                // Workspaces as little glass chips: idle chips are barely
                // visible, hover lifts them, the active one springs wider and
                // glows in the rice accent.
                Repeater {
                    model: ctx.playing || ctx.upState === "running" ? 0 : ctx.workspaces
                    delegate: Rectangle {
                        id: wsChip
                        required property var modelData
                        readonly property bool active: modelData.id === ctx.activeWorkspace
                        anchors.verticalCenter: parent.verticalCenter
                        width: active ? 32 : 26
                        height: 24
                        radius: 12
                        color: active ? ctx.a(ctx.cAcc, 0.88)
                            : wsMa.containsMouse ? ctx.a(ctx.cFg, 0.13)
                            : ctx.a(ctx.cFg, 0.05)
                        border.width: 1
                        border.color: active ? ctx.a("#ffffff", 0.22)
                            : wsMa.containsMouse ? ctx.a(ctx.cAcc, 0.45) : ctx.edge
                        antialiasing: true
                        scale: wsMa.pressed ? 0.9 : 1
                        Behavior on width { SpringAnimation { spring: 4.2; damping: 0.42; epsilon: 0.3 } }
                        Behavior on color { ColorAnimation { duration: 190; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 190 } }
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                        Text {
                            id: num
                            anchors.centerIn: parent
                            text: modelData.name && !/^[0-9]+$/.test(modelData.name) ? String(modelData.name) : String(modelData.id)
                            color: active ? ctx.cBg0 : ctx.cText
                            opacity: active ? 1 : 0.85
                            font.family: ctx.font
                            font.pixelSize: 11
                            font.weight: active ? Font.DemiBold : Font.Normal
                            Behavior on color { ColorAnimation { duration: 190 } }
                        }
                        MouseArea {
                            id: wsMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ctx.focusWorkspace(modelData.id)
                        }
                    }
                }
                Cava {
                    visible: ctx.playing
                    bars: ctx.bars
                    color: ctx.cAcc
                    width: 46; height: 16
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: ctx.playing && ctx.title.length > 0
                    text: ctx.title
                    color: ctx.cFg
                    font.family: ctx.font
                    font.pixelSize: 12
                    width: Math.min(implicitWidth, 320)
                    elide: Text.ElideRight
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !ctx.playing && ctx.upState === "running"
                    text: "\uf019  " + Math.round(ctx.upProgress * 100) + "%"
                    color: ctx.cFg
                    font.family: ctx.iconFont; font.weight: Font.Black; font.pixelSize: 12
                }
            }

            TapHandler { onTapped: ctx.pinned === "" ? ctx.show(ctx.playing ? "music" : "updates") : ctx.unpin() }
        }

        // ---------------------------------------------------------- the card
        Rectangle {
            id: card
            visible: win.mode !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            y: 1
            width: win.mode === "music" ? 460 : win.mode === "updates" ? 470
                    : win.mode === "discord" ? 470 : win.mode === "hub" ? 330 : 410
            height: win.mode === "music" ? 156
                    : win.mode === "updates" ? ((ctx.upState === "running" || ctx.upState === "done" || ctx.upState === "failed" || ctx.upState === "checking") ? 168 : 316)
                    : win.mode === "apps" ? 424
                    : win.mode === "discord" ? 452
        : win.mode === "hub" ? 118 : win.mode === "bt" ? 290 : 300
            radius: 22
            color: ctx.glass(0.74)
            border.width: 1
            border.color: ctx.edge
            clip: true
            opacity: win.mode === "" ? 0 : 1
            scale: win.mode === "" ? 0.92 : 1

            Behavior on width { SpringAnimation { spring: 3.6; damping: 0.32; epsilon: 0.3 } }
            Behavior on height { SpringAnimation { spring: 3.6; damping: 0.32; epsilon: 0.3 } }
            Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

            // pinned cards need an explicit close (hover-out will not dismiss them)
            Btn {
                visible: ctx.pinned !== ""
                glyph: "\uf00d"
                tip: "Close"
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 8
                anchors.rightMargin: 8
                onClicked: ctx.unpin()
            }

            // glass highlight, matching the waybar chips
            Rectangle {   // glass edge: hairline highlight + inner ring
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
                height: 1
                color: Qt.rgba(1, 1, 1, 0.10)
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius - 1
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.05)
            }
            // ==================================================== MUSIC
            Item {
                anchors.fill: parent
                anchors.margins: 12
                visible: win.mode === "music"
                opacity: win.mode === "music" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Rectangle {   // art / live video / fallback
                    id: art
                    width: 132; height: 132
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 16
                    clip: true
                    color: ctx.a(ctx.cAcc, 0.14)

                    Image {
                        anchors.fill: parent
                        visible: ctx.artUrl !== "" && !ctx.videoLive
                        source: ctx.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }
                    ScreencopyView {
                        anchors.fill: parent
                        visible: ctx.videoLive
                        captureSource: ctx.videoLive ? ctx.videoToplevel : null
                        live: true
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: ctx.artUrl === "" && !ctx.videoLive
                        text: ctx.title.length ? ctx.title.charAt(0).toUpperCase() : "\uf001"
                        color: ctx.cAccL
                        font.family: ctx.title.length ? ctx.font : ctx.iconFont
                        font.weight: Font.Black
                        font.pixelSize: 46
                    }
                    Cava {   // inline visualiser over the art
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8 }
                        height: 18
                        bars: ctx.bars
                        color: ctx.cAccL
                        visible: ctx.playing
                    }
                    TapHandler { onTapped: ctx.raisePlayer() }
                }

                Item {
                    anchors.left: art.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    Text {
                        id: mTitle
                        width: parent.width - playBtn.width - 8
                        text: ctx.title || "Nothing playing"
                        color: ctx.cFg
                        font.family: ctx.font; font.pixelSize: 15
                        elide: Text.ElideRight
                    }
                    Text {
                        id: mSub
                        anchors.top: mTitle.bottom
                        anchors.topMargin: 2
                        width: parent.width - playBtn.width - 8
                        text: ctx.artist !== "" ? ctx.artist + (ctx.album !== "" ? " · " + ctx.album : "") : (ctx.player?.identity ?? "")
                        color: ctx.cDim
                        font.family: ctx.font; font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    // seek line (click to seek)
                    Item {
                        id: seek
                        anchors.top: mSub.bottom
                        anchors.topMargin: 12
                        width: parent.width
                        height: 14
                        readonly property real len: ctx.player?.length ?? 0
                        readonly property real pos: ctx.player?.position ?? 0
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: 4; radius: 2
                            color: ctx.a(ctx.cFg, 0.12)
                            Rectangle {
                                height: parent.height; radius: 2
                                width: seek.len > 0 ? parent.width * Math.min(1, seek.pos / seek.len) : 0
                                color: ctx.cAcc
                            }
                        }
                        TapHandler {
                            onTapped: point => {
                                if (!ctx.player?.canSeek || seek.len <= 0) return;
                                const target = (point.position.x / seek.width) * seek.len;
                                ctx.player.seek(target - seek.pos);
                            }
                        }
                    }
                    Text {
                        id: times
                        anchors.top: seek.bottom
                        width: parent.width
                        text: ctx.fmt(ctx.player?.position) + "   /   " + ctx.fmt(ctx.player?.length)
                        color: ctx.cDim
                        font.family: ctx.font; font.pixelSize: 10
                    }

                    Row {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        spacing: 6

                        Btn { glyph: "\uf049"; tip: "Previous"; enabled: ctx.player?.canGoPrevious ?? false; onClicked: ctx.player.previous() }
                        Btn {
                            glyph: ctx.playing ? "\uf04c" : "\uf04b"
                            tip: ctx.playing ? "Pause" : "Play"
                            big: true
                            enabled: ctx.player?.canTogglePlaying ?? false
                            onClicked: ctx.player.togglePlaying()
                        }
                        Btn { glyph: "\uf051"; tip: "Next"; enabled: ctx.player?.canGoNext ?? false; onClicked: ctx.player.next() }
                        Btn {
                            glyph: ctx.liked ? "\uf004" : "\uf08a"
                            tip: ctx.isSpotify ? (ctx.liked ? "Remove from Liked Songs (Alt+Shift+B)" : "Like (Alt+Shift+B)") : "Open player"
                            enabled: ctx.player !== null
                            accent: ctx.liked
                            onClicked: ctx.isSpotify ? ctx.likeSpotify() : ctx.raisePlayer()
                        }
                        Btn { glyph: "\uf08e"; tip: "Open player window"; enabled: ctx.player !== null; onClicked: ctx.raisePlayer() }
                    }

                    Row {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        spacing: 4
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: ctx.realPlayers.length > 1
                            text: (ctx.player?.identity ?? "")
                            color: ctx.cDim; font.family: ctx.font; font.pixelSize: 9
                        }
                    }

                    // play/pause overlay badge (appears on hover of the card)
                    Rectangle {
                        id: playBtn
                        visible: false
                        width: 1; height: 1
                    }
                }
            }

            // ==================================================== UPDATES
            Item {
                anchors.fill: parent
                anchors.margins: 14
                visible: win.mode === "updates"
                opacity: win.mode === "updates" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Row {
                    id: upHead
                    spacing: 10
                    Rectangle {
                        width: 32; height: 32; radius: 11
                        color: ctx.a(ctx.cAcc, 0.18)
                        Text {
                            anchors.centerIn: parent
                            text: ctx.upState === "running" ? "\uf019" : ctx.upState === "failed" ? "\uf071" : ctx.upAll.length ? "\uf0ab" : "\uf00c"
                            color: ctx.upState === "failed" ? ctx.cRed : ctx.cAccL
                            font.family: ctx.iconFont; font.weight: Font.Black; font.pixelSize: 14
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: ctx.upState === "checking" ? "Checking for updates…"
                                : ctx.upState === "running" ? "Updating  " + Math.round(ctx.upProgress * 100) + "%"
                                : ctx.upState === "done" ? "System up to date"
                                : ctx.upState === "failed" ? "Update failed"
                                : ctx.upAll.length ? ctx.upAll.length + " updates available" : "Everything is up to date"
                            color: ctx.cFg; font.family: ctx.font; font.pixelSize: 14
                        }
                        Text {
                            text: ctx.upState === "running" ? (ctx.upCounts + (ctx.upItem ? "  ·  " + ctx.upItem : ""))
                                : ctx.upState === "checking" ? "querying dnf and flatpak…"
                                : ctx.upState === "failed" ? ctx.upError
                                : ctx.dnfList.length + " system  ·  " + ctx.flatList.length + " flatpak"
                            color: ctx.cDim; font.family: ctx.font; font.pixelSize: 10
                            width: 380; elide: Text.ElideRight
                        }
                    }
                }

                // overall line
                Rectangle {
                    id: upTrack
                    anchors.top: upHead.bottom
                    anchors.topMargin: 12
                    width: parent.width; height: 6; radius: 3
                    color: ctx.a(ctx.cFg, 0.10)
                    visible: ctx.upState === "running" || ctx.upState === "done"
                    Rectangle {
                        height: parent.height; radius: 3
                        width: Math.max(ctx.upProgress > 0 ? 6 : 0, upTrack.width * ctx.upProgress)
                        color: ctx.upState === "failed" ? ctx.cRed : ctx.cAcc
                        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    }
                }

                ListView {
                    id: upList
                    anchors { top: upTrack.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: upBtns.top; bottomMargin: 10 }
                    visible: ctx.upState === "ready" || ctx.upState === "idle"
                    clip: true
                    model: ctx.upAll
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Item {
                        required property var modelData
                        width: upList.width; height: 23
                        Rectangle {
                            width: 5; height: 5; radius: 2.5
                            x: 3; anchors.verticalCenter: parent.verticalCenter
                            color: modelData.src === "dnf" ? ctx.cAcc : ctx.cBlue
                        }
                        Text {
                            x: 16; width: parent.width - 84
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name; elide: Text.ElideRight
                            color: ctx.cText; font.family: ctx.font; font.pixelSize: 11
                        }
                        Text {
                            anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            text: modelData.src; color: ctx.cDim; font.family: ctx.font; font.pixelSize: 9
                        }
                    }
                }

                // current item with its own line, while running
                Column {
                    anchors { top: upTrack.bottom; topMargin: 12; left: parent.left; right: parent.right }
                    visible: ctx.upState === "running"
                    spacing: 8
                    Text {
                        width: parent.width
                        text: ctx.upItem || "Working…"
                        color: ctx.cText; font.family: ctx.font; font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        width: parent.width; height: 4; radius: 2
                        color: ctx.a(ctx.cFg, 0.10)
                        Rectangle {
                            height: parent.height; radius: 2
                            width: parent.width * ctx.itemProgress
                            color: ctx.cAccL
                            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                Row {
                    id: upBtns
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    spacing: 8
                    visible: ctx.upState === "ready" && ctx.upAll.length > 0
                    Btn { text: "Later"; onClicked: ctx.unpin() }
                    Btn { text: "Update all"; primary: true; onClicked: ctx.startUpdate() }
                }
                Row {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    spacing: 8
                    visible: ctx.upState === "done" || ctx.upState === "failed"
                    Btn { text: "Close"; onClicked: ctx.unpin() }
                }
            }

            // ==================================================== WIFI
            Item {
                anchors.fill: parent
                anchors.margins: 14
                visible: win.mode === "wifi"
                opacity: win.mode === "wifi" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Row {
                    id: wifiHead
                    spacing: 10
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ctx.netGlyph; color: ctx.cAccL
                        font.family: ctx.iconFont; font.weight: Font.Black; font.pixelSize: 16
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: ctx.netLabel; color: ctx.cFg; font.family: ctx.font; font.pixelSize: 14 }
                        Text {
                            text: ctx.wifiNet ? Math.round(ctx.strength(ctx.wifiNet) * 100) + "% signal" : (ctx.wiredDev ? "wired" : "")
                            color: ctx.cDim; font.family: ctx.font; font.pixelSize: 10
                        }
                    }
                    Item { width: 120; height: 1 }
                    Btn {
                        text: Networking.wifiEnabled ? "Wi‑Fi on" : "Wi‑Fi off"
                        primary: Networking.wifiEnabled
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }

                ListView {
                    id: wifiList
                    anchors { top: wifiHead.bottom; topMargin: 12; left: parent.left; right: parent.right; bottom: parent.bottom }
                    clip: true
                    model: ctx.wifiDev ? ctx.wifiDev.networks : []
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool known: modelData.known
                        readonly property bool connected: modelData.connected
                        width: wifiList.width; height: 34
                        radius: 9
                        color: connected ? ctx.a(ctx.cAcc, 0.18) : (ma.containsMouse ? ctx.a(ctx.cFg, 0.07) : "transparent")
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: connected ? "\uf1eb" : known ? "\uf023" : "\uf1eb"
                                color: connected ? ctx.cAccL : ctx.cDim
                                font.family: ctx.iconFont; font.weight: Font.Black; font.pixelSize: 11
                            }
                            Text {
                                width: parent.width - 130
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                color: connected ? ctx.cFg : ctx.cText
                                font.family: ctx.font; font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            Item { width: 30; height: 1 }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(ctx.strength(modelData) * 100) + "%"
                                color: ctx.cDim; font.family: ctx.font; font.pixelSize: 9
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: win.pskFor === modelData.name
                                text: "type password below"
                                color: ctx.cDim; font.family: ctx.font; font.pixelSize: 9
                            }
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (connected) { modelData.requestDisconnect(); return; }
                                if (modelData.known || modelData.security === WifiSecurityType.Open) {
                                    modelData.requestConnect();
                                } else {
                                    win.pskFor = modelData.name;
                                    win.pskText = "";
                                    ctx.wantsKeyboard = true;
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: win.pskFor !== ""
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 40; radius: 11
                    color: ctx.a(ctx.cFg, 0.06)
                    border.width: 1; border.color: ctx.edge
                    TextField {
                        id: pskField
                        anchors.fill: parent
                        anchors.margins: 4
                        leftPadding: 10
                        focus: win.pskFor !== ""
                        placeholderText: "Password for " + win.pskFor
                        echoMode: TextInput.Password
                        color: ctx.cFg
                        font.family: ctx.font; font.pixelSize: 12
                        background: null
                        onTextChanged: win.pskText = text
                        Keys.onReturnPressed: {
                            const n = ctx.wifiDev?.networks.values.find(x => x.name === win.pskFor);
                            if (n) n.connectWithPsk(win.pskText);
                            win.pskFor = ""; ctx.wantsKeyboard = false;
                        }
                        Keys.onEscapePressed: { win.pskFor = ""; ctx.wantsKeyboard = false; ctx.unpin(); }
                    }
                }
            }

            // ==================================================== BLUETOOTH
            Item {
                anchors.fill: parent
                anchors.margins: 14
                visible: win.mode === "bt"
                opacity: win.mode === "bt" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Row {
                    id: btHead
                    spacing: 10
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf293"; color: ctx.btOn ? ctx.cAccL : ctx.cDim
                        font.family: ctx.iconFont; font.weight: Font.Black; font.pixelSize: 16
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: ctx.bt?.name ?? "Bluetooth"; color: ctx.cFg; font.family: ctx.font; font.pixelSize: 14 }
                        Text {
                            text: ctx.btOn ? (ctx.btConnected.length + " connected") : "off"
                            color: ctx.cDim; font.family: ctx.font; font.pixelSize: 10
                        }
                    }
                    Item { width: 90; height: 1 }
                    Btn {
                        text: ctx.btOn ? "Bluetooth on" : "Bluetooth off"
                        primary: ctx.btOn
                        enabled: ctx.bt !== null
                        onClicked: ctx.bt.enabled = !ctx.bt.enabled
                    }
                    Btn { text: "Scan"; primary: ctx.bt?.discovering ?? false; enabled: ctx.btOn; onClicked: ctx.bt.discovering = !ctx.bt.discovering }
                }

                ListView {
                    anchors { top: btHead.bottom; topMargin: 12; left: parent.left; right: parent.right; bottom: parent.bottom }
                    clip: true
                    model: ctx.btDevices
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool connected: modelData.connected
                        width: 380; height: 34
                        radius: 9
                        color: connected ? ctx.a(ctx.cAcc, 0.18) : (ma.containsMouse ? ctx.a(ctx.cFg, 0.07) : "transparent")
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon ?? "\uf293"
                                color: connected ? ctx.cAccL : ctx.cDim
                                font.family: ctx.iconFont; font.weight: Font.Black; font.pixelSize: 11
                            }
                            Text {
                                width: parent.width - 140
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name || modelData.deviceName
                                color: connected ? ctx.cFg : ctx.cText
                                font.family: ctx.font; font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.batteryAvailable
                                text: Math.round(modelData.battery * 100) + "%"
                                color: ctx.cDim; font.family: ctx.font; font.pixelSize: 9
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: connected ? "connected" : modelData.paired ? "paired" : "new"
                                color: ctx.cDim; font.family: ctx.font; font.pixelSize: 9
                            }
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (connected) modelData.disconnect();
                                else if (modelData.paired) modelData.connect();
                                else { modelData.pair(); }
                            }
                        }
                    }
                }
            }

            // ==================================================== APPS
            Item {
                anchors.fill: parent
                anchors.margins: 14
                visible: win.mode === "apps"
                opacity: win.mode === "apps" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                TextField {
                    id: appField
                    width: parent.width
                    height: 38
                    focus: win.mode === "apps"
                    placeholderText: "Search apps…"
                    placeholderTextColor: ctx.cDim
                    color: ctx.cFg
                    font.family: ctx.font
                    font.pixelSize: 13
                    leftPadding: 12
                    selectionColor: ctx.cAcc
                    selectedTextColor: ctx.cBg0
                    background: Rectangle {
                        radius: 11
                        color: ctx.a(ctx.cFg, 0.06)
                        border.width: 1
                        border.color: appField.activeFocus ? ctx.a(ctx.cAcc, 0.55) : ctx.edge
                    }
                    onTextChanged: { win.appQuery = text; win.appSel = 0; }
                    Keys.onDownPressed: {
                        if (win.appList.length) win.appSel = Math.min(win.appList.length - 1, win.appSel + 1);
                        event.accepted = true;
                    }
                    Keys.onUpPressed: {
                        win.appSel = Math.max(0, win.appSel - 1);
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: {
                        if (win.appList[win.appSel]) ctx.launchApp(win.appList[win.appSel].exec);
                        event.accepted = true;
                    }
                    Keys.onEscapePressed: { ctx.unpin(); event.accepted = true; }
                }

                ListView {
                    id: appListView
                    anchors { top: appField.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: parent.bottom }
                    clip: true
                    model: win.appList
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 2
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: appListView.width
                        height: 36
                        radius: 9
                        color: index === win.appSel ? ctx.a(ctx.cAcc, 0.22)
                            : appMa.containsMouse ? ctx.a(ctx.cFg, 0.07) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 10
                            spacing: 10
                            Item {
                                width: 22; height: 22
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.name ?? "?").charAt(0).toUpperCase()
                                    color: ctx.cDim
                                    font.family: ctx.font; font.pixelSize: 12
                                }
                                Image {
                                    anchors.fill: parent
                                    source: modelData.icon ? Quickshell.iconPath(modelData.icon, "") : ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    sourceSize { width: 22; height: 22 }
                                }
                            }
                            Text {
                                width: parent.width - 40
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                color: index === win.appSel ? ctx.cFg : ctx.cText
                                font.family: ctx.font; font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                        MouseArea {
                            id: appMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.appSel = index
                            onClicked: ctx.launchApp(modelData.exec)
                        }
                    }
                }
            }

            // ==================================================== DISCORD
            Item {
                id: discordCard
                anchors.fill: parent
                anchors.margins: 12
                visible: win.mode === "discord"
                opacity: win.mode === "discord" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Row {
                    id: dHead
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\uf392"
                        color: ctx.cAccL
                        font.family: "Font Awesome 6 Brands"; font.pixelSize: 15
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: ctx.slackOpen
                        text: "\uf198"
                        color: ctx.cYellow
                        font.family: "Font Awesome 6 Brands"; font.pixelSize: 14
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Inbox"
                        color: ctx.cFg
                        font.family: ctx.font; font.pixelSize: 13
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: ctx.discordUnread > 0
                        width: dCount.implicitWidth + 14; height: 18; radius: 9
                        color: ctx.a(ctx.cAcc, 0.22)
                        Text {
                            id: dCount
                            anchors.centerIn: parent
                            text: ctx.discordUnread
                            color: ctx.cAccL
                            font.family: ctx.font; font.pixelSize: 10
                        }
                    }
                }

                Text {
                    anchors { top: parent.top; right: parent.right; rightMargin: 34; topMargin: 2 }
                    text: "\u21b5 send   \u21e7\u21b5 open"
                    color: ctx.cDim
                    font.family: ctx.font; font.pixelSize: 10
                }

                ListView {
                    id: dList
                    anchors { top: dHead.bottom; topMargin: 8; left: parent.left; right: parent.right; bottom: dReplyBar.top; bottomMargin: 8 }
                    clip: true
                    model: ctx.inboxRows
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 2
                    readonly property int rowH: win.discordRowH
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: dList.width
                        height: dList.rowH
                        radius: 10
                        color: index === win.dSel ? ctx.a(ctx.cAcc, 0.18)
                            : dMa.containsMouse ? ctx.a(ctx.cFg, 0.07) : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            visible: (modelData.unread || 0) + (modelData.mentions || 0) > 0
                            width: 18; height: 18; radius: 9
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            color: (modelData.mentions || 0) > 0 ? ctx.a(ctx.cRed, 0.85) : ctx.a(ctx.cAcc, 0.85)
                            Text {
                                anchors.centerIn: parent
                                text: (modelData.mentions || 0) > 0 ? modelData.mentions : modelData.unread
                                color: ctx.cBg0
                                font.family: ctx.font; font.pixelSize: 9
                            }
                        }
                        Text {
                            id: dName
                            anchors { left: parent.left; leftMargin: 34; right: parent.right; rightMargin: 10; top: parent.top; topMargin: 5 }
                            text: modelData.name + (modelData.guild ? "  ·  " + modelData.guild : "")
                            color: index === win.dSel ? ctx.cFg : ctx.cText
                            font.family: ctx.font; font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: 34; right: parent.right; rightMargin: 10; top: dName.bottom; topMargin: 1 }
                            text: modelData.content !== ""
                                ? (modelData.author !== "" ? modelData.author + ": " : "") + modelData.content
                                : ((modelData.unread || 0) + " new message" + ((modelData.unread || 0) === 1 ? "" : "s"))
                            color: ctx.cDim
                            font.family: ctx.font; font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            id: dMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: win.dSel = index
                            onClicked: { win.dSel = index; dField.forceActiveFocus(); }
                            onDoubleClicked: ctx.discordJump(modelData)
                        }
                    }
                }

                Text {
                    anchors.centerIn: dList
                    visible: ctx.inboxRows.length === 0
                    text: ctx.discordAny ? "No unread messages" : "Discord and Slack aren't running"
                    color: ctx.cDim
                    font.family: ctx.font; font.pixelSize: 12
                }

                Row {
                    id: dReplyBar
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    spacing: 8
                    height: 38

                    TextField {
                        id: dField
                        width: parent.width - dSend.width - 8
                        height: 38
                        focus: win.mode === "discord"
                        placeholderText: {
                            const r = ctx.inboxRows[win.dSel];
                            if (!r) return "Reply…";
                            return r.app === "slack" ? "⏎ open Slack" : "Reply to " + r.name + "…";
                        }
                        placeholderTextColor: ctx.cDim
                        color: ctx.cFg
                        font.family: ctx.font; font.pixelSize: 12
                        leftPadding: 12
                        selectionColor: ctx.cAcc
                        selectedTextColor: ctx.cBg0
                        background: Rectangle {
                            radius: 11
                            color: ctx.a(ctx.cFg, 0.06)
                            border.width: 1
                            border.color: dField.activeFocus ? ctx.a(ctx.cAcc, 0.55) : ctx.edge
                        }
                        onTextChanged: win.dReply = text
                        Keys.onReturnPressed: {
                            const ch = ctx.inboxRows[win.dSel];
                            if (!ch) { event.accepted = true; return; }
                            const open = (event.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) !== 0;
                            if (ch.app === "slack") { ctx.slackFocus(); ctx.unpin(); }
                            else if (open) ctx.discordJump(ch);
                            else { ctx.discordReply(ch, text); text = ""; }
                            event.accepted = true;
                        }
                        Keys.onDownPressed: {
                            if (ctx.inboxRows.length) win.dSel = Math.min(ctx.inboxRows.length - 1, win.dSel + 1);
                            event.accepted = true;
                        }
                        Keys.onUpPressed: {
                            win.dSel = Math.max(0, win.dSel - 1);
                            event.accepted = true;
                        }
                        Keys.onEscapePressed: { ctx.unpin(); event.accepted = true; }
                    }
                    Btn {
                        id: dSend
                        glyph: "\uf1d8"
                        width: 38
                        height: 38
                        enabled: win.dReply.trim() !== "" && ctx.inboxRows.length > 0
                        onClicked: {
                            const ch = ctx.inboxRows[win.dSel];
                            if (ch) { ctx.discordReply(ch, dField.text); dField.text = ""; }
                        }
                    }
                }
            }

            // ==================================================== HUB
            Item {
                anchors.fill: parent
                anchors.margins: 14
                visible: win.mode === "hub"
                opacity: win.mode === "hub" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    Btn { glyph: "\uf001"; text: "Music"; primary: ctx.playing; onClicked: ctx.show("music") }
                    Btn { glyph: "\uf019"; text: "Updates"; primary: ctx.upAll.length > 0; onClicked: ctx.show("updates") }
                    Btn { glyph: "\uf1eb"; text: "Wi‑Fi"; primary: ctx.netUp; onClicked: ctx.show("wifi") }
                    Btn { glyph: "\uf293"; text: "Bluetooth"; primary: ctx.btConnected.length > 0; onClicked: ctx.show("bt") }
                }
            }
        }
    }

    // ---------------------------------------------------------- components
    component Cava: Item {
        property var bars: []
        property color color: "#a7c080"
        Repeater {
            model: 12
            Rectangle {
                required property int index
                readonly property real v: bars.length ? (bars[index] ?? 0) : 0
                width: 2
                radius: 1
                height: Math.max(2, v * parent.height)
                x: index * 4
                anchors.bottom: parent.bottom
                color: parent.color
                opacity: 0.55 + 0.45 * v
                Behavior on height { NumberAnimation { duration: 90 } }
            }
        }
    }

    component Btn: Rectangle {
        id: b
        property string glyph: ""
        property string text: ""
        property string tip: ""
        property bool primary: false
        property bool big: false
        property bool accent: false
        property bool enabled: true
        signal clicked()
        width: (text !== "" ? label.implicitWidth + 24 : (glyph !== "" ? (big ? 34 : 28) : 0))
        height: big ? 34 : 28
        radius: height / 2
        opacity: enabled ? 1 : 0.35
        color: b.primary ? (ma.containsMouse ? ctx.cAccL : ctx.cAcc)
            : b.accent ? ctx.a(ctx.cRed, ma.containsMouse ? 0.30 : 0.18)
            : ctx.a(ctx.cFg, ma.containsMouse ? 0.15 : 0.07)
        border.width: 1
        border.color: b.primary ? ctx.a(ctx.cAccL, 0.9) : ctx.edge
        Behavior on color { ColorAnimation { duration: 140 } }
        scale: ma.pressed ? 0.94 : 1
        Behavior on scale { NumberAnimation { duration: 110 } }

        Row {
            anchors.centerIn: parent
            spacing: 6
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: b.glyph !== ""
                text: b.glyph
                color: b.primary ? ctx.cBg0 : b.accent ? ctx.cRed : ctx.cFg
                font.family: ctx.iconFont
                font.weight: Font.Black
                font.pixelSize: b.big ? 15 : 12
            }
            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                visible: b.text !== ""
                text: b.text
                color: b.primary ? ctx.cBg0 : ctx.cFg
                font.family: ctx.font; font.pixelSize: 11
            }
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            enabled: b.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: b.clicked()
        }
    }
}
