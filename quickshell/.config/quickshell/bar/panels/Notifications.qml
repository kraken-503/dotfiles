import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../core"

Scope {
    id: root

    readonly property int cardWidth: 360          // width
    readonly property int maxHeight: 300          // height (max per notification)
    readonly property int offsetX: 20             // offset = 20x20, origin top-right
    readonly property int offsetY: 20
    readonly property int limit: 5                // notification_limit
    readonly property int padding: 16             // padding / horizontal_padding
    readonly property int iconPad: 12             // text_icon_padding
    readonly property int radius: 12              // corner_radius
    readonly property int iconRadius: 8           // icon_corner_radius
    readonly property int iconSize: 40
    readonly property real fontPt: 11             // font = JetBrainsMono Nerd Font 11 (family comes from Theme.font)
    readonly property int progressHeight: 6       // progress_bar_height
    readonly property int frameWidth: 0           // frame_width
    readonly property real bgOpacity: 0.9         // transparency = 10
    readonly property int gap: 4
    readonly property int showAgeAfter: 60        // show_age_threshold (seconds)
    readonly property real defaultTimeout: 3     // seconds, for notifications that don't ask for one
    readonly property bool newestFirst: false
    readonly property var styles: ({
        low:      { bg: Theme.bg, fg: Theme.text, frame: Theme.blue },
        normal:   { bg: Theme.bg, fg: Theme.text, frame: Theme.blue },
        critical: { bg: Theme.bg, fg: Theme.text, frame: Theme.peach }
    })
    // ─────────────────────────────────────────────────────────────────────

    property var born: ({})

    function dismissAll() {
        const v = server.trackedNotifications.values;
        const all = [];
        for (let i = 0; i < v.length; i++) all.push(v[i]);
        all.forEach(n => n.dismiss());
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true;
            const b = Object.assign({}, root.born);
            b[n.id] = Date.now();
            root.born = b;
        }
    }

    // critical first, then oldest first (dunst's default ordering)
    readonly property var sorted: {
        const v = server.trackedNotifications.values;
        const arr = [];
        for (let i = 0; i < v.length; i++) arr.push(v[i]);
        arr.sort((a, b) => (b.urgency - a.urgency) || (newestFirst ? b.id - a.id : a.id - b.id));
        return arr;
    }
    readonly property var shownItems: sorted.slice(0, limit)
    readonly property var shownIds: shownItems.map(n => n.id)

    // expiry timers start when a notification becomes visible (extra ones wait in the queue)
    Instantiator {
        model: server.trackedNotifications
        delegate: QtObject {
            id: tr
            required property var modelData
            readonly property bool shown: root.shownIds.indexOf(modelData.id) >= 0
            readonly property real timeout: modelData.expireTimeout > 0 ? modelData.expireTimeout
                : (modelData.urgency === NotificationUrgency.Critical ? 0 : root.defaultTimeout)

            property Timer expiry: Timer {
                interval: tr.timeout * 1000
                running: tr.shown && tr.timeout > 0
                onTriggered: tr.modelData.expire()
            }
        }
    }

    PanelWindow {
        screen: UiState.focusedScreen                // follow = mouse / focus
        visible: root.shownItems.length > 0
        anchors { top: true; right: true }
        margins { top: root.offsetY; right: root.offsetX }
        implicitWidth: root.cardWidth
        implicitHeight: col.implicitHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Normal          // sits below the bar, like dunst
        mask: Region { item: col }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-notifications"

        ColumnLayout {
            id: col
            width: parent.width
            spacing: root.gap

            Repeater {
                model: root.shownItems
                delegate: NotificationCard {
                    n: modelData
                    cfg: root
                    born: root.born[modelData.id] || Date.now()
                }
            }
        }
    }
}
