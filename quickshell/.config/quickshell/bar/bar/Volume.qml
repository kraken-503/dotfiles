import QtQuick
import Quickshell
import "../components"
import "../core"

Item {
    id: root
    readonly property bool bluetooth: (Audio.sink?.name ?? "").startsWith("bluez")
    readonly property int pct: Math.round(Audio.volume * 100)
    readonly property string icon: bluetooth ? "\uf025" : (Audio.volume < 0.5 ? "\uf027" : "\uf028")

    implicitWidth: t.implicitWidth + 16
    implicitHeight: 32

    Txt {
        id: t
        anchors.centerIn: parent
        textFormat: Text.StyledText
        text: Audio.muted ? "\uf6a9"
            : root.bluetooth ? root.pct + "<small>%</small> " + root.icon
            : root.icon + " " + root.pct + "<small>%</small>"
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => {
            if (m.button === Qt.RightButton) Quickshell.execDetached(["pavucontrol"]);
            else Audio.toggleMute();
        }
        onWheel: w => Audio.setVolume(Audio.volume + (w.angleDelta.y > 0 ? 0.01 : -0.01))
    }
}
