import QtQuick
import QtQuick.Layouts
import "../core"

Rectangle {
    id: root
    property string label
    property string trailing
    property bool active: false
    property int indent: 0
    property color labelColor: active ? Theme.mauve : Theme.text
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 32
    radius: 10
    color: active ? Qt.alpha(Theme.mauve, 0.15) : (area.containsMouse ? Theme.surface0 : "transparent")

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10 + root.indent
        anchors.rightMargin: 10
        Txt { Layout.fillWidth: true; text: root.label; elide: Text.ElideRight; font.pixelSize: 12; color: root.labelColor }
        Txt { text: root.trailing; font.pixelSize: 11; color: Theme.subtext }
    }

    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
