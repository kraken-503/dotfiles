import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../components"
import "../core"

Pill {
    id: root
    radius: 18
    hPad: 8

    readonly property var icons: ["󰬺", "󰬻", "󰬼", "󰬽", "󰬾", "󰬿", "󰭀", "󰭁", "󰭂"]

    readonly property var ids: {
        const s = [1, 2, 3];
        const v = Hyprland.workspaces.values;
        for (let i = 0; i < v.length; i++)
            if (v[i].id > 0 && s.indexOf(v[i].id) < 0) s.push(v[i].id);
        return s.sort((a, b) => a - b);
    }

    function ws(id) {
        const v = Hyprland.workspaces.values;
        for (let i = 0; i < v.length; i++)
            if (v[i].id === id) return v[i];
        return null;
    }

    WheelHandler {
        onWheel: e => Hyprland.dispatch(e.angleDelta.y > 0 ? "workspace +1" : "workspace -1")
    }

    Repeater {
        model: root.ids

        delegate: Rectangle {
            id: btn
            required property int modelData
            readonly property bool active: Hyprland.focusedWorkspace?.id === modelData
            readonly property bool urgent: root.ws(modelData)?.urgent ?? false

            implicitWidth: lbl.implicitWidth + (active ? 36 : 16)
            implicitHeight: 26
            radius: active ? 26 : 12
            color: active ? Qt.alpha(Theme.mauve, 0.15)
                          : (area.containsMouse ? Theme.surface0 : Theme.base)

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.BezierCurve
                    easing.bezierCurve: [0.05, 0.9, 0.1, 1.05, 1, 1]
                }
            }
            Behavior on color { ColorAnimation { duration: 300 } }

            Txt {
                id: lbl
                anchors.centerIn: parent
                font.pixelSize: 19
                text: btn.modelData >= 1 && btn.modelData <= 9 ? root.icons[btn.modelData - 1] : "\uf111"
                color: btn.urgent ? Theme.red
                     : btn.active ? Theme.mauve
                     : area.containsMouse ? Theme.text
                     : Theme.subtext
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Hyprland.dispatch("workspace " + btn.modelData)
            }
        }
    }
}
