import QtQuick
import Quickshell.Services.UPower
import "../components"
import "../core"

Item {
    id: root
    readonly property var dev: UPower.displayDevice
    readonly property int pct: Math.round(dev.percentage * 100)
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
    readonly property bool plugged: dev.state === UPowerDeviceState.FullyCharged
                                 || dev.state === UPowerDeviceState.PendingCharge
    readonly property var icons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property string icon: icons[Math.min(Math.floor(pct / 10), 9)]
    property bool alt: false        // click toggles format-alt (time remaining)

    function timeText() {
        const s = charging ? dev.timeToFull : dev.timeToEmpty;
        if (!s || s <= 0) return "--";
        return Math.floor(s / 3600) + " h " + Math.floor(s % 3600 / 60) + " min";
    }

    visible: dev.isPresent
    implicitWidth: t.implicitWidth + 16
    implicitHeight: 32

    Txt {
        id: t
        anchors.centerIn: parent
        color: (root.pct <= 25 && !root.charging && !root.plugged) ? Theme.red : Theme.text
        text: root.alt ? root.timeText() + " " + root.icon
            : root.charging ? "󰂄 " + root.pct + "%"
            : root.plugged ? "󰚥 " + root.pct + "%"
            : root.icon + " " + root.pct + "%"
    }

    MouseArea { anchors.fill: parent; onClicked: root.alt = !root.alt }
}
