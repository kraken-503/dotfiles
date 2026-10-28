import QtQuick
import "../core"

Item {
    id: root
    property string icon
    property bool active: false
    property color tint: "transparent"     // optional color override (alpha 0 = use default)
    property real idleOpacity: 1

    signal clicked()

    implicitWidth: t.implicitWidth + 16
    implicitHeight: 32

    Txt {
        id: t
        anchors.centerIn: parent
        text: root.icon
        color: root.active ? Theme.mauve
             : root.tint.a > 0 ? root.tint
             : (area.containsMouse ? Theme.text : Theme.subtext)
        opacity: root.active || area.containsMouse ? 1 : root.idleOpacity
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
