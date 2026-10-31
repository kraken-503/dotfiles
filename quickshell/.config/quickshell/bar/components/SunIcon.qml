import QtQuick

Item {
    id: root

    property real level: 0.5               // 0..1
    property color dimColor: "#6c7086"
    property color brightColor: "#f9e2af"
    property bool spinning: false          // true while the rays should turn (Backlight sets it on hover)
    property int spinDuration: 3000        // ms per full turn

    property real size: 20
    property int rayCount: 8

    property real shown: level
    Behavior on shown { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    readonly property real t: Math.max(0, Math.min(1, shown))

    readonly property color tone: Qt.rgba(dimColor.r + (brightColor.r - dimColor.r) * t,
                                          dimColor.g + (brightColor.g - dimColor.g) * t,
                                          dimColor.b + (brightColor.b - dimColor.b) * t, 1)

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.centerIn: parent
        width: root.size * (0.62 + 0.38 * root.t)
        height: width
        radius: width / 2
        color: root.tone
        opacity: 0.16 * root.t
    }

    property real angle: 0
    readonly property real step: 360 / rayCount
    onSpinningChanged: {
        if (spinning) {
            settle.stop();
            turn.from = angle % 360;
            turn.to = turn.from + 360;
            turn.start();
        } else {
            turn.stop();
            settle.from = angle;
            settle.to = Math.ceil(angle / step - 0.001) * step;
            settle.duration = Math.max(1, Math.round(450 * (settle.to - settle.from) / step));
            settle.start();
        }
    }
    NumberAnimation { id: turn; target: root; property: "angle"; duration: root.spinDuration; loops: Animation.Infinite }
    NumberAnimation { id: settle; target: root; property: "angle"; easing.type: Easing.OutCubic }

    // rays
    Item {
        id: rays
        anchors.fill: parent
        rotation: root.angle

        Repeater {
            model: root.rayCount
            delegate: Rectangle {
                id: ray
                required property int index
                readonly property real outerR: root.size / 2 - 0.5
                readonly property real len: 2 + 1.6 * root.t
                width: 2
                height: len
                radius: 1
                color: root.tone
                opacity: 0.45 + 0.55 * root.t
                x: root.size / 2 - width / 2
                y: root.size / 2 - outerR
                transform: Rotation {
                    origin.x: 1
                    origin.y: ray.outerR                      // from the ray's top edge down to the icon center
                    angle: ray.index * 360 / root.rayCount
                }
            }
        }
    }

    // core
    Rectangle {
        anchors.centerIn: parent
        width: root.size * (0.30 + 0.08 * root.t)
        height: width
        radius: width / 2
        color: root.tone
    }
}
