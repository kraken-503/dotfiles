import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../components"
import "../core"

Item {
    id: root
    property bool alt: false          // click toggles format-alt
    property int monthOffset: 0       // scroll over the clock to shift the calendar
    readonly property date view: new Date(clock.date.getFullYear(), clock.date.getMonth() + monthOffset, 1)

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 32

    SystemClock { id: clock; precision: SystemClock.Minutes }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        ClockIcon {
            visible: !root.alt
            time: clock.date
            color: Theme.teal
            size: 15
            Layout.alignment: Qt.AlignVCenter
        }
        Txt {
            color: Theme.teal
            text: root.alt ? Qt.formatDateTime(clock.date, "dddd, MMMM dd, yyyy")
                           : Qt.formatDateTime(clock.date, "hh:mm AP")
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => {
            if (m.button === Qt.RightButton) root.alt = !root.alt;
            else UiState.toggleMusic();
        }
        onWheel: w => root.monthOffset += (w.angleDelta.y > 0 ? -1 : 1)
    }

    PopupWindow {
        anchor.item: root
        anchor.rect.x: (root.width - width) / 2
        anchor.rect.y: root.height + 6
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        color: "transparent"
        visible: area.containsMouse && !UiState.musicOpen
        onVisibleChanged: if (!visible) root.monthOffset = 0

        Rectangle {
            id: card
            anchors.fill: parent
            color: Theme.base
            radius: 12
            implicitWidth: col.implicitWidth + 24
            implicitHeight: col.implicitHeight + 24

            ColumnLayout {
                id: col
                anchors.centerIn: parent
                spacing: 6

                Txt {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.calTitle
                    font.pixelSize: 15
                    text: Qt.formatDate(root.view, "MMMM yyyy")
                }

                GridLayout {
                    columns: 2
                    rowSpacing: 2
                    columnSpacing: 6

                    Item { implicitWidth: 1; implicitHeight: 1 }

                    DayOfWeekRow {
                        locale: grid.locale
                        delegate: Txt {
                            required property var model
                            color: Theme.calWeekday
                            width: 30
                            horizontalAlignment: Text.AlignHCenter
                            text: model.shortName
                        }
                    }

                    WeekNumberColumn {
                        month: grid.month
                        year: grid.year
                        locale: grid.locale
                        delegate: Txt {
                            required property var model
                            color: Theme.calWeek
                            height: 22
                            text: "W" + model.weekNumber
                        }
                    }

                    MonthGrid {
                        id: grid
                        month: root.view.getMonth()
                        year: root.view.getFullYear()
                        locale: Qt.locale()
                        delegate: Txt {
                            required property var model
                            width: 30
                            height: 22
                            horizontalAlignment: Text.AlignHCenter
                            opacity: model.month === grid.month ? 1 : 0
                            color: model.today ? Theme.calToday : Theme.calDay
                            font.underline: model.today
                            text: model.day
                        }
                    }
                }
            }
        }
    }
}
