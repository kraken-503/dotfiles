import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import "../components"
import "../core"

PanelWindow {
    id: win
    screen: UiState.focusedScreen
    visible: UiState.ccOpen || body.opacity > 0
    anchors { top: true; right: true }
    margins { top: 44; right: 10 }
    implicitWidth: 340
    implicitHeight: body.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-cc"
    WlrLayershell.keyboardFocus: UiState.ccOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        // The notification window must be whitelisted too: while a grab is active, Hyprland keeps pointer focus
        // on a whitelisted surface, so clicks on a non-whitelisted notification land on the tiles underneath it.
        windows: UiState.notificationWindow ? [win, UiState.notificationWindow] : [win]
        active: UiState.ccOpen
        onCleared: UiState.closeCc()
    }

    property string section: ""           // "", "wifi", "bt", "power"

    readonly property int vpnMaxRows: 8
    readonly property int vpnMaxHeight: vpnMaxRows * 32 + (vpnMaxRows - 1) * 2
    property bool nightOn: false
    property bool nightWanted: false     // what the last click asked for
    property bool nightPending: false    // a click is waiting for its result
    property bool nightFailed: false     // the result did not match the request

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property string btSubtitle: {
        if (!adapter) return "No adapter";
        if (!adapter.enabled) return "Off";
        const d = Bluetooth.devices.values;
        for (let i = 0; i < d.length; i++)
            if (d[i].connected) return d[i].name;
        return "On";
    }

    function profileName(p) {
        return p === PowerProfile.PowerSaver ? "Power saver"
             : p === PowerProfile.Performance ? "Performance" : "Balanced";
    }
    function batteryState() {
        const s = UPower.displayDevice.state;
        return s === UPowerDeviceState.Charging ? "Charging"
             : s === UPowerDeviceState.FullyCharged ? "Full" : "On battery";
    }
    function expand(name) {
        section = section === name ? "" : name;
        if (section === "wifi") Wifi.refresh();
        if (section === "vpn") Vpn.refresh();
    }

    Connections {
        target: UiState
        function onCcOpenChanged() {
            if (UiState.ccOpen) { Wifi.refresh(); Vpn.refresh(); nightCheck.running = true; }
            else win.section = "";
        }
    }

    Process {
        id: nightCheck
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: code => {
            win.nightOn = code === 0;
            if (win.nightPending) {             // this check answers the last click
                win.nightPending = false;
                win.nightFailed = win.nightOn !== win.nightWanted;
            }
        }
    }
    Process {
        // Does not use scripts/hyprsunset-toggle.sh: running -> stop it, otherwise start it detached.
        // hyprsunset's own output goes to /tmp/qs-hyprsunset.log so a failed start can be read.
        id: nightToggle
        command: ["bash", "-c",
            'if pgrep -x hyprsunset >/dev/null; then pkill -x hyprsunset; ' +
            'else setsid -f hyprsunset -t 4500 >/tmp/qs-hyprsunset.log 2>&1; fi']
        onExited: recheck.start()
    }
    Timer { id: recheck; interval: 500; onTriggered: nightCheck.running = true }
    Timer { interval: 2000; running: UiState.ccOpen; repeat: true; onTriggered: nightCheck.running = true }

    Rectangle {
        id: body
        width: parent.width
        radius: 18
        color: Theme.base
        border.width: 1
        border.color: Theme.surface0
        implicitHeight: col.implicitHeight + 28
        opacity: UiState.ccOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: UiState.ccOpen ? 0 : -8
            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            spacing: 10

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10
                uniformCellWidths: true

                Tile {
                    icon: "\uf1eb"
                    title: "Wi-Fi"
                    subtitle: !Wifi.enabled ? "Off" : (Wifi.ssid !== "" ? Wifi.ssid : "Not connected")
                    active: Wifi.enabled
                    expandable: true
                    expanded: win.section === "wifi"
                    onToggled: Wifi.setEnabled(!Wifi.enabled)
                    onExpandRequested: win.expand("wifi")
                }
                Tile {
                    icon: "\uf294"
                    title: "Bluetooth"
                    subtitle: win.btSubtitle
                    active: win.adapter?.enabled ?? false
                    expandable: true
                    expanded: win.section === "bt"
                    onToggled: { if (win.adapter) win.adapter.enabled = !win.adapter.enabled; }
                    onExpandRequested: win.expand("bt")
                }
                Tile {
                    icon: "\uf132"
                    title: "VPN"
                    subtitle: Vpn.activeName !== "" ? Vpn.activeName : (Vpn.profiles.length > 0 ? "Off" : "No profiles")
                    active: Vpn.activeProfiles.length > 0
                    expandable: true
                    expanded: win.section === "vpn"
                    onToggled: { if (Vpn.activeProfiles.length > 0) Vpn.disconnectAll(); else win.expand("vpn"); }
                    onExpandRequested: win.expand("vpn")
                }
                Tile {
                    icon: "\uf186"
                    title: "Night light"
                    subtitle: win.nightFailed ? "Failed, see /tmp/qs-hyprsunset.log" : (win.nightOn ? "On" : "Off")
                    active: win.nightOn
                    onToggled: {
                        if (nightToggle.running) return;
                        win.nightFailed = false;
                        win.nightWanted = !win.nightOn;
                        win.nightPending = true;
                        nightToggle.running = true;
                    }
                }
                Tile {
                    Layout.columnSpan: 2
                    icon: "\uf0e7"
                    title: "Power mode"
                    subtitle: win.profileName(PowerProfiles.profile)
                    active: PowerProfiles.profile !== PowerProfile.Balanced
                    expandable: true
                    expanded: win.section === "power"
                    onToggled: win.expand("power")
                    onExpandRequested: win.expand("power")
                }
            }

            // ── Wi-Fi list ─────────────────────
            ColumnLayout {
                visible: win.section === "wifi"
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: Wifi.networks
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2
                        ListRow {
                            label: modelData.ssid
                            trailing: (modelData.secure ? "\uf023  " : "") + modelData.signal + "%"
                            active: modelData.active
                            onClicked: { if (!modelData.active) Wifi.connectTo(modelData.ssid, ""); }
                        }
                        ListRow {
                            visible: modelData.active
                            indent: 14
                            label: "Disconnect"
                            labelColor: Theme.red
                            onClicked: Wifi.disconnect()
                        }
                    }
                }
                Txt {
                    visible: Wifi.enabled && Wifi.networks.length === 0
                    text: "No networks found"
                    color: Theme.subtext
                    font.pixelSize: 11
                }
                Txt {
                    visible: Wifi.message !== ""
                    text: Wifi.message
                    color: Theme.subtext
                    font.pixelSize: 11
                }
                Rectangle {
                    visible: Wifi.pendingSsid !== ""
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 10
                    color: Theme.surface0

                    TextInput {
                        id: pw
                        anchors.fill: parent
                        anchors.margins: 9
                        echoMode: TextInput.Password
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 12
                        clip: true
                        onAccepted: { Wifi.connectTo(Wifi.pendingSsid, text); text = ""; }
                        Txt {
                            visible: !pw.text
                            text: "Password for " + Wifi.pendingSsid + " (Enter)"
                            color: Theme.subtext
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // ── Bluetooth list ─────────────────
            ColumnLayout {
                visible: win.section === "bt"
                Layout.fillWidth: true
                spacing: 2

                Repeater {
                    model: Bluetooth.devices
                    delegate: ListRow {
                        required property var modelData
                        visible: modelData.paired
                        label: modelData.name
                        trailing: modelData.connected ? "Connected" : ""
                        active: modelData.connected
                        onClicked: { if (modelData.connected) modelData.disconnect(); else modelData.connect(); }
                    }
                }
            }

            // ── VPN profiles ───────────────────
            ColumnLayout {
                visible: win.section === "vpn"
                Layout.fillWidth: true
                spacing: 2

                ListView {
                    id: vpnList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, win.vpnMaxHeight)
                    visible: Vpn.profiles.length > 0
                    clip: true
                    spacing: 2
                    model: Vpn.profiles
                    boundsBehavior: Flickable.StopAtBounds

                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        id: vpnBar
                        policy: QQC.ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: Theme.mauve
                            opacity: vpnBar.active ? 0.9 : 0.4
                        }
                    }

                    delegate: ColumnLayout {
                        required property var modelData
                        width: vpnList.width - 10          // leave room for the scrollbar
                        spacing: 2
                        ListRow {
                            label: modelData.name
                            trailing: modelData.active ? "Connected" : ""
                            active: modelData.active
                            onClicked: { if (!modelData.active) Vpn.connectTo(modelData); }
                        }
                        ListRow {
                            visible: modelData.active
                            indent: 14
                            label: "Disconnect"
                            labelColor: Theme.red
                            onClicked: Vpn.disconnect(modelData)
                        }
                    }
                }
                Txt {
                    visible: Vpn.profiles.length === 0
                    text: "No VPN profiles in NetworkManager"
                    color: Theme.subtext
                    font.pixelSize: 11
                }
                Txt {
                    visible: Vpn.message !== ""
                    text: Vpn.message
                    color: Theme.subtext
                    font.pixelSize: 11
                }
            }

            // ── Power profiles ─────────────────
            RowLayout {
                visible: win.section === "power"
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { p: PowerProfile.PowerSaver, n: "Saver" },
                        { p: PowerProfile.Balanced, n: "Balanced" },
                        { p: PowerProfile.Performance, n: "Performance" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        visible: modelData.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 10
                        color: PowerProfiles.profile === modelData.p ? Qt.alpha(Theme.mauve, 0.18)
                             : (pa.containsMouse ? Theme.surface0 : Theme.mantle)
                        Txt {
                            anchors.centerIn: parent
                            text: modelData.n
                            font.pixelSize: 12
                            color: PowerProfiles.profile === modelData.p ? Theme.mauve : Theme.text
                        }
                        MouseArea { id: pa; anchors.fill: parent; hoverEnabled: true; onClicked: PowerProfiles.profile = modelData.p }
                    }
                }
            }

            // ── Sliders ────────────────────────
            Slider {
                Layout.fillWidth: true
                icon: Audio.muted ? "\uf026" : "\uf028"
                value: Audio.volume
                onMoved: v => Audio.setVolume(v)
            }
            Slider {
                Layout.fillWidth: true
                icon: "\uf185"
                value: Brightness.percent / 100
                onMoved: v => Brightness.set(v * 100)
            }

            // ── Battery footer ─────────────────
            RowLayout {
                visible: UPower.displayDevice.isPresent
                Layout.fillWidth: true
                Txt { text: "\uf240  " + Math.round(UPower.displayDevice.percentage * 100) + "%"; color: Theme.subtext; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                Txt { text: win.batteryState(); color: Theme.subtext; font.pixelSize: 12 }
            }
        }
    }
}
