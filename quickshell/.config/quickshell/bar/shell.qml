//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import "bar"
import "core"
import "panels"

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    ControlCenter {}
    WallpaperPicker {}
    ThemePicker {}
    MusicPlayer {}
    Launcher {}
    Osd {}
    Notifications { id: notifs }

    // qs -c bar ipc call bar toggleControlCenter
    // qs -c bar ipc call bar toggleWallpapers
    // qs -c bar ipc call bar toggleTheme
    // qs -c bar ipc call bar toggleMusic
    // qs -c bar ipc call bar launcher drun|run|filebrowser|window
    // qs -c bar ipc call bar dismissNotifications
    // qs -c bar ipc call bar exportTheme
    IpcHandler {
        target: "bar"
        function toggleControlCenter(): void { UiState.toggleCc(); }
        function toggleWallpapers(): void { UiState.toggleWp(); }
        function toggleTheme(): void { UiState.toggleTheme(); }
        function toggleMusic(): void { UiState.toggleMusic(); }
        function launcher(mode: string): void { UiState.toggleLauncher(mode); }
        function toggleLauncher(): void { UiState.toggleLauncher("drun"); }
        function dismissNotifications(): void { notifs.dismissAll(); }
        function exportTheme(): void { ThemeExport.exportAll(); }
    }
}
