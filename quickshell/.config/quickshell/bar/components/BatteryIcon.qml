import QtQuick
import QtQuick.Shapes

// Minimal vertical battery: a slim pill that fills from the bottom (green / yellow / red), no outline.
// A small bolt sits next to it while charging. Pure QtQuick: colors are properties.
Item {
    id: root

    property real pct: 100                  // 0..100
    property bool charging: false
    property bool blinkWhenCritical: true

    // thresholds: red at or below lowAt, yellow at or below midAt, green above
    property real lowAt: 20
    property real midAt: 50
    property real criticalAt: 10            // blink below this (not while charging)

    property color colorLow:  "#f38ba8"
    property color colorMid:  "#f9e2af"
    property color colorHigh: "#a6e3a1"
    property color track:     "#313244"
    readonly property color fillColor: charging ? colorHigh
                                      : pct <= lowAt ? colorLow
                                      : pct <= midAt ? colorMid
                                      : colorHigh
    property color boltColor: fillColor

    property string boltPlacement: "beside" // "beside" | "none"
    property real bodyWidth: 9
    property real bodyHeight: 15
    readonly property real nubWidth: 0
    readonly property real nubHeight: 0
    readonly property real boltWidth: 7
    property real boltSlot: (boltPlacement === "beside" && charging) ? boltWidth + 4 : 0

    implicitWidth: boltSlot + bodyWidth
    implicitHeight: bodyHeight + nubHeight
    Behavior on boltSlot { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // bolt
    Shape {
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: root.boltWidth
        height: 11
        opacity: root.boltSlot > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        preferredRendererType: Shape.GeometryRenderer
        ShapePath {
            fillColor: root.boltColor
            strokeColor: "transparent"
            PathPolyline {
                path: [Qt.point(4.6, 0), Qt.point(0, 6.2), Qt.point(3.0, 6.2),
                       Qt.point(2.2, 11), Qt.point(7, 4.4), Qt.point(4.0, 4.4), Qt.point(4.6, 0)]
            }
        }
    }

    Item {
        x: root.boltSlot
        width: root.bodyWidth
        height: parent.height

        // terminal
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: root.nubWidth
            height: root.nubHeight + 1
            radius: 1
            color: root.track
        }

        // body
        Rectangle {
            id: body
            y: root.nubHeight
            width: root.bodyWidth
            height: root.bodyHeight
            radius: 3
            color: root.track

            // fill, rising from the bottom
            Rectangle {
                id: fill
                anchors.bottom: parent.bottom
                width: parent.width
                height: root.pct > 0 ? Math.max(3, parent.height * Math.min(100, root.pct) / 100) : 0
                radius: 3
                color: root.fillColor
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 250 } }

                SequentialAnimation on opacity {
                    running: root.blinkWhenCritical && !root.charging && root.pct <= root.criticalAt
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 600 }
                    NumberAnimation { to: 1.0; duration: 600 }
                    onRunningChanged: if (!running) fill.opacity = 1
                }
            }
        }
    }
}
