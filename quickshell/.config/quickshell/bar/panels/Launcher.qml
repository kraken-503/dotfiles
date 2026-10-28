import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../core"

PanelWindow {
    id: win

    readonly property color cBackground: Theme.bg   // follows the theme
    readonly property color cBackgroundAlt: Theme.surface0   // follows the theme
    readonly property color cForeground: Theme.text   // follows the theme
    readonly property color cSelected: Theme.selected   // follows the theme
    readonly property color cSelectedText: Theme.selectedText   // follows the theme
    readonly property color cActive: Theme.green   // follows the theme
    readonly property color cUrgent: Theme.red   // follows the theme
    readonly property color cDarkText: Theme.base   // follows the theme
    readonly property string fontFamily:    Theme.font  // rofi: "JetBrains Mono Nerd Font"
    readonly property real fontPt:          10
    readonly property string terminal:      "rofi-sensible-terminal"
    readonly property string fallbackIcon:  "application-x-addon"
    readonly property int maxHistory:       25
    readonly property bool cycle:           true
    readonly property string promptIcon:    "\uf002"    // textbox-prompt-colon str

    readonly property var modes: [
        { id: "drun",        icon: "\uf009" },
        { id: "run",         icon: "\uf120" },
        { id: "filebrowser", icon: "\uf07b" },
        { id: "window",      icon: "\uf2d0" }
    ]
    // ────────────────────────────────────────────────────────────────────

    implicitWidth: 700
    implicitHeight: 600
    screen: UiState.focusedScreen
    visible: UiState.launcherOpen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: UiState.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string mode: "drun"
    property string query: ""
    property int sel: 0
    property string fbDir: Quickshell.env("HOME")
    property var history: ({})
    property var runNames: []
    property var windows: []
    property var dirEntries: []

    // ── data sources ────────────────────────────────────────────────────
    function fold(s) { 
        let t = String(s === undefined || s === null ? "" : s).toLowerCase();
        try { t = t.normalize("NFD").replace(/[\u0300-\u036f]/g, ""); } catch (e) {}
        return t;
    }

    function iconSource(name) {
        if (!name) return Quickshell.iconPath(fallbackIcon);
        if (name.startsWith("/")) return "file://" + name;
        return Quickshell.iconPath(name, fallbackIcon);
    }

    function byHistory(a, b) {
        const h = history;
        return ((h[b.key] || 0) - (h[a.key] || 0)) || a.title.localeCompare(b.title);
    }

    readonly property var drunItems: {
        const apps = DesktopEntries.applications.values;
        const out = [];
        for (let i = 0; i < apps.length; i++) {
            const e = apps[i];
            if (e.noDisplay) continue;
            out.push({
                title: e.name,
                icon: e.icon,
                entry: e,
                key: e.id,
                hay: fold([e.name, e.genericName, (e.command || []).join(" "),
                           (e.categories || []).join(" "), (e.keywords || []).join(" ")].join("\n"))
            });
        }
        out.sort(byHistory);
        return out;
    }

    readonly property var runItems: {
        const out = runNames.map(n => ({ title: n, icon: "", key: "run:" + n, hay: fold(n) }));
        out.sort(byHistory);
        return out;
    }

    readonly property var windowItems: windows.map(w => ({
        title: w["class"] + " · " + w.title,                 // window-format "{c} · {t}"
        icon: String(w["class"]).toLowerCase(),
        key: w.address,
        address: w.address,
        hay: fold(w.title + "\n" + w["class"]),              // window-match-fields title,class
        active: w.focusHistoryID === 0,
        urgent: false
    }))

    readonly property var fileItems: dirEntries.map(d => ({
        title: d.title,
        name: d.name,
        isDir: d.isDir,
        icon: d.isDir ? "folder" : "text-x-generic",
        key: d.name,
        hay: fold(d.name)
    }))

    readonly property var sourceItems:
        mode === "drun" ? drunItems
        : mode === "run" ? runItems
        : mode === "window" ? windowItems
        : fileItems

    readonly property var filtered: {
        const tokens = fold(query).split(/\s+/).filter(t => t !== "");
        if (tokens.length === 0) return sourceItems;
        return sourceItems.filter(it => tokens.every(t => it.hay.indexOf(t) >= 0));
    }
    onFilteredChanged: sel = 0

    // ── actions ─────────────────────────────────────────────────────────
    function dismiss() { UiState.closeLauncher(); }

    function bump(key) {
        const h = Object.assign({}, history);
        h[key] = (h[key] || 0) + 1;
        const keys = Object.keys(h).sort((a, b) => h[b] - h[a]).slice(0, maxHistory);
        const pruned = {};
        keys.forEach(k => pruned[k] = h[k]);
        history = pruned;
        saver.command = ["bash", "-c",
            'mkdir -p ~/.cache/quickshell-bar && printf "%s" "$1" > ~/.cache/quickshell-bar/launcher-history.json',
            "save", JSON.stringify(pruned)];
        saver.running = true;
    }

    function runCommand(cmd, inTerminal) {
        if (inTerminal) Quickshell.execDetached([terminal, "-e", "bash", "-c", cmd]);
        else Quickshell.execDetached(["bash", "-c", cmd]);
    }

    function enterDir(name) {
        if (name === "..") fbDir = fbDir.replace(/\/[^\/]*\/?$/, "") || "/";
        else fbDir = (fbDir === "/" ? "" : fbDir) + "/" + name;
        entryInput.text = "";
        sel = 0;
        loadDir();
    }

    function accept(alt) {                  // alt = Shift+Return
        const it = filtered[sel];
        if (!it) return;
        if (mode === "drun") {
            const e = it.entry;
            if (e.runInTerminal)
                Quickshell.execDetached([terminal, "-e"].concat((e.command || []).filter(a => !/^%[a-zA-Z]$/.test(a))));
            else e.execute();
            bump(it.key);
            dismiss();
        } else if (mode === "run") {
            runCommand(it.title, alt);
            bump(it.key);
            dismiss();
        } else if (mode === "window") {
            Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + it.address]);
            dismiss();
        } else if (it.isDir) {
            enterDir(it.name);
        } else {
            Quickshell.execDetached(["xdg-open", fbDir + "/" + it.name]);
            dismiss();
        }
    }

    function acceptCustom() {               // Ctrl+Return: run what was typed
        if (query.trim() === "" || (mode !== "drun" && mode !== "run")) return;
        runCommand(query, false);
        dismiss();
    }

    function move(d) {
        const n = filtered.length;
        if (n === 0) return;
        sel = cycle ? (sel + d + n) % n : Math.max(0, Math.min(n - 1, sel + d));
    }
    function movePage(d) {
        const n = filtered.length;
        if (n === 0) return;
        const rows = Math.max(1, Math.floor(list.height / 59));
        sel = Math.max(0, Math.min(n - 1, sel + d * rows));
    }

    function modeIndex(id) {
        for (let i = 0; i < modes.length; i++) if (modes[i].id === id) return i;
        return 0;
    }
    function setMode(id) { mode = id; sel = 0; enterMode(); }
    function cycleMode(d) { setMode(modes[(modeIndex(mode) + d + modes.length) % modes.length].id); }

    function loadDir() { if (!lsProc.running) lsProc.running = true; }
    function enterMode() {
        if (mode === "run" && !runProc.running) runProc.running = true;
        else if (mode === "window" && !clientsProc.running) clientsProc.running = true;
        else if (mode === "filebrowser") loadDir();
    }

    function handleKey(e) {
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
        const shift = (e.modifiers & Qt.ShiftModifier) !== 0;
        const k = e.key;
        const ret = (k === Qt.Key_Return || k === Qt.Key_Enter);
        const alt = (e.modifiers & Qt.AltModifier) !== 0;
        const inp = entryInput;

        if (k === Qt.Key_Escape || (ctrl && (k === Qt.Key_G || k === Qt.Key_BracketLeft))) dismiss();
        else if (ctrl && ret) acceptCustom();
        else if (ret || (ctrl && (k === Qt.Key_J || k === Qt.Key_M))) accept(shift);
        // mode switching: Alt+1..4 jump straight to a mode
        else if (alt && !ctrl && k >= Qt.Key_1 && k < Qt.Key_1 + modes.length) setMode(modes[k - Qt.Key_1].id);
        else if ((shift && k === Qt.Key_Right) || (ctrl && !shift && k === Qt.Key_Tab)) cycleMode(1);
        else if ((shift && k === Qt.Key_Left) || (ctrl && (k === Qt.Key_Backtab || (shift && k === Qt.Key_Tab)))) cycleMode(-1);
        // list navigation
        else if (k === Qt.Key_Down || k === Qt.Key_Tab || (ctrl && k === Qt.Key_N)) move(1);
        else if (k === Qt.Key_Up || k === Qt.Key_Backtab || (ctrl && k === Qt.Key_P)) move(-1);
        else if (k === Qt.Key_PageDown) movePage(1);
        else if (k === Qt.Key_PageUp) movePage(-1);
        else if (k === Qt.Key_Home) sel = 0;
        else if (k === Qt.Key_End) sel = Math.max(0, filtered.length - 1);
        // emacs-style line editing (rofi defaults)
        else if (ctrl && k === Qt.Key_A) inp.cursorPosition = 0;
        else if (ctrl && k === Qt.Key_E) inp.cursorPosition = inp.length;
        else if (ctrl && k === Qt.Key_B) inp.cursorPosition = Math.max(0, inp.cursorPosition - 1);
        else if (ctrl && k === Qt.Key_F) inp.cursorPosition = Math.min(inp.length, inp.cursorPosition + 1);
        else if (ctrl && k === Qt.Key_U) inp.remove(0, inp.cursorPosition);
        else if (ctrl && k === Qt.Key_K) inp.remove(inp.cursorPosition, inp.length);
        else if (ctrl && k === Qt.Key_W) inp.text = "";
        else if (ctrl && k === Qt.Key_H) inp.remove(Math.max(0, inp.cursorPosition - 1), inp.cursorPosition);
        else if (ctrl && k === Qt.Key_D) inp.remove(inp.cursorPosition, inp.cursorPosition + 1);
        else return false;
        return true;
    }

    // ── open / close ────────────────────────────────────────────────────
    Connections {
        target: UiState
        function onLauncherOpenChanged() {
            if (!UiState.launcherOpen) return;
            win.mode = UiState.launcherMode;
            win.fbDir = Quickshell.env("HOME");
            win.sel = 0;
            entryInput.text = "";
            win.query = "";
            win.enterMode();
            entryInput.forceActiveFocus();
        }
    }
    onVisibleChanged: if (visible) Qt.callLater(() => entryInput.forceActiveFocus())

    // ── processes ───────────────────────────────────────────────────────
    FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell-bar/launcher-history.json"
        printErrors: false
        onLoaded: { try { win.history = JSON.parse(text()); } catch (e) {} }
    }
    Process { id: saver }

    Process {       // run mode: everything executable on $PATH
        id: runProc
        command: ["bash", "-c", `IFS=:; for d in $PATH; do [ -d "$d" ] && find "$d" -maxdepth 1 -executable ! -type d -printf '%f\\n' 2>/dev/null; done | sort -u`]
        stdout: StdioCollector { onStreamFinished: win.runNames = this.text.split("\n").filter(s => s !== "") }
    }

    Process {       // window mode
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(this.text);
                    win.windows = arr.filter(c => c.mapped !== false)
                                     .sort((a, b) => a.focusHistoryID - b.focusHistoryID);
                } catch (e) { win.windows = []; }
            }
        }
    }

    Process {       // filebrowser mode: directories first, sorted by name
        id: lsProc
        command: ["bash", "-c", 'cd "$1" 2>/dev/null && ls -1 -p --group-directories-first', "ls", win.fbDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                if (win.fbDir !== "/") out.push({ title: "..", name: "..", isDir: true });
                const lines = this.text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i];
                    if (!l) continue;
                    const isDir = l.endsWith("/");
                    const name = isDir ? l.slice(0, -1) : l;
                    out.push({ title: name + (isDir ? "/" : ""), name: name, isDir: isDir });
                }
                win.dirEntries = out;
            }
        }
    }

    component LText: Text {
        property var cfg: null
        color: cfg ? cfg.cForeground : "#CDD6F4"
        font.family: cfg ? cfg.fontFamily : "monospace"
        font.pointSize: cfg ? cfg.fontPt : 10
        verticalAlignment: Text.AlignVCenter
    }

    // ── UI ──────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: win.cBackground

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // inputbar
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 35
                spacing: 10

                Rectangle {
                    implicitWidth: promptText.implicitWidth + 30
                    implicitHeight: promptText.implicitHeight + 24
                    radius: height / 2
                    color: win.cBackgroundAlt
                    LText { cfg: win; id: promptText; anchors.centerIn: parent; text: win.promptIcon }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: promptText.implicitHeight + 24
                    radius: height / 2
                    color: win.cBackgroundAlt

                    TextInput {
                        id: entryInput
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        color: win.cForeground
                        selectionColor: win.cSelected
                        selectedTextColor: win.cSelectedText
                        font.family: win.fontFamily
                        font.pointSize: win.fontPt
                        clip: true
                        focus: true
                        onTextChanged: win.query = text
                        Keys.onPressed: e => { if (win.handleKey(e)) e.accepted = true; }

                        LText { cfg: win;
                            visible: !entryInput.text
                            text: "Search"              // placeholder, same color as the text
                        }
                    }
                }
            }

            // listbox
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 20
                spacing: 20

                Rectangle {                              // message: current folder
                    visible: win.mode === "filebrowser"
                    Layout.fillWidth: true
                    implicitHeight: msg.implicitHeight + 24
                    radius: height / 2
                    color: win.cBackgroundAlt
                    LText { cfg: win;
                        id: msg
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        elide: Text.ElideMiddle
                        text: win.fbDir.replace(Quickshell.env("HOME"), "~")
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 10
                    interactive: false
                    model: win.filtered
                    currentIndex: win.sel
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    WheelHandler { onWheel: e => win.move(e.angleDelta.y > 0 ? -1 : 1) }

                    delegate: Rectangle {
                        id: el
                        required property var modelData
                        required property int index
                        readonly property bool selected: index === win.sel
                        readonly property bool active: modelData.active === true
                        readonly property bool urgent: modelData.urgent === true

                        width: ListView.view.width
                        height: 49
                        radius: height / 2
                        // normal/selected × normal/active/urgent, as in style.rasi
                        color: (urgent || (selected && active)) ? win.cUrgent
                             : selected ? win.cSelected
                             : active ? win.cActive
                             : "transparent"
                        readonly property color fg: (urgent || active) ? win.cDarkText
                                                  : selected ? win.cSelectedText
                                                  : win.cForeground

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Image {
                                Layout.preferredWidth: 25
                                Layout.preferredHeight: 25
                                source: win.iconSource(el.modelData.icon)
                                sourceSize.width: 50
                                sourceSize.height: 50
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                            }
                            LText { cfg: win;
                                Layout.fillWidth: true
                                text: el.modelData.title
                                color: el.fg
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: win.sel = el.index            // MousePrimary: select
                            onDoubleClicked: { win.sel = el.index; win.accept(false); }   // MouseDPrimary: accept
                        }
                    }
                }

                // mode-switcher
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: win.modes
                        delegate: Rectangle {
                            id: btn
                            required property var modelData
                            readonly property bool current: win.mode === modelData.id
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: btnText.implicitHeight + 24
                            radius: height / 2
                            color: current ? win.cSelected : win.cBackgroundAlt
                            LText { cfg: win;
                                id: btnText
                                anchors.centerIn: parent
                                text: btn.modelData.icon
                                color: btn.current ? win.cSelectedText : win.cForeground
                            }
                            MouseArea { anchors.fill: parent; onClicked: win.setMode(btn.modelData.id) }
                        }
                    }
                }
            }
        }
    }
}
