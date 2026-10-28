pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // ── colors follow the active theme (palettes are in Themes.qml) ──
    property color base: Themes.current.base
    Behavior on base { ColorAnimation { duration: 250 } }
    property color mantle: Themes.current.mantle
    Behavior on mantle { ColorAnimation { duration: 250 } }
    property color bg: Themes.current.bg
    Behavior on bg { ColorAnimation { duration: 250 } }
    property color surface0: Themes.current.surface0
    Behavior on surface0 { ColorAnimation { duration: 250 } }
    property color selected: Themes.current.selected
    Behavior on selected { ColorAnimation { duration: 250 } }
    property color text: Themes.current.text
    Behavior on text { ColorAnimation { duration: 250 } }
    property color subtext: Themes.current.subtext
    Behavior on subtext { ColorAnimation { duration: 250 } }
    property color selectedText: Themes.current.selectedText
    Behavior on selectedText { ColorAnimation { duration: 250 } }
    property color mauve: Themes.current.accent
    Behavior on mauve { ColorAnimation { duration: 250 } }
    property color blue: Themes.current.blue
    Behavior on blue { ColorAnimation { duration: 250 } }
    property color red: Themes.current.red
    Behavior on red { ColorAnimation { duration: 250 } }
    property color green: Themes.current.green
    Behavior on green { ColorAnimation { duration: 250 } }
    property color teal: Themes.current.teal
    Behavior on teal { ColorAnimation { duration: 250 } }
    property color peach: Themes.current.peach
    Behavior on peach { ColorAnimation { duration: 250 } }
    property color yellow: Themes.current.yellow
    Behavior on yellow { ColorAnimation { duration: 250 } }
    property color calTitle: Themes.current.calTitle
    Behavior on calTitle { ColorAnimation { duration: 250 } }
    property color calWeekday: Themes.current.calWeekday
    Behavior on calWeekday { ColorAnimation { duration: 250 } }
    property color calWeek: Themes.current.calWeek
    Behavior on calWeek { ColorAnimation { duration: 250 } }
    property color calDay: Themes.current.calDay
    Behavior on calDay { ColorAnimation { duration: 250 } }
    property color calToday: Themes.current.calToday
    Behavior on calToday { ColorAnimation { duration: 250 } }
    readonly property color accent: mauve


    readonly property string font: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 13
}
