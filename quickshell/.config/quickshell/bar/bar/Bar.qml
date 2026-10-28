import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"
import "../core"

PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    margins { top: 6; left: 10; right: 10 }
    implicitHeight: 32
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"

    Item {
        anchors.fill: parent

        // ── left ──────────────────────────────
        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Skull { Layout.rightMargin: 15 }
            Workspaces { Layout.rightMargin: 8 }
        }

        // ── center ────────────────────────────
        Pill {
            anchors.centerIn: parent
            radius: 12
            hPad: 12
            onWidthChanged: UiState.centerWidth = width
            Component.onCompleted: UiState.centerWidth = width

            ClockModule {}

            ScriptLabel {            // custom/microphone
                script: "bash '" + Quickshell.shellPath("scripts/mic-status.sh") + "'"
                interval: 1000
                pixelSize: 18
                hPad: 6
                classColors: ({ active: Theme.text, muted: Theme.teal })
            }
            ScriptLabel {            // custom/webcam
                script: "bash '" + Quickshell.shellPath("scripts/webcam-status.sh") + "'"
                interval: 2000
                hPad: 6
                baseColor: Theme.subtext
            }
            ScriptLabel {            // custom/obs
                script: "bash '" + Quickshell.shellPath("scripts/obs-status.sh") + "'"
                interval: 2000
                baseColor: Theme.subtext
                classColors: ({ recording: Theme.red })
                blinkClass: "recording"
            }
        }

        // ── right ─────────────────────────────
        Pill {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            radius: 12
            hPad: 8

            Backlight {}
            Volume {}
            Battery {}
            IconButton {            // control center; icon/colors come from NetStyle.qml
                icon: NetStyle.current.icon
                tint: NetStyle.current.color
                idleOpacity: NetStyle.current.opacity
                active: UiState.ccOpen
                onClicked: UiState.toggleCc()
            }
        }
    }
}
