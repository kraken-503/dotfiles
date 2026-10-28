pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function fill(p) {                      // fill the calendar roles for themes that don't set them
        p.calTitle   = p.calTitle   || p.text;
        p.calWeekday = p.calWeekday || p.yellow;
        p.calWeek    = p.calWeek    || p.teal;
        p.calDay     = p.calDay     || p.subtext;
        p.calToday   = p.calToday   || p.red;
        return p;
    }

    function dots(p) { return [p.accent, p.blue, p.green, p.yellow, p.peach, p.red]; }

    readonly property var names: ["Catppuccin", "Tokyo Night", "Nord", "Gruvbox", "Dracula", "Rosé Pine", "Everforest"]

    readonly property var palettes: ({
        "Catppuccin": fill({
            base: "#11111b", mantle: "#181825", bg: "#1e1e2e", surface0: "#313244", selected: "#3B4252",
            text: "#cdd6f4", subtext: "#a6adc8", selectedText: "#F8F9FA",
            accent: "#cba6f7", blue: "#89b4fa", red: "#f38ba8", green: "#a6e3a1", teal: "#4D7C80",
            peach: "#fab387", yellow: "#f9e2af",
            calTitle: "#ffead3", calWeekday: "#ffcc66", calWeek: "#99ffdd", calDay: "#ecc6d9", calToday: "#ff6699"
        }),
        "Tokyo Night": fill({
            base: "#16161e", mantle: "#1a1b26", bg: "#1f2335", surface0: "#292e42", selected: "#3b4261",
            text: "#c0caf5", subtext: "#a9b1d6", selectedText: "#ffffff",
            accent: "#bb9af7", blue: "#7aa2f7", red: "#f7768e", green: "#9ece6a", teal: "#73daca",
            peach: "#ff9e64", yellow: "#e0af68"
        }),
        "Nord": fill({
            base: "#242933", mantle: "#292e39", bg: "#2e3440", surface0: "#3b4252", selected: "#434c5e",
            text: "#d8dee9", subtext: "#aeb7c7", selectedText: "#eceff4",
            accent: "#88c0d0", blue: "#81a1c1", red: "#bf616a", green: "#a3be8c", teal: "#8fbcbb",
            peach: "#d08770", yellow: "#ebcb8b"
        }),
        "Gruvbox": fill({
            base: "#1d2021", mantle: "#282828", bg: "#32302f", surface0: "#3c3836", selected: "#504945",
            text: "#ebdbb2", subtext: "#a89984", selectedText: "#fbf1c7",
            accent: "#d3869b", blue: "#83a598", red: "#fb4934", green: "#b8bb26", teal: "#8ec07c",
            peach: "#fe8019", yellow: "#fabd2f"
        }),
        "Dracula": fill({
            base: "#191a21", mantle: "#21222c", bg: "#282a36", surface0: "#343746", selected: "#44475a",
            text: "#f8f8f2", subtext: "#b6b8cc", selectedText: "#ffffff",
            accent: "#bd93f9", blue: "#8be9fd", red: "#ff5555", green: "#50fa7b", teal: "#6272a4",
            peach: "#ffb86c", yellow: "#f1fa8c"
        }),
        "Rosé Pine": fill({
            base: "#16141f", mantle: "#191724", bg: "#1f1d2e", surface0: "#26233a", selected: "#403d52",
            text: "#e0def4", subtext: "#908caa", selectedText: "#faf4ed",
            accent: "#c4a7e7", blue: "#3e8fb0", red: "#eb6f92", green: "#9ccfd8", teal: "#31748f",
            peach: "#ebbcba", yellow: "#f6c177"
        }),
        "Everforest": fill({
            base: "#232a2e", mantle: "#2d353b", bg: "#343f44", surface0: "#3d484d", selected: "#475258",
            text: "#d3c6aa", subtext: "#9da9a0", selectedText: "#f2efdf",
            accent: "#d699b6", blue: "#7fbbb3", red: "#e67e80", green: "#a7c080", teal: "#83c092",
            peach: "#e69875", yellow: "#dbbc7f"
        })
    })

    property string name: "Catppuccin"
    readonly property var current: palettes[name] || palettes["Catppuccin"]

    function apply(n) {
        if (!palettes[n]) return;
        name = n;
        saver.command = ["bash", "-c",
            'mkdir -p ~/.cache/quickshell-bar && printf "%s" "$1" > ~/.cache/quickshell-bar/theme', "save", n];
        saver.running = true;
    }

    Process { id: saver }

    FileView {
        id: saved
        path: Quickshell.env("HOME") + "/.cache/quickshell-bar/theme"
        blockLoading: true
        printErrors: false
    }
    Component.onCompleted: {
        const t = (saved.text() || "").trim();
        if (t !== "" && palettes[t]) name = t;
    }
}
