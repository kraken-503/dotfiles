import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../core"

Item {
    id: root

    readonly property bool showPercent: true
    readonly property bool spinOnHover: true     // the rays turn only while the pointer is over the sun
    readonly property int spinDuration: 3000     // ms per full turn
    readonly property real iconSize: 20

    readonly property int percent: Brightness.percent

    readonly property color dimColor: Qt.tint(Theme.subtext, Qt.alpha(Theme.base, 0.55))
    readonly property color brightColor: {
        const y = Theme.yellow !== undefined ? Theme.yellow : "#f9e2af";
        return Qt.hsla(y.hslHue, Math.max(0.85, y.hslSaturation), 0.62, 1);
    }

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 32

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Item {                                   // slightly larger than the sun so it is easy to hover
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: sun.implicitWidth + 8
            implicitHeight: 32
            HoverHandler { id: sunHover }

            SunIcon {
                id: sun
                anchors.centerIn: parent
                size: root.iconSize
                level: root.percent / 100
                dimColor: root.dimColor
                brightColor: root.brightColor
                spinning: root.spinOnHover && sunHover.hovered
                spinDuration: root.spinDuration
            }
        }

        Txt {
            Layout.alignment: Qt.AlignVCenter
            visible: root.showPercent
            textFormat: Text.StyledText
            text: root.percent + "<small>%</small>"
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/hyprsunset-toggle.sh")])
    }
}
