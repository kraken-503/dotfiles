import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../core"

Rectangle {
    id: card
    property var n: null
    property var cfg: null
    property real born: Date.now()
    property real now: Date.now()

    readonly property bool critical: n.urgency === NotificationUrgency.Critical
    readonly property var st: critical ? cfg.styles.critical
                            : n.urgency === NotificationUrgency.Low ? cfg.styles.low
                            : cfg.styles.normal

    // show_age_threshold
    readonly property real ageSec: (now - born) / 1000
    readonly property string ageText: {
        if (ageSec < cfg.showAgeAfter) return "";
        const m = Math.floor(ageSec / 60);
        if (m < 60) return "(" + m + (m === 1 ? " minute" : " minutes") + " ago)";
        const h = Math.floor(m / 60);
        return "(" + h + (h === 1 ? " hour" : " hours") + " ago)";
    }

    function clean(b) {         // markup = full, minus tags StyledText can't render
        return String(b || "")
            .replace(/<(?!\/?(?:b|i|u|a|br)\b)[^>]*>/gi, "")
            .replace(/\n/g, "<br>");
    }

    // format = "<b>%s</b>\n%b"
    readonly property string markup: {
        const body = clean(n.body);
        return "<b>" + n.summary + (ageText !== "" ? " " + ageText : "") + "</b>" + (body !== "" ? "<br>" + body : "");
    }

    readonly property string iconSrc: {
        if (n.image && String(n.image) !== "") return String(n.image);
        const a = n.appIcon ? String(n.appIcon) : "";
        if (a === "") return "";
        if (a.startsWith("/")) return "file://" + a;
        if (a.startsWith("file:")) return a;
        return Quickshell.iconPath(a, true);
    }

    // progress_bar: apps send hint int:value
    readonly property real progress: {
        const h = n.hints;
        if (!h || h.value === undefined) return -1;
        return Math.max(0, Math.min(100, Number(h.value))) / 100;
    }

    function doAction() {
        const acts = n.actions;
        let a = null;
        for (let i = 0; i < acts.length; i++)
            if (acts[i].identifier === "default") a = acts[i];
        if (!a && acts.length > 0) a = acts[0];
        if (a) a.invoke();
        n.dismiss();
    }

    Layout.preferredWidth: cfg.cardWidth
    implicitHeight: Math.min(cfg.maxHeight, content.implicitHeight + cfg.padding * 2)
    height: implicitHeight
    radius: cfg.radius
    color: Qt.alpha(st.bg, cfg.bgOpacity)
    border.width: cfg.frameWidth
    border.color: st.frame
    clip: true

    Timer { interval: 10000; running: true; repeat: true; onTriggered: card.now = Date.now() }

    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: cfg.padding }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: cfg.iconPad

            ClippingRectangle {
                visible: card.iconSrc !== ""
                Layout.alignment: Qt.AlignTop
                implicitWidth: cfg.iconSize
                implicitHeight: cfg.iconSize
                radius: cfg.iconRadius
                color: "transparent"
                Image {
                    anchors.fill: parent
                    source: card.iconSrc
                    sourceSize.width: cfg.iconSize * 2
                    sourceSize.height: cfg.iconSize * 2
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                text: card.markup
                textFormat: Text.StyledText
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
                color: card.st.fg
                font.family: Theme.font
                font.pointSize: cfg.fontPt
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
        }

        Rectangle {                                  // progress bar
            visible: card.progress >= 0
            Layout.fillWidth: true
            implicitHeight: cfg.progressHeight
            radius: height / 2
            color: Theme.surface0
            Rectangle {
                width: parent.width * card.progress
                height: parent.height
                radius: height / 2
                color: Theme.mauve
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: m => {
            if (m.button === Qt.LeftButton) card.n.dismiss();        // mouse_left_click   = close_current
            else if (m.button === Qt.MiddleButton) card.doAction();  // mouse_middle_click = do_action
            else cfg.dismissAll();                                    // mouse_right_click  = close_all
        }
    }
}
