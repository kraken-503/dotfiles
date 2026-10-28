import QtQuick
import QtQuick.Layouts
import "../core"

Rectangle {
    id: root
    property bool active: false
    property bool expandable: false
    property bool expanded: false
    property string icon
    property string title
    property string subtitle
    signal toggled()
    signal expandRequested()

    Layout.fillWidth: true
    implicitHeight: 58
    radius: 16
    color: active ? Qt.alpha(Theme.mauve, 0.18) : (body.containsMouse ? Theme.surface0 : Theme.mantle)
    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea { id: body; anchors.fill: parent; hoverEnabled: true; onClicked: root.toggled() }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            radius: 17
            color: root.active ? Theme.mauve : Theme.surface0
            Behavior on color { ColorAnimation { duration: 150 } }
            Txt {
                anchors.centerIn: parent
                text: root.icon
                color: root.active ? Theme.base : Theme.text
                font.pixelSize: 15
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Txt { Layout.fillWidth: true; text: root.title; elide: Text.ElideRight; font.pixelSize: 12 }
            Txt { Layout.fillWidth: true; text: root.subtitle; elide: Text.ElideRight; color: Theme.subtext; font.pixelSize: 11 }
        }

        Item {
            visible: root.expandable
            implicitWidth: 22
            implicitHeight: 34
            Txt {
                anchors.centerIn: parent
                text: "\uf105"
                color: Theme.subtext
                rotation: root.expanded ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: 150 } }
            }
            MouseArea { anchors.fill: parent; onClicked: root.expandRequested() }
        }
    }
}
