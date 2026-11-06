//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
// Rice dynamic island: one pill over the bar centre that morphs into
// music / updates / wifi / bluetooth cards.
//   qs ipc -c island call island show music|updates|wifi|bt|hub|close
// Colors come from ~/.config/waybar/rice-palette.css (wallcolors.py), live.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.SystemTray

ShellRoot {
    id: root
    readonly property string home: Quickshell.env("HOME")

    // ------------------------------------------------------------ palette
    property var pal: ({})
    function c(k, fb) { return pal[k] ?? fb }
    function a(col, alpha) { return Qt.rgba(col.r, col.g, col.b, alpha) }
    function rgbaHex(hex, alpha) {
        return Qt.rgba(parseInt(hex.substr(1, 2), 16) / 255, parseInt(hex.substr(3, 2), 16) / 255,
                       parseInt(hex.substr(5, 2), 16) / 255, alpha);
    }
    readonly property color cFg: c("fg_bright", "#e6dcc2")
    readonly property color cText: c("fg", "#d3c6aa")
    readonly property color cDim: c("grey2", "#9da9a0")
    readonly property color cAcc: c("green", "#a7c080")
    readonly property color cAccL: c("l_green", "#c2dba0")
    readonly property color cBg0: c("bg0", "#2d353b")
    readonly property color cRed: c("l_red", "#ee9ea0")
    readonly property color cBlue: c("l_blue", "#a8d5cf")
    readonly property color cYellow: c("l_yellow", "#ecd49b")
    readonly property color cOrange: c("l_orange", "#efb89a")
    readonly property color cPurple: c("l_purple", "#e6bbcd")
    readonly property string font: "Fira Sans Semibold"
    readonly property string iconFont: "Font Awesome 6 Free"
    // glass, exactly the waybar recipe (bg0 55% + faint fg edge)
    function glass(alpha) { return rgbaHex(c("bg0", "#2d353b"), alpha); }
    readonly property color edge: rgbaHex(c("fg", "#d3c6aa"), 0.12)

    FileView {
        path: root.home + "/.config/waybar/rice-palette.css"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const m = {}, re = /@define-color\s+ef_(\w+)\s+(#[0-9a-fA-F]{6})/g, t = text();
            let r;
            while ((r = re.exec(t)) !== null) m[r[1]] = r[2];
            root.pal = m;
        }
    }

    // ------------------------------------------------------------ card state
    property string pinned: ""
    property bool cardOpen: false
    property bool anyHovered: false
    property bool barHover: false
    property int polls: 0
    property string debugPointer: ""
    property bool hoverSuppressed: false
    property bool wantsKeyboard: false
    property real lastUnpin: 0
    property string lastUnpinned: ""
    readonly property bool shownForBar: true   // idle pill = workspace numbers
    // always offer workspace 1, even when it has no windows yet
    readonly property var workspaces: {
        const list = Hyprland.workspaces ? Hyprland.workspaces.values.filter(w => w.id > 0) : [];
        if (!list.some(w => w.id === 1)) list.push({ id: 1, name: "1" });
        return list.slice().sort((a, b) => a.id - b.id);
    }
    readonly property bool hasMedia: playing || title.length > 0
    readonly property int activeWorkspace: Hyprland.focusedWorkspace?.id ?? 0
    function focusWorkspace(id) { Hyprland.dispatch("workspace " + id) }
    function unpin() {
        if (pinned !== "") { lastUnpinned = pinned; lastUnpin = Date.now(); }
        pinned = "";
        wantsKeyboard = false;
        // hover must not immediately re-expand the card we just dismissed
        hoverSuppressed = true;
        hoverResume.restart();
    }
    function show(what) {
        if (pinned === what) { unpin(); return; }
        // the chip click that dismissed this card must not reopen it
        if (what === lastUnpinned && Date.now() - lastUnpin < 450) return;
        pinned = what;
        if (what === "updates") maybeCheck();
    }

    Timer { id: hoverResume; interval: 2500; onTriggered: root.hoverSuppressed = false }

    IpcHandler {
        target: "island"
        function open(what: string): void { root.show(what) }
        function toggle(): void { root.show("updates") }
        function close(): void { root.unpin() }
        function isopen(): bool { return root.pinned !== "" || root.cardOpen }
        // dev hook: replay a captured update log through the real parser
        function replay(path: string): void { root.upLog = path; root.upState = "running" }
        function debug(): string {
            return JSON.stringify({ pos: root.player?.position, len: root.player?.length,
                                    state: root.upState, all: root.upAll.length,
                                    hovered: root.anyHovered, pointer: root.debugPointer,
                                    likes: root.likesSent, pinned: root.pinned, cardOpen: root.cardOpen, tray: root.trayDebug, trayClicks: root.trayClicks, trayLast: root.trayLast, workspaces: root.workspaces.length, activeWs: root.activeWorkspace,
                                    playerWindow: (root.playerWindow()?.lastIpcObject?.class ?? "") + " " + (root.playerWindow()?.address ?? ""),
                                    barHover: root.barHover, polls: root.polls, suppress: root.hoverSuppressed, discordAny: root.discordAny, inbox: root.discordInbox.length, rpc: root.discordRpc !== null, unread: root.discordUnread });
        }
    }

    // ------------------------------------------------------------ music
    readonly property var realPlayers: Mpris.players.values.filter(p => !(p.dbusName ?? "").includes("playerctld"))
    property string preferredBus: ""
    readonly property var player: {
        const ps = realPlayers;
        if (!ps.length) return null;
        return ps.find(p => p.dbusName === preferredBus) ?? ps.find(p => p.isPlaying) ?? ps[0];
    }
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player ? (player.trackTitle || player.identity || "") : ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property string playerId: ((player?.identity ?? "") + " " + (player?.desktopEntry ?? "")).toLowerCase()
    readonly property bool isSpotify: playerId.includes("spotify")
    readonly property string trackKey: title + "|" + artist
    property string likedKey: ""
    readonly property bool liked: likedKey !== "" && likedKey === trackKey
    readonly property var videoToplevel: {
        if (!player || isSpotify) return null;
        const t = (player.trackTitle ?? "").trim();
        if (t.length < 3) return null;
        return ToplevelManager.toplevels.values.find(tl => (tl.title ?? "").includes(t)) ?? null;
    }
    readonly property bool videoLive: videoToplevel !== null
    Timer {   // follow whichever player starts playing
        interval: 1000; repeat: true; running: root.realPlayers.length > 1
        onTriggered: {
            const cur = root.player;
            const p = root.realPlayers.find(x => x.isPlaying);
            if (p && cur !== p && !(cur?.isPlaying)) root.preferredBus = p.dbusName;
        }
    }
    function fmt(sec) {
        // Quickshell reports MPRIS position/length in seconds
        let s = Math.max(0, Math.floor(sec || 0));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
    // Hyprland toplevels let us focus the player's window (and its workspace)
    // directly; MPRIS Raise is a no-op for Spotify on Wayland.
    readonly property var hyprToplevels: Hyprland.toplevels ? Hyprland.toplevels.values : []
    function addr(t) {
        const a = t?.address ?? "";
        return a.startsWith("0x") ? a : "0x" + a;
    }
    function playerWindow() {
        const want = isSpotify ? "spotify"
            : ((player?.desktopEntry ?? "") + " " + (player?.identity ?? "")).toLowerCase();
        let t = hyprToplevels.find(tl => want.length > 2 && ((tl.lastIpcObject?.class ?? "").toLowerCase().includes(want)));
        if (!t && title.length > 2) t = hyprToplevels.find(tl => (tl.title ?? "").includes(title));
        return t;
    }
    function raisePlayer() {
        if (videoToplevel) { videoToplevel.activate(); unpin(); return; }
        const t = playerWindow();
        if (t) Hyprland.dispatch("focuswindow address:" + addr(t));
        else if (isSpotify) Hyprland.dispatch("focuswindow class:^(spotify|Spotify)$");
        else if (player?.canRaise) player.raise();
        unpin();
    }
    // Spotify has no MPRIS "like": its own shortcut is Alt+Shift+B, sent to the
    // exact Spotify window (works while it is unfocused).
    property int likesSent: 0
    function likeSpotify() {
        const t = hyprToplevels.find(tl => ((tl.lastIpcObject?.class ?? "").toLowerCase().includes("spotify")));
        if (!t) return;   // no Spotify window: the shortcut would go nowhere
        Quickshell.execDetached(["hyprctl", "dispatch", "sendshortcut", "ALT SHIFT, B, address:" + addr(t)]);
        likedKey = liked ? "" : trackKey;
        likesSent++;
    }

    // ------------------------------------------------------------ tray
    readonly property var trayItems: SystemTray.items ? SystemTray.items.values : []
    readonly property string trayDebug: trayItems.map(t => (t.id ?? "") + "|" + (t.icon ?? "") + "|" + (t.status ?? "")).join(" ; ")
    property bool vpnConnected: false
    property string trayTip: ""
    property int trayClicks: 0
    property string trayLast: ""
    Timer {
        interval: 6000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: vpnCheck.running = true
    }
    Process {
        id: vpnCheck
        command: ["sh", "-c", "mullvad status 2>/dev/null | head -1"]
        stdout: StdioCollector {
            id: vpnOut
            onStreamFinished: root.vpnConnected = /^Connected/.test(vpnOut.text.trim())
        }
    }

    // ------------------------------------------------------------ discord
    // Fed by the RpcBridge BetterDiscord plugin: what Discord actually shows
    // (PresenceStore, not raw RPC requests) + unread channels.
    property var discordInbox: []
    property var discordRpc: null
    readonly property bool discordAny: discordRpc !== null || discordInbox.length > 0
    readonly property int discordUnread: discordInbox.reduce((n, c) => n + (c.unread || 0), 0)
    readonly property int discordMentions: discordInbox.reduce((n, c) => n + (c.mentions || 0), 0)

    FileView {
        id: inboxFile
        path: root.home + "/.cache/discord-inbox.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const j = JSON.parse(text());
                root.discordInbox = Array.isArray(j.channels) ? j.channels : [];
            } catch (e) { root.discordInbox = []; }
        }
    }
    FileView {
        id: rpcFile
        path: root.home + "/.cache/discord-rpc.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.discordRpc = JSON.parse(text()); } catch (e) { root.discordRpc = null; }
        }
    }
    // the plugin deletes its files when Discord is gone; drop stale state.
    // Loop ends with qs (kill -0 $PPID) so restarts leave no orphans.
    Process {
        running: true
        command: ["sh", "-c", "while kill -0 $PPID 2>/dev/null; do [ -f \"$HOME/.cache/discord-rpc.json\" ] && printf r; [ -f \"$HOME/.cache/discord-inbox.json\" ] && printf i; echo; sleep 5; done"]
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("r") < 0) root.discordRpc = null;
                if (line.indexOf("i") < 0) root.discordInbox = [];
            }
        }
    }

    // focuswindow alone can leave you on the current workspace for apps on a
    // hidden one; jump to that workspace first, then focus the window.
    function focusToplevel(t) {
        if (!t) return false;
        const ws = t.lastIpcObject?.workspace?.id ?? t.workspace?.id ?? 0;
        if (ws > 0) Hyprland.dispatch("workspace " + ws);
        Hyprland.dispatch("focuswindow address:" + addr(t));
        return true;
    }
    function findApp(re) {
        return (Hyprland.toplevels ? Hyprland.toplevels.values : []).find(tl => {
            const cls = ((tl.lastIpcObject?.class ?? "") + " " + (tl.lastIpcObject?.initialClass ?? "")).toLowerCase();
            return re.test(cls);
        });
    }
    // Slack has no local API; surface its desktop notifications (sniffed by
    // notify-watch.py) as card rows while a Slack window exists.
    property var slackToasts: []
    readonly property bool slackOpen: (Hyprland.toplevels ? Hyprland.toplevels.values : [])
        .some(tl => /slack/i.test((tl.lastIpcObject?.class ?? "") + " " + (tl.lastIpcObject?.initialClass ?? "")))
    readonly property var slackRows: {
        if (!slackOpen) return [];
        const cutoff = Date.now() - 30 * 60 * 1000;
        const seen = {};
        const rows = [];
        for (const t of slackToasts) {
            if (!/slack/i.test(t.app || "") || (t.ts || 0) < cutoff) continue;
            const key = (t.summary || "") + "|" + (t.body || "");
            if (seen[key]) continue;
            seen[key] = true;
            rows.push(t);
        }
        return rows
            .slice(-3)
            .map(t => ({
                id: "slack:" + t.ts,
                name: t.summary || "Slack",
                guild: "Slack",
                author: "",
                content: t.body || "",
                ts: t.ts || 0,
                unread: 0,
                mentions: 0,
                app: "slack",
            }));
    }
    readonly property var inboxRows: {
        const d = discordInbox.map(c => Object.assign({ app: "discord" }, c));
        return slackRows.concat(d);
    }
    FileView {
        path: root.home + "/.cache/rice-toasts.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const j = JSON.parse(text());
                root.slackToasts = Array.isArray(j.toasts) ? j.toasts : [];
            } catch (e) { root.slackToasts = []; }
        }
    }

    function discordFocus() {
        if (focusToplevel(findApp(/discord|vesktop|equibop/))) return;
        Hyprland.dispatch("focuswindow class:^(discord|Discord|vesktop|Vesktop|equibop)$");
    }
    function slackFocus() {
        if (focusToplevel(findApp(/slack/))) return;
        Hyprland.dispatch("focuswindow class:^(Slack|slack)$");
    }
    function discordCmd(obj) {
        Quickshell.execDetached(["sh", "-c",
            "printf %s \"$0\" > \"$HOME/.cache/discord-cmd.json\"", JSON.stringify(obj)]);
    }
    function discordJump(ch) {
        discordCmd({ action: "jump", channelId: ch.id, guildId: ch.guildId || "", messageId: ch.lastId || "" });
        discordFocus();
        unpin();
    }
    function discordReply(ch, text) {
        const body = (text || "").trim();
        if (!ch || !body) return;
        discordCmd({ channelId: ch.id, content: body });
    }

    // ------------------------------------------------------------ apps
    property var apps: []
    Process {
        id: appScan
        running: true
        command: ["sh", root.home + "/.config/quickshell/island/apps.sh"]
        stdout: StdioCollector {
            id: appOut
            onStreamFinished: {
                const t = appOut.text.trim();
                root.apps = t ? t.split("\n").map(l => {
                    const p = l.split("\t");
                    return { name: p[0] ?? "", exec: p[1] ?? "", icon: p[2] ?? "" };
                }).filter(a => a.name && a.exec) : [];
            }
        }
    }
    function launchApp(cmd) {
        // strip desktop-entry field codes and flatpak file-forwarding markers
        const clean = cmd.replace(/@@[^@]*@@/g, "").replace(/%[a-zA-Z]/g, "").trim();
        if (!clean) return;
        Quickshell.execDetached(["sh", "-c", `setsid ${clean} >/dev/null 2>&1 < /dev/null &`]);
        unpin();
    }

    property var bars: []
    Process {
        running: root.playing
        command: ["cava", "-p", root.home + "/.config/quickshell/island/cava.conf"]
        stdout: SplitParser {
            onRead: data => root.bars = data.split(";").filter(x => x !== "").map(x => Math.min(1, (+x) / 100))
        }
        onRunningChanged: if (!running) root.bars = []
    }

    // ------------------------------------------------------------ network / bluetooth
    readonly property var netDevices: Networking.devices.values
    readonly property var wifiDevs: netDevices.filter(d => d.type === DeviceType.Wifi)
    readonly property var wifiDev: wifiDevs.find(d => d.connected) ?? wifiDevs[0] ?? null
    readonly property var wiredDev: netDevices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifiNet: wifiDev ? (wifiDev.networks.values.find(n => n.connected) ?? null) : null
    readonly property bool netUp: wiredDev !== null || wifiNet !== null
    readonly property string netGlyph: wiredDev ? "\uf796" : "\uf1eb"
    readonly property string netLabel: wifiNet ? wifiNet.name : wiredDev ? "Ethernet"
        : (Networking.wifiEnabled ? "Not connected" : "Wi-Fi off")
    function strength(n) { const v = n?.signalStrength ?? 0; return v > 1 ? v / 100 : v; }

    readonly property var bt: Bluetooth.defaultAdapter
    readonly property bool btOn: bt?.enabled ?? false
    readonly property var btDevices: bt ? bt.devices.values : []
    readonly property var btConnected: btDevices.filter(d => d.connected)

    // ------------------------------------------------------------ updates
    // idle | checking | ready | running | done | failed
    property string upState: "idle"
    property var dnfList: []
    property var flatList: []
    readonly property var upAll: dnfList.map(n => ({ src: "dnf", name: n })).concat(flatList.map(n => ({ src: "flatpak", name: n })))
    property real lastCheck: 0
    property int pendingChecks: 0
    property real upProgress: 0
    property real itemProgress: 0
    property string upItem: ""
    property string upCounts: ""
    property string upError: ""
    property string upLog: ""
    property int nFlat: 0
    property int nDnf: 0
    property string phase: ""
    property var seenRefs: ({})
    property int flatDone: 0
    property real flatItem: 0
    property real dnfFrac: 0
    property int dnfStage: 0

    function maybeCheck() {
        if (upState === "running" || upState === "checking") return;
        if ((upState === "ready" || upState === "done") && Date.now() - lastCheck < 5 * 60 * 1000) return;
        upState = "checking";
        pendingChecks = 2;
        dnfCheck.running = true;
        flatCheck.running = true;
    }
    function checkDone() {
        if (--pendingChecks > 0) return;
        lastCheck = Date.now();
        if (upState === "checking") upState = "ready";
    }
    Process {
        id: dnfCheck
        command: ["sh", "-c", "dnf check-update -q 2>/dev/null | awk 'NF>=3 && $1 ~ /^[a-zA-Z0-9]/ {sub(/\\.[^.]+$/, \"\", $1); print $1}'"]
        stdout: StdioCollector { id: dnfOut; onStreamFinished: root.dnfList = dnfOut.text.trim() ? dnfOut.text.trim().split("\n") : [] }
        onExited: root.checkDone()
    }
    Process {
        id: flatCheck
        command: ["sh", "-c", "flatpak remote-ls --updates --columns=name 2>/dev/null"]
        stdout: StdioCollector { id: flatOut; onStreamFinished: root.flatList = flatOut.text.trim() ? flatOut.text.trim().split("\n") : [] }
        onExited: root.checkDone()
    }

    function startUpdate() {
        if (!flatList.length && !dnfList.length) return;
        nFlat = flatList.length; nDnf = dnfList.length;
        phase = ""; seenRefs = ({}); flatDone = 0; flatItem = 0; dnfFrac = 0; dnfStage = 0;
        upProgress = 0; itemProgress = 0; upItem = "Starting…"; upCounts = ""; upError = "";
        upLog = home + "/.cache/rice-update-" + Date.now() + ".log";
        const flat = flatList.join("\n"), dnf = dnfList.join("\n");
        Quickshell.execDetached(["sh", "-c",
            `printf '%s\\n' '${flat.replace(/'/g, "'\\''")}' > "${home}/.cache/rice-update.flat"; ` +
            `printf '%s\\n' '${dnf.replace(/'/g, "'\\''")}' > "${home}/.cache/rice-update.dnf"; ` +
            `echo "${upLog}" > "${home}/.cache/rice-update.current"; ` +
            `setsid "${home}/.config/quickshell/island/update-run.sh" "${upLog}" >/dev/null 2>&1 < /dev/null &`]);
        upState = "running";
    }
    function parseLine(raw) {
        const segs = raw.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, "").split("\r");
        const l = segs[segs.length - 1].trim();
        if (!l) return;
        if (l.startsWith("@@TOTAL")) { const t = l.split(/\s+/); nFlat = +t[1]; nDnf = +t[2]; return; }
        if (l.startsWith("@@PHASE")) { phase = l.split(/\s+/)[1]; return; }
        if (l.startsWith("@@EXIT")) { finishUpdate(+l.split(/\s+/)[1]); return; }
        if (phase === "flatpak") {
            const m = l.match(/^(Updating|Installing)\s+(?:\d+\/\d+…?\s+)?((?:app|runtime)\/\S+)/);
            if (m && !seenRefs[m[2]]) {
                seenRefs[m[2]] = true;
                flatDone++;
                flatItem = 0;
                upItem = m[2].split("/")[1];
            }
            const p = l.match(/(\d{1,3})%/);
            if (p) flatItem = Math.min(1, +p[1] / 100);
            upCounts = "flatpak " + Math.min(flatDone, Math.max(nFlat, flatDone)) + "/" + Math.max(nFlat, flatDone);
        } else if (phase === "dnf") {
            if (/Running transaction|Transaction Summary/i.test(l)) dnfStage = 1;
            const m = l.match(/^\[\s*(\d+)\s*\/\s*(\d+)\s*\]\s*(.*)$/);
            if (m && +m[2] > 0) {
                const f = Math.min(1, +m[1] / +m[2]);
                dnfFrac = dnfStage ? 0.35 + 0.65 * f : 0.35 * f;
                upItem = m[3].replace(/\s+\d+%.*$/, "").replace(/\s*\|.*$/, "");
                upCounts = "system " + m[1] + "/" + m[2];
            } else if (!/^(\s|=|-)/.test(l) && l.length < 120) {
                upItem = l;
            }
        }
        itemProgress = phase === "dnf" ? dnfFrac : flatItem;
        const total = Math.max(1, nFlat + nDnf);
        const flatFrac = nFlat ? Math.min(1, Math.max(0, (flatDone - 1 + flatItem) / nFlat)) : 0;
        const doneFlat = phase === "dnf" ? 1 : flatFrac;
        upProgress = Math.min(0.99, (nFlat * doneFlat + nDnf * dnfFrac) / total);
    }
    function finishUpdate(code) {
        if (upState !== "running") return;
        if (code === 0) { upProgress = 1; upState = "done"; dnfList = []; flatList = []; lastCheck = Date.now(); }
        else { upState = "failed"; upError = (code === 126 || code === 127) ? "Authentication cancelled" : "Exit code " + code + " · log in ~/.cache"; }
        Quickshell.execDetached(["pkill", "-RTMIN+1", "waybar"]);
        settleTimer.restart();
    }
    Timer { id: settleTimer; interval: 9000; onTriggered: if (root.upState === "done" || root.upState === "failed") root.upState = root.upState === "done" ? "ready" : "idle" }

    Process {
        id: tailer
        running: root.upState === "running" && root.upLog !== ""
        command: ["tail", "-n", "+1", "-F", root.upLog]
        stdout: SplitParser { onRead: data => root.parseLine(data) }
    }
    // pick up an update that is still running after a shell restart
    Process {
        running: true
        command: ["sh", "-c", "f=$(cat \"$HOME/.cache/rice-update.current\" 2>/dev/null) && [ -f \"$f\" ] && ! grep -q '^@@EXIT' \"$f\" && pgrep -f update-run.sh >/dev/null && echo \"$f\""]
        stdout: StdioCollector {
            id: resumeOut
            onStreamFinished: {
                const f = resumeOut.text.trim();
                if (!f) return;
                root.upLog = f;
                root.upState = "running";
            }
        }
    }

    Variants {
        model: Quickshell.screens
        delegate: Island { ctx: root }
    }

    Tray { ctx: root }
    Toasts { ctx: root }
}
