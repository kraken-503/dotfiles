import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Item {
    id: root
    property bool active: false
    property int barCount: 10          // keep in sync with `bars` in cava.conf
    property int barWidth: 4
    property int gap: 3
    property int maxHeight: 30
    property int minHeight: 4
    property color color: Theme.mauve
    property var levels: []            // 0..100 per bar

    implicitWidth: barCount * barWidth + (barCount - 1) * gap
    implicitHeight: maxHeight

    Process {
        running: root.active
        command: ["cava", "-p", Quickshell.shellPath("assets/cava.conf")]
        stdout: SplitParser {
            onRead: data => root.levels = data.split(";").filter(s => s !== "").map(Number)
        }
        onRunningChanged: if (!running) root.levels = []
    }

    Row {
        anchors.fill: parent
        spacing: root.gap

        Repeater {
            model: root.barCount
            delegate: Rectangle {
                required property int index
                width: root.barWidth
                height: Math.max(root.minHeight, (root.levels[index] ?? 0) / 100 * root.maxHeight)
                y: (root.maxHeight - height) / 2
                radius: root.barWidth / 2
                color: root.color
                Behavior on height { NumberAnimation { duration: 80 } }
            }
        }
    }
}
