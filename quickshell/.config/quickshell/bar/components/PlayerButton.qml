import QtQuick
import "../core"

Item {
    id: root
    property string icon
    property int size: 32
    property bool filled: false
    signal clicked()

    implicitWidth: size
    implicitHeight: size
    opacity: enabled ? 1 : 0.35
    scale: area.pressed ? 0.88 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.filled ? Theme.mauve : (area.containsMouse ? Theme.surface0 : "transparent")
    }
    Txt {
        anchors.centerIn: parent
        text: root.icon
        color: root.filled ? Theme.base : Theme.text
        font.pixelSize: root.filled ? 16 : 14
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; enabled: root.enabled; onClicked: root.clicked() }
}
