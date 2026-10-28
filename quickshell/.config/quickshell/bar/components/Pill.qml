import QtQuick
import QtQuick.Layouts
import "../core"

Rectangle {
    id: root

    default property alias content: row.data
    property int hPad: 8
    property alias spacing: row.spacing

    color: Theme.base
    implicitHeight: 32
    implicitWidth: row.implicitWidth + hPad * 2

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4
    }
}
