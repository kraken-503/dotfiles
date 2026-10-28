import QtQuick
import "../core"

Item {
    id: root
    property real value: 0              // 0..1, driven from outside
    property string icon: ""
    property real local: 0
    readonly property real shown: area.pressed ? local : value
    signal moved(real v)

    implicitHeight: 40
    implicitWidth: 300

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface0

        Rectangle {
            height: parent.height
            width: Math.max(parent.height, parent.width * root.shown)
            radius: height / 2
            color: Theme.mauve
            Behavior on width { enabled: !area.pressed; NumberAnimation { duration: 120 } }
        }
        Txt {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: Theme.base
            font.pixelSize: 16
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        function set(x) {
            root.local = Math.max(0, Math.min(1, x / width));
            root.moved(root.local);
        }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x); }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.02 : -0.02))))
    }
}
