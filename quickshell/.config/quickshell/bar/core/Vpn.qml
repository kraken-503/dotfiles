pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var profiles: []                  // [{ name, uuid, active }]
    property string message: ""
    property string kind: ""

    readonly property var activeProfiles: profiles.filter(p => p.active)
    readonly property string activeName: activeProfiles.length > 0 ? activeProfiles[0].name : ""

    function refresh() { list.running = true; }

    function parse(text) {
        const out = [];
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            if (!lines[i]) continue;
            const f = Wifi.splitTerse(lines[i]);          // NAME, UUID, TYPE, ACTIVE
            if (f[2] !== "vpn" && f[2] !== "wireguard") continue;
            out.push({ name: f[0], uuid: f[1], active: f[3] === "yes" });
        }
        out.sort((a, b) => a.name.localeCompare(b.name));  // stable order, active row doesn't jump
        profiles = out;
    }

    function connectTo(p) {
        if (act.running) return;
        kind = "connect";
        message = "Connecting to " + p.name + "…";
        const others = activeProfiles.filter(a => a.uuid !== p.uuid).map(a => a.uuid).join(" ");
        act.command = ["bash", "-c",
            'for u in $2; do nmcli connection down uuid "$u" >/dev/null 2>&1; done; nmcli -w 20 connection up uuid "$1"',
            "vpn", p.uuid, others];
        act.running = true;
    }

    function disconnect(p) {
        if (act.running) return;
        kind = "disconnect";
        message = "Disconnecting…";
        act.command = ["nmcli", "connection", "down", "uuid", p.uuid];
        act.running = true;
    }

    function disconnectAll() {
        if (act.running) return;
        kind = "disconnect";
        message = "Disconnecting…";
        act.command = ["bash", "-c", 'for u in $1; do nmcli connection down uuid "$u"; done',
            "vpn", activeProfiles.map(a => a.uuid).join(" ")];
        act.running = true;
    }

    Process {
        id: list
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,ACTIVE", "connection", "show"]
        stdout: StdioCollector { onStreamFinished: root.parse(this.text) }
    }

    Process {
        id: act
        onExited: code => {
            root.message = code === 0 ? "" : (root.kind === "connect" ? "Couldn't connect (credentials?)" : "Couldn't disconnect");
            root.refresh();
            later.restart();
        }
    }
    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: later; interval: 1500; onTriggered: root.refresh() }
}
