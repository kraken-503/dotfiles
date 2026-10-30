import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../components"
import "../core"

// Minimal vertical battery: green / yellow / red fill, a bolt while charging, percentage next to it.
// Click toggles the percentage between "62%" and the time left (or time to full).
Item {
    id: root

    // ── EDIT HERE ───────────────────────────────────────────────
    readonly property bool showPercent: true
    readonly property real lowAt: 20          // red at or below this percentage
    readonly property real midAt: 50          // yellow at or below this percentage, green above
    readonly property real criticalAt: 10     // fill blinks at or below this (not while charging)
    // ────────────────────────────────────────────────────────────

    readonly property var dev: UPower.displayDevice
    readonly property int pct: Math.round(dev.percentage * 100)
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
    readonly property bool plugged: dev.state === UPowerDeviceState.FullyCharged
                                 || dev.state === UPowerDeviceState.PendingCharge
    property bool alt: false        // click toggles the time-remaining text

    function timeText() {
        const s = charging ? dev.timeToFull : dev.timeToEmpty;
        if (!s || s <= 0) return "--";
        return Math.floor(s / 3600) + " h " + Math.floor(s % 3600 / 60) + " min";
    }

    visible: dev.isPresent
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 32

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        BatteryIcon {
            Layout.alignment: Qt.AlignVCenter
            pct: root.pct
            charging: root.charging || root.plugged
            lowAt: root.lowAt
            midAt: root.midAt
            criticalAt: root.criticalAt
            colorLow: Theme.red
            colorMid: Theme.yellow !== undefined ? Theme.yellow : "#f9e2af"
            colorHigh: Theme.green
            track: Theme.surface0
        }

        Txt {
            Layout.alignment: Qt.AlignVCenter
            visible: root.showPercent || root.alt
            text: root.alt ? root.timeText() : root.pct + "%"
            color: (root.pct <= root.lowAt && !root.charging && !root.plugged) ? Theme.red : Theme.text
        }
    }

    MouseArea { anchors.fill: parent; onClicked: root.alt = !root.alt }
}
