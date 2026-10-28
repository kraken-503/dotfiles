pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root
    property string lastDbus: ""

    readonly property var player: {
        const p = Mpris.players.values;
        if (!p || p.length === 0) return null;
        for (let i = 0; i < p.length; i++)
            if (p[i].isPlaying) return p[i];
        for (let i = 0; i < p.length; i++)
            if (p[i].dbusName === lastDbus) return p[i];
        return p[0];
    }

    readonly property bool has: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle ?? ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string art: player?.trackArtUrl ?? ""
    readonly property string identity: player?.identity ?? ""
    readonly property real position: player?.position ?? 0     // seconds
    readonly property real length: player?.length ?? 0         // seconds
    readonly property real fraction: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    function fmt(s) {
        const t = Math.max(0, Math.floor(s || 0));
        return Math.floor(t / 60) + ":" + (t % 60 < 10 ? "0" : "") + (t % 60);
    }
    function toggle() { if (player?.canTogglePlaying) player.togglePlaying(); }
    function next() { if (player?.canGoNext) player.next(); }
    function previous() { if (player?.canGoPrevious) player.previous(); }
    function seek(frac) {
        if (player?.canSeek && length > 0) player.position = Math.max(0, Math.min(1, frac)) * length;
    }

    Instantiator {
        model: Mpris.players
        delegate: QtObject {
            required property var modelData
            readonly property bool playing: modelData.isPlaying
            onPlayingChanged: if (playing) root.lastDbus = modelData.dbusName
            Component.onCompleted: if (playing) root.lastDbus = modelData.dbusName
        }
    }

    Timer {
        running: root.playing && UiState.musicOpen
        interval: 500
        repeat: true
        onTriggered: root.player?.positionChanged()
    }
}
