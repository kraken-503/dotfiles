import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

RowLayout {
    spacing: 12

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: ma
            required property SystemTrayItem modelData

            visible: modelData.id !== "nm-applet"
            Layout.preferredWidth: visible ? 16 : 0
            Layout.preferredHeight: visible ? 16 : 0

            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

            function openMenu() {
                const p = ma.mapToItem(null, 0, ma.height);
                modelData.display(QsWindow.window, p.x, p.y);
            }

            onClicked: m => {
                if (m.button === Qt.MiddleButton) modelData.secondaryActivate();
                else if (m.button === Qt.RightButton || modelData.onlyMenu) {
                    if (modelData.hasMenu) openMenu();
                }
                else modelData.activate();
            }

            IconImage {
                anchors.fill: parent
                source: ma.modelData.icon
            }
        }
    }
}
