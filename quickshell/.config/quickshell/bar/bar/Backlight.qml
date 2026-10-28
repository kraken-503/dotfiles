import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../core"

Item {
    id: root
    readonly property var icons: ["󰃞", "󰃟", "󰃠"]
    readonly property int percent: Brightness.percent

    implicitWidth: t.implicitWidth + 16
    implicitHeight: 32


    Txt {
        id: t
        anchors.centerIn: parent
        textFormat: Text.StyledText
        text: root.icons[Math.min(Math.floor(root.percent / 100 * 3), 2)] + " " + root.percent + "<small>%</small>"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/hyprsunset-toggle.sh")])
    }
}
