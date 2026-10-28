pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root
    readonly property string ignored: "Easy Effects Sink"

    readonly property var sink: {
        const d = Pipewire.defaultAudioSink;
        if (d && d.description !== ignored) return d;
        const n = Pipewire.nodes.values;
        for (let i = 0; i < n.length; i++)
            if (n[i].isSink && !n[i].isStream && n[i].description !== ignored) return n[i];
        return d;
    }
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    function setVolume(v) { if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(1, v)); }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted; }
}
