pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string device: "amdgpu_bl2"
    readonly property string sysPath: "/sys/class/backlight/" + device
    readonly property int percent: {
        const m = Number(maxFile.text());
        return m > 0 ? Math.round(Number(curFile.text()) / m * 100) : 0;
    }

    property int pending: -1

    function set(p) {
        pending = Math.max(1, Math.min(100, Math.round(p)));
        if (!setter.running) run();
    }
    function run() {
        const v = pending;
        pending = -1;
        setter.command = ["brightnessctl", "-d", device, "set", v + "%"];
        setter.running = true;
    }

    FileView { id: curFile; path: root.sysPath + "/brightness"; blockLoading: true }
    FileView { id: maxFile; path: root.sysPath + "/max_brightness"; blockLoading: true }
    Timer { interval: 200; running: true; repeat: true; onTriggered: curFile.reload() }

    Process {
        id: setter
        onExited: {
            curFile.reload();
            if (root.pending >= 0) root.run();
        }
    }
}
