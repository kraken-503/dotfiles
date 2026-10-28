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
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

            function openMenu() {
                const p = ma.mapToItem(null, 0, ma.height);
                modelData.display(QsWindow.window, p.x, p.y);
            }

            onClicked: m => {
                if (m.button === Qt.MiddleButton) modelData.secondaryActivate();
                else if (m.button === Qt.RightButton || modelData.onlyMenu) { if (modelData.hasMenu) openMenu(); }
                else modelData.activate();
            }

            IconImage { anchors.fill: parent; source: ma.modelData.icon }
        }
    }
}
