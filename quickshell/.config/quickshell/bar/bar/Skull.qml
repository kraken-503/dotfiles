import QtQuick
import Quickshell.Io
import Quickshell
import "../components"

Pill {
    radius: 14
    hPad: 12

    ScriptLabel {
        id: sl
        script: "bash '" + Quickshell.shellPath("scripts/gamemode-toggle.sh") + "'" + " status"
        interval: 5000
        prefix: ""
        hPad: 0
        hideWhenEmpty: false
        onClicked: toggle.running = true
    }

    Process {
        id: toggle
        command: ["bash", Quickshell.shellPath("scripts/gamemode-toggle.sh"), "toggle"]
        onRunningChanged: if (!running) sl.refresh()
    }
}
