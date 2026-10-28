import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components"
import "../core"

PanelWindow {
    id: win

    readonly property int cellW: 150
    readonly property int cellH: 100
    readonly property int openW: 680
    readonly property int openH: 180
    readonly property int pillH: 32

    screen: UiState.focusedScreen
    visible: UiState.themeOpen || body.height > pillH + 1
    anchors { top: true }
    margins { top: 6 }
    implicitWidth: openW + 20
    implicitHeight: openH
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: body }
    WlrLayershell.namespace: "quickshell-themes"
    WlrLayershell.keyboardFocus: UiState.themeOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        windows: [win]
        active: UiState.themeOpen
        onCleared: UiState.closeTheme()
    }

    Connections {
        target: UiState
        function onThemeOpenChanged() {
            if (!UiState.themeOpen) return;
            list.currentIndex = Math.max(0, Themes.names.indexOf(Themes.name));
            list.positionViewAtIndex(list.currentIndex, ListView.Center);
            list.forceActiveFocus();
        }
    }

    Rectangle {
        id: body
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: UiState.themeOpen ? win.openW : UiState.centerWidth
        height: UiState.themeOpen ? win.openH : win.pillH
        radius: UiState.themeOpen ? 29 : 12
        color: Theme.base
        clip: true

        Behavior on width  { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on radius { NumberAnimation { duration: 300 } }

        Item {
            anchors.fill: parent
            opacity: UiState.themeOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: UiState.themeOpen ? 220 : 90 } }

            Item {
                id: header
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: win.pillH
                Txt {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Theme:"
                    color: Theme.teal
                }
                Txt {
                    anchors.centerIn: parent
                    text: list.currentItem ? list.currentItem.modelData : ""
                }
                Txt {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.subtext
                    text: (list.currentIndex + 1) + " / " + Themes.names.length
                }
            }

            ListView {
                id: list
                anchors { top: header.bottom; topMargin: 8; left: parent.left; right: parent.right }
                height: win.cellH + 16
                orientation: ListView.Horizontal
                spacing: 12
                clip: true
                model: Themes.names
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false

                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: (width - win.cellW) / 2
                preferredHighlightEnd: (width + win.cellW) / 2
                highlightMoveDuration: 220

                Keys.onPressed: e => {
                    switch (e.key) {
                    case Qt.Key_Left:
                    case Qt.Key_H:
                        decrementCurrentIndex(); break;
                    case Qt.Key_Right:
                    case Qt.Key_L:
                        incrementCurrentIndex(); break;
                    case Qt.Key_Home: currentIndex = 0; break;
                    case Qt.Key_End: currentIndex = count - 1; break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                    case Qt.Key_Space:
                        if (currentItem) { Themes.apply(currentItem.modelData); ThemeExport.exportAll(); }
                        break;
                    case Qt.Key_Escape:
                        UiState.closeTheme(); break;
                    default:
                        return;
                    }
                    e.accepted = true;
                }

                WheelHandler {
                    onWheel: e => {
                        if (e.angleDelta.y > 0 || e.angleDelta.x > 0) list.decrementCurrentIndex();
                        else list.incrementCurrentIndex();
                    }
                }

                delegate: Item {
                    id: cell
                    required property int index
                    required property string modelData
                    readonly property var pal: Themes.palettes[modelData]
                    readonly property bool current: ListView.isCurrentItem

                    width: win.cellW
                    height: list.height
                    scale: current ? 1 : 0.88
                    opacity: current ? 1 : 0.6
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: win.cellW
                        height: win.cellH
                        radius: 14
                        color: cell.pal.bg
                        border.width: cell.current ? 2 : 1
                        border.color: cell.current ? Theme.accent : cell.pal.surface0

                        Column {
                            anchors.centerIn: parent
                            spacing: 14

                            // the theme's own colors as dots
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 6
                                Repeater {
                                    model: Themes.dots(cell.pal)
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 16
                                        height: 16
                                        radius: 8
                                        color: modelData
                                    }
                                }
                            }

                        }

                        // marks the theme that is currently applied
                        Rectangle {
                            visible: Themes.name === cell.modelData
                            anchors { right: parent.right; top: parent.top; margins: 8 }
                            width: 20; height: 20; radius: 10
                            color: cell.pal.accent
                            Text {
                                anchors.centerIn: parent
                                text: "\uf00c"
                                color: cell.pal.base
                                font.family: Theme.font
                                font.pixelSize: 6
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                list.currentIndex = cell.index;
                                Themes.apply(cell.modelData);
                                ThemeExport.exportAll();
                            }
                        }
                    }
                }
            }

            Txt {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 10 }
                color: Theme.subtext
                font.pixelSize: 11
            }
        }
    }
}
