import QtQuick
import "../core"

// Mini analog clock 
Item {
    id: root
    property date time: new Date()
    property color color: Theme.teal
    property real size: 15
    property real stroke: 1.5

    implicitWidth: size
    implicitHeight: size

    readonly property real hourAngle: (time.getHours() % 12) * 30 + time.getMinutes() * 0.5
    readonly property real minuteAngle: time.getMinutes() * 6 + time.getSeconds() * 0.1

    // face
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: root.stroke
        border.color: root.color
    }

    // hour hand
    Rectangle {
        width: root.stroke
        height: root.size * 0.26
        radius: width / 2
        color: root.color
        x: (root.width - width) / 2
        y: root.height / 2 - height
        transformOrigin: Item.Bottom
        rotation: root.hourAngle
        Behavior on rotation { RotationAnimation { duration: 300; direction: RotationAnimation.Shortest } }
    }

    // minute hand
    Rectangle {
        width: root.stroke
        height: root.size * 0.38
        radius: width / 2
        color: root.color
        x: (root.width - width) / 2
        y: root.height / 2 - height
        transformOrigin: Item.Bottom
        rotation: root.minuteAngle
        Behavior on rotation { RotationAnimation { duration: 300; direction: RotationAnimation.Shortest } }
    }

    // center pin
    Rectangle {
        width: root.stroke + 1
        height: width
        radius: width / 2
        color: root.color
        anchors.centerIn: parent
    }
}
