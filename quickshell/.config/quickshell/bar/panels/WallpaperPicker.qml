import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../core"

PanelWindow {
    id: win

    // ── edit these two ─────────────────────
    property string dir: Quickshell.env("HOME") + "/Pictures/walls/"
    property string transition: "random"
    // ───────────────────────────────────────

    readonly property int cellW: 220
    readonly property int cellH: 124
    readonly property int openW: 780
    readonly property int openH: 200
    readonly property int pillH: 32

    screen: UiState.focusedScreen
    visible: UiState.wpOpen || body.height > pillH + 1
    anchors { top: true }
    margins { top: 6 }                 
    implicitWidth: openW + 20
    implicitHeight: openH
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: body }       
    WlrLayershell.namespace: "quickshell-wallpapers"
    WlrLayershell.keyboardFocus: UiState.wpOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        windows: [win]
        active: UiState.wpOpen
        onCleared: UiState.closeWp()
    }

    function indexOfApplied() {
        for (let i = 0; i < files.count; i++)
            if (files.get(i, "filePath") === UiState.wallpaper) return i;
        return 0;
    }

    Connections {
        target: UiState
        function onWpOpenChanged() {
            if (!UiState.wpOpen) return;
            list.currentIndex = win.indexOfApplied();
            list.positionViewAtIndex(list.currentIndex, ListView.Center);
            list.forceActiveFocus();
        }
    }

    // awww 
    readonly property string applyScript: `
        bin=$(command -v awww || command -v swww) || exit 3
        daemon="$bin-daemon"
        pgrep -x "$(basename "$daemon")" >/dev/null || { setsid "$daemon" >/dev/null 2>&1 & sleep 0.6; }
        "$bin" img "$1" --transition-type "$2" --transition-duration 2 --transition-fps 60
        mkdir -p ~/.cache/quickshell-bar && printf '%s' "$1" > ~/.cache/quickshell-bar/wallpaper
    `

    Process { id: apply }
    function applyWallpaper(path) {
        if (!path) return;
        UiState.wallpaper = path;
        apply.command = ["bash", "-c", applyScript, "wp", path, transition];
        apply.running = true;
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell-bar/wallpaper"
        printErrors: false
        onLoaded: UiState.wallpaper = text().trim()
    }

    FolderListModel {
        id: files
        folder: "file://" + encodeURI(win.dir)
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.bmp", "*.avif"]
        caseSensitive: false
        showDirs: false
        sortField: FolderListModel.Name
    }

    Rectangle {
        id: body
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: UiState.wpOpen ? win.openW : UiState.centerWidth
        height: UiState.wpOpen ? win.openH : win.pillH
        radius: UiState.wpOpen ? 20 : 12
        color: Theme.base
        clip: true

        Behavior on width  { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on radius { NumberAnimation { duration: 300 } }

        Item {
            anchors.fill: parent
            opacity: UiState.wpOpen ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: UiState.wpOpen ? 220 : 90 } }

            // header: takes the place of the pill's own row
            Item {
                id: header
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: win.pillH

                Txt {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf03e  Wallpapers"
                    color: Theme.teal
                }
                Txt {
                    anchors.centerIn: parent
                    width: parent.width - 260
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    text: list.currentItem ? list.currentItem.fileName : ""
                }
                Txt {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.subtext
                    text: files.count > 0 ? (list.currentIndex + 1) + " / " + files.count : ""
                }
            }

            ListView {
                id: list
                anchors { top: header.bottom; topMargin: 8; left: parent.left; right: parent.right }
                height: win.cellH + 16
                orientation: ListView.Horizontal
                spacing: 12
                clip: true
                model: files
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationEnabled: false

                // keep the current item centered
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
                        if (currentItem) win.applyWallpaper(currentItem.filePath);
                        break;
                    case Qt.Key_Escape:
                        UiState.closeWp(); break;
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
                    required property string fileName
                    required property string filePath
                    required property url fileUrl
                    readonly property bool current: ListView.isCurrentItem

                    width: win.cellW
                    height: list.height
                    scale: current ? 1 : 0.88
                    opacity: current ? 1 : 0.6
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    ClippingRectangle {
                        anchors.centerIn: parent
                        width: win.cellW
                        height: win.cellH
                        radius: 14
                        color: Theme.surface0
                        border.width: cell.current ? 2 : 0
                        border.color: Theme.mauve

                        Image {
                            anchors.fill: parent
                            source: cell.fileUrl
                            sourceSize.width: 440
                            sourceSize.height: 248
                            asynchronous: true
                            cache: false
                            fillMode: Image.PreferAspectCrop
                        }

                        // badge on the wallpaper that is currently applied
                        Rectangle {
                            visible: UiState.wallpaper === cell.filePath
                            anchors { right: parent.right; top: parent.top; margins: 8 }
                            width: 22; height: 22; radius: 11
                            color: Theme.mauve
                            Txt { anchors.centerIn: parent; text: "\uf00c"; color: Theme.base; font.pixelSize: 11 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                list.currentIndex = cell.index;
                                win.applyWallpaper(cell.filePath);
                            }
                        }
                    }
                }
            }

            Txt {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 10 }
                text: files.count === 0
                    ? "No images in " + win.dir
                    : ""
                color: Theme.subtext
                font.pixelSize: 11
            }
        }
    }
}
