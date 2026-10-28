import QtQuick
import Quickshell.Io
import "../core"

Item {
    id: root

    property string script
    property int interval: 2000
    property string prefix: ""
    property color baseColor: Theme.text
    property var classColors: ({})          // { className: color }
    property string blinkClass: ""
    property bool hideWhenEmpty: true
    property int pixelSize: Theme.fontSize
    property int hPad: 6

    property string label: ""
    property string classes: ""
    readonly property var classList: classes.split(" ")

    signal clicked()
    function refresh() { if (!proc.running) proc.running = true }

    visible: !hideWhenEmpty || label !== ""
    implicitWidth: t.implicitWidth + hPad * 2
    implicitHeight: 32

    Txt {
        id: t
        anchors.centerIn: parent
        text: root.prefix + root.label
        font.pixelSize: root.pixelSize
        color: {
            for (const k in root.classColors)
                if (root.classList.includes(k)) return root.classColors[k];
            return root.baseColor;
        }
        Behavior on color { ColorAnimation { duration: 300 } }

        SequentialAnimation on opacity {
            running: root.blinkClass !== "" && root.classList.includes(root.blinkClass)
            loops: Animation.Infinite
            NumberAnimation { to: 0.4; duration: 500 }
            NumberAnimation { to: 1.0; duration: 500 }
            onRunningChanged: if (!running) t.opacity = 1
        }
    }

    MouseArea { anchors.fill: parent; onClicked: root.clicked() }

    Process {
        id: proc
        command: ["bash", "-c", root.script]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                try {
                    const j = JSON.parse(lines[lines.length - 1]);
                    root.label = j.text ?? "";
                    root.classes = Array.isArray(j.class) ? j.class.join(" ") : (j.class ?? "");
                } catch (e) {
                    root.label = "";
                    root.classes = "";
                }
            }
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
