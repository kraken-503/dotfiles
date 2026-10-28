import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"

PanelWindow {
    id: win

    readonly property int timeoutMs: 1000
    readonly property real bottomFraction: 0.15          // gap above the bottom edge, as a share of screen height
    readonly property color bg: Qt.alpha(Theme.bg, 0.45)
    readonly property color frame: Qt.alpha(Theme.surface0, 0.6)
    readonly property color fg: Theme.text
    readonly property color trough: Theme.surface0
    readonly property color progress: Theme.mauve
    readonly property int iconSize: 18
    function iconFor(kind, level, muted) {
        if (kind === "brightness") return "\uf185";
        if (muted) return "\uf6a9";
        if (level <= 0) return "\uf026";
        return level < 0.5 ? "\uf027" : "\uf028";
    }
    // ─────────────────────────────────────────────────────────────────────

    property string kind: "volume"
    property bool shown: false
    property bool ready: false           // ignore the changes that happen while everything loads

    readonly property bool muted: kind === "volume" && Audio.muted
    readonly property real level: muted ? 0 : Math.max(0, Math.min(1, kind === "volume" ? Audio.volume : Brightness.percent / 100))

    function pop(k) {
        if (!ready || UiState.ccOpen) return;     // control center sliders already show the value
        kind = k;
        shown = true;
        hide.restart();
    }

    Timer { interval: 2000; running: true; onTriggered: win.ready = true }
    Timer { id: hide; interval: win.timeoutMs; onTriggered: win.shown = false }

    Connections {
        target: Audio
        function onVolumeChanged() { win.pop("volume"); }
        function onMutedChanged() { win.pop("volume"); }
    }
    Connections {
        target: Brightness
        function onPercentChanged() { win.pop("brightness"); }
    }

    screen: UiState.focusedScreen
    visible: shown || body.opacity > 0
    anchors { bottom: true }
    margins { bottom: Math.round((screen ? screen.height : 1080) * win.bottomFraction) }
    implicitWidth: body.implicitWidth
    implicitHeight: body.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}                                  // never takes clicks
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"

    Rectangle {
        id: body
        anchors.fill: parent
        radius: 20
        color: win.bg
        border.width: 1
        border.color: win.frame
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        implicitWidth: row.implicitWidth + 48        // padding 20 + container margin 4, both sides
        implicitHeight: row.implicitHeight + 32      // padding 12 + container margin 4, both sides

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: win.iconSize + 4
                horizontalAlignment: Text.AlignHCenter
                text: win.iconFor(win.kind, win.level, win.muted)
                color: win.fg
                font.family: Theme.font
                font.pixelSize: win.iconSize
            }

            Rectangle {                              // trough
                anchors.verticalCenter: parent.verticalCenter
                width: 150
                height: 6
                radius: 6
                color: win.trough

                Rectangle {                          // progress
                    width: parent.width * win.level
                    height: parent.height
                    radius: 6
                    color: win.progress
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
            }
        }
    }
}
