pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool enabled: false
    property string ssid: ""
    property var networks: []
    property string message: ""
    property string pendingSsid: ""
    property string lastKind: ""
    property string lastSsid: ""
    property string device: ""

    function splitTerse(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) { cur += line[i + 1]; i++; }
            else if (c === ":") { out.push(cur); cur = ""; }
            else cur += c;
        }
        out.push(cur);
        return out;
    }

    function parseList(text) {
        const best = {};
        let active = "";
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            if (!lines[i]) continue;
            const f = splitTerse(lines[i]);
            const name = f[1];
            if (!name) continue;
            const n = { ssid: name, signal: parseInt(f[2]) || 0, secure: (f[3] || "") !== "", active: f[0] === "*" };
            if (n.active) active = name;
            const b = best[name];
            if (!b || n.active || (!b.active && n.signal > b.signal)) best[name] = n;
        }
        const arr = Object.keys(best).map(k => best[k]);
        arr.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
        networks = arr.slice(0, 7);
        ssid = active;
    }

    function refresh() { radio.running = true; devProc.running = true; }

    function disconnect() {
        if (act.running) return;
        lastKind = "disconnect";
        message = "Disconnecting…";
        act.command = device !== ""
            ? ["nmcli", "device", "disconnect", device]
            : ["nmcli", "connection", "down", "id", ssid];
        act.running = true;
    }

    function setEnabled(on) {
        if (act.running) return;
        lastKind = "radio";
        act.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        act.running = true;
    }

    function connectTo(name, password) {
        if (act.running) return;
        lastKind = "connect";
        lastSsid = name;
        message = "Connecting…";
        act.command = password
            ? ["nmcli", "dev", "wifi", "connect", name, "password", password]
            : ["nmcli", "dev", "wifi", "connect", name];
        act.running = true;
    }

    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: later; interval: 1200; onTriggered: root.refresh() }

    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = this.text.trim() === "enabled";
                if (root.enabled) list.running = true;
                else { root.networks = []; root.ssid = ""; }
            }
        }
    }

    Process {
        id: devProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.split("\n");
                for (let i = 0; i < l.length; i++) {
                    const f = root.splitTerse(l[i]);
                    if (f[1] === "wifi") { root.device = f[0]; break; }
                }
            }
        }
    }

    Process {
        id: list
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"]
        stdout: StdioCollector { onStreamFinished: root.parseList(this.text) }
    }

    Process {
        id: act
        stdout: StdioCollector { id: actOut }
        stderr: StdioCollector { id: actErr }
        onExited: code => {
            if (root.lastKind === "connect") {
                const out = actOut.text + actErr.text;
                if (code === 0) { root.message = ""; root.pendingSsid = ""; }
                else if (out.indexOf("Secrets were required") >= 0 || out.indexOf("assword") >= 0) {
                    root.pendingSsid = root.lastSsid;
                    root.message = "Password needed";
                } else root.message = "Couldn't connect";
            } else if (root.lastKind === "disconnect") {
                root.message = code === 0 ? "" : "Couldn't disconnect";
            }
            root.refresh();
            later.restart();
        }
    }
}
