import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../core"

PanelWindow {
    id: win

    readonly property int openW: 420
    readonly property int openH: 196
    readonly property int pillH: 32

    screen: UiState.focusedScreen
    visible: UiState.musicOpen || body.height > pillH + 1
    anchors { top: true }
    margins { top: 6 }
    implicitWidth: openW + 20
    implicitHeight: openH
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: body }
    WlrLayershell.namespace: "quickshell-music"
    WlrLayershell.keyboardFocus: UiState.musicOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        windows: [win]
        active: UiState.musicOpen
        onCleared: UiState.closeMusic()
    }

    Connections {
        target: UiState
        function onMusicOpenChanged() { if (UiState.musicOpen) keys.forceActiveFocus(); }
    }

    Rectangle {
        id: body
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: UiState.musicOpen ? win.openW : UiState.centerWidth
        height: UiState.musicOpen ? win.openH : win.pillH
        radius: UiState.musicOpen ? 20 : 12
        color: Theme.base
        clip: true

        Behavior on width  { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on radius { NumberAnimation { duration: 300 } }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            opacity: UiState.musicOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: UiState.musicOpen ? 220 : 90 } }

            Keys.onPressed: e => {
                switch (e.key) {
                case Qt.Key_Space:
                case Qt.Key_K:
                    Media.toggle(); break;
                case Qt.Key_Left:
                case Qt.Key_H:
                    Media.previous(); break;
                case Qt.Key_Right:
                case Qt.Key_L:
                    Media.next(); break;
                case Qt.Key_Escape:
                    UiState.closeMusic(); break;
                default:
                    return;
                }
                e.accepted = true;
            }

            // header
            Item {
                id: header
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: win.pillH
                Txt {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf001  " + (Media.identity !== "" ? Media.identity : "Music")
                    color: Theme.teal
                }
                Txt {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: !Media.has ? "" : (Media.playing ? "Playing" : "Paused")
                    color: Theme.subtext
                    font.pixelSize: 11
                }
            }

            // art + title/artist
            RowLayout {
                id: info
                anchors { top: header.bottom; topMargin: 8; left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
                spacing: 14

                ClippingRectangle {
                    implicitWidth: 64
                    implicitHeight: 64
                    radius: 12
                    color: Theme.surface0
                    Txt { anchors.centerIn: parent; text: "\uf001"; color: Theme.subtext; font.pixelSize: 22; visible: art.status !== Image.Ready }
                    Image {
                        id: art
                        anchors.fill: parent
                        source: Media.art
                        sourceSize.width: 128
                        sourceSize.height: 128
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Txt {
                        Layout.fillWidth: true
                        text: Media.title !== "" ? Media.title : "Nothing playing"
                        elide: Text.ElideRight
                        font.pixelSize: 14
                    }
                    Txt {
                        Layout.fillWidth: true
                        text: Media.artist
                        visible: text !== ""
                        elide: Text.ElideRight
                        color: Theme.subtext
                        font.pixelSize: 12
                    }
                }

                Visualizer {
                    active: UiState.musicOpen && Media.playing
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // progress
            RowLayout {
                id: progress
                anchors { top: info.bottom; topMargin: 12; left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
                spacing: 8
                Txt { text: Media.fmt(Media.position); color: Theme.subtext; font.pixelSize: 11; Layout.preferredWidth: 34 }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 14
                    Rectangle {
                        id: track
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Theme.surface0
                        Rectangle {
                            width: track.width * Media.fraction
                            height: parent.height
                            radius: 2
                            color: Theme.mauve
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: Media.player?.canSeek ?? false
                        onPressed: m => Media.seek(m.x / width)
                        onPositionChanged: m => { if (pressed) Media.seek(m.x / width); }
                    }
                }
                Txt { text: Media.fmt(Media.length); color: Theme.subtext; font.pixelSize: 11; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
            }

            // controls
            RowLayout {
                anchors { top: progress.bottom; topMargin: 8; horizontalCenter: parent.horizontalCenter }
                spacing: 26
                PlayerButton { icon: "\uf048"; enabled: Media.player?.canGoPrevious ?? false; onClicked: Media.previous() }
                PlayerButton { icon: Media.playing ? "\uf04c" : "\uf04b"; size: 40; filled: true; enabled: Media.player?.canTogglePlaying ?? false; onClicked: Media.toggle() }
                PlayerButton { icon: "\uf051"; enabled: Media.player?.canGoNext ?? false; onClicked: Media.next() }
            }
        }
    }
}
