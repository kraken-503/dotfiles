pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    property bool ccOpen: false
    property bool wpOpen: false
    property bool musicOpen: false
    property bool themeOpen: false
    property bool launcherOpen: false
    property string launcherMode: "drun"
    property string wallpaper: ""
    property real centerWidth: 300      // reported by the bar's center pill
    property double ccClosedAt: 0
    property double wpClosedAt: 0
    property double musicClosedAt: 0
    property double themeClosedAt: 0

    readonly property var focusedScreen: {
        const name = Hyprland.focusedMonitor?.name;
        const s = Quickshell.screens;
        for (let i = 0; i < s.length; i++)
            if (s[i].name === name) return s[i];
        return s[0];
    }

    function closeCc() { ccOpen = false; ccClosedAt = Date.now(); }
    function closeWp() { wpOpen = false; wpClosedAt = Date.now(); }
    function closeMusic() { musicOpen = false; musicClosedAt = Date.now(); }
    function closeTheme() { themeOpen = false; themeClosedAt = Date.now(); }
    function closeLauncher() { launcherOpen = false; }

    function openLauncher(mode) {
        closeCc(); closeWp(); closeMusic(); closeTheme();
        launcherMode = mode || "drun";
        launcherOpen = true;
    }
    function toggleLauncher(mode) {
        const m = mode || "drun";
        if (launcherOpen && launcherMode === m) closeLauncher();
        else openLauncher(m);
    }

    function toggleCc() {
        if (ccOpen) { closeCc(); return; }
        if (Date.now() - ccClosedAt < 300) return;
        closeWp(); closeMusic(); closeTheme();
        ccOpen = true;
    }
    function toggleWp() {
        if (wpOpen) { closeWp(); return; }
        if (Date.now() - wpClosedAt < 300) return;
        closeCc(); closeMusic(); closeTheme();
        wpOpen = true;
    }
    function toggleMusic() {
        if (musicOpen) { closeMusic(); return; }
        if (Date.now() - musicClosedAt < 300) return;
        closeCc(); closeWp(); closeTheme();
        musicOpen = true;
    }
    function toggleTheme() {
        if (themeOpen) { closeTheme(); return; }
        if (Date.now() - themeClosedAt < 300) return;
        closeCc(); closeWp(); closeMusic();
        themeOpen = true;
    }
}
