import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.CustomTheme

// Media-Centric Status Bar Module with Always-Visible CAVA Spectrum & Fluid Transitions
Rectangle {
    id: root

    // Find the currently active / playing MPRIS player
    readonly property var activePlayer: {
        const list = Mpris.players.values;
        if (!list || list.length === 0) return null;
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i];
        }
        return list[0];
    }

    readonly property bool hasPlayer: activePlayer !== null
    readonly property bool isPlaying: hasPlayer && activePlayer.isPlaying
    readonly property string trackTitle: hasPlayer && activePlayer.trackTitle ? activePlayer.trackTitle : ""

    // Collapse completely when nothing is playing/available
    readonly property bool collapsed: !hasPlayer || (trackTitle === "" && !isPlaying)

    // Smooth Appearance & Dissolve Opacity
    opacity: collapsed ? 0.0 : 1.0
    visible: opacity > 0.001 || implicitWidth > 0.5
    clip: true

    Behavior on opacity {
        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
    }

    // Hover handler for non-blocking hover detection
    HoverHandler {
        id: hoverHandler
    }

    // Expansion state on hover or manual lock
    property bool manualExpanded: false
    property bool isExpanded: (hoverHandler.hovered || manualExpanded) && !collapsed

    // Keyboard navigation focus flag
    property bool focused: false

    function activate(): void {
        togglePlay()
    }

    // Safe playback actions with DBus MPRIS fallback to playerctl
    function togglePlay(): void {
        if (root.activePlayer && typeof root.activePlayer.togglePlaying === "function") {
            try {
                root.activePlayer.togglePlaying();
                return;
            } catch (e) {
                console.warn("Mpris togglePlaying error:", e);
            }
        }
        Quickshell.execDetached(["playerctl", "play-pause"]);
    }

    function previousTrack(): void {
        if (root.activePlayer && typeof root.activePlayer.previous === "function") {
            try {
                root.activePlayer.previous();
                return;
            } catch (e) {
                console.warn("Mpris previous error:", e);
            }
        }
        Quickshell.execDetached(["playerctl", "previous"]);
    }

    function nextTrack(): void {
        if (root.activePlayer && typeof root.activePlayer.next === "function") {
            try {
                root.activePlayer.next();
                return;
            } catch (e) {
                console.warn("Mpris next error:", e);
            }
        }
        Quickshell.execDetached(["playerctl", "next"]);
    }

    implicitHeight: 28
    implicitWidth: collapsed ? 0 : (isExpanded ? (expandedContent.implicitWidth + 18) : (compactContent.implicitWidth + 14))

    Behavior on implicitWidth {
        NumberAnimation { duration: 380; easing.type: Easing.OutQuint }
    }

    radius: 14
    color: (hoverHandler.hovered || root.focused) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10) : "transparent"
    border.color: (hoverHandler.hovered || root.focused) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25) : "transparent"
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: 300; easing.type: Easing.OutQuint }
    }

    Behavior on border.color {
        ColorAnimation { duration: 300; easing.type: Easing.OutQuint }
    }

    // --- CAVA REAL-TIME SPECTRUM INTEGRATION (16 BARS STEREO) ---
    readonly property int barCount: 16
    readonly property real minBarHeight: 2.0
    readonly property real maxBarHeight: 14.0
    readonly property real barWidth: 2.0
    readonly property real barRadius: 1.0
    readonly property real barSpacing: 1.5
    readonly property real totalBarsWidth: (barWidth * barCount) + (barSpacing * (barCount - 1))
    property real visualPeak: 50.0
    property var rawValues: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

    Process {
        id: cavaProc
        command: [
            "stdbuf", "-oL", "-eL",
            "/home/zane/.local/bin/cava",
            "-p", Quickshell.env("HOME") + "/.config/cava/quickshell.conf"
        ]
        running: !root.collapsed

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let str = data.trim();
                if (!str) return;
                let parts = str.split(";");
                let vals = [];
                let framePeak = 0;
                for (let i = 0; i < root.barCount; i++) {
                    let num = (i < parts.length && parts[i] !== "") ? parseInt(parts[i]) || 0 : 0;
                    vals.push(num);
                    if (num > framePeak) framePeak = num;
                }
                if (framePeak > root.visualPeak) {
                    root.visualPeak = Math.min(100.0, framePeak);
                } else {
                    root.visualPeak = Math.max(45.0, root.visualPeak * 0.98);
                }
                root.rawValues = vals;
            }
        }
    }

    // Smooth Leading Divider inside Module
    Rectangle {
        id: leadingDivider
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: 16
        color: Theme.outline_variant
        opacity: root.collapsed ? 0.0 : 0.35

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }
    }

    // Background click handler (z: 0 so child buttons take precedence)
    MouseArea {
        id: bgMouse
        anchors.fill: parent
        z: 0
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["qs", "ipc", "call", "audio", "toggle"])
            } else {
                root.manualExpanded = !root.manualExpanded;
            }
        }
    }

    // --- COMPACT VIEW ---
    RowLayout {
        id: compactContent
        z: 1
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        opacity: root.isExpanded ? 0 : 1
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        transform: Translate {
            x: root.isExpanded ? -8 : 0
            Behavior on x {
                NumberAnimation { duration: 280; easing.type: Easing.OutQuint }
            }
        }

        // Clean Music Icon
        Item {
            implicitWidth: 16
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: "monospace"
                font.pixelSize: 13
                color: Theme.primary
                opacity: root.isPlaying ? 1.0 : 0.60
                scale: root.isPlaying ? 1.05 : 1.0

                Behavior on opacity {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                Behavior on scale {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
            }
        }

        // Title (Single title, no artist)
        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 120
            text: root.trackTitle
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
        }

        // Mini Play/Pause button with Spring Scale Interaction
        Item {
            id: playBtnCompact
            implicitWidth: 18
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: playIconCompact
                anchors.centerIn: parent
                text: root.isPlaying ? "󰏤" : "󰐊"
                font.family: "monospace"
                font.pixelSize: 13
                color: Theme.primary
                opacity: playBtnMouse.containsMouse ? 1.0 : (root.isPlaying ? 0.90 : 0.70)
                scale: playBtnMouse.pressed ? 0.82 : (playBtnMouse.containsMouse ? 1.25 : 1.0)

                Behavior on scale {
                    NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
            }

            MouseArea {
                id: playBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePlay()
            }
        }

        // Fixed-dimension CAVA spectrum container (Always visible while player is visible)
        Item {
            id: compactBarsContainer
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root.totalBarsWidth
            implicitHeight: root.maxBarHeight
            width: root.totalBarsWidth
            height: root.maxBarHeight
            opacity: root.isPlaying ? 1.0 : 0.50
            clip: true

            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }

            Row {
                id: compactBarsRow
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.barSpacing

                Repeater {
                    model: root.barCount
                    Rectangle {
                        required property int index
                        anchors.bottom: parent.bottom
                        width: root.barWidth
                        radius: root.barRadius
                        color: Theme.primary
                        height: (root.rawValues && root.rawValues[index] !== undefined && root.isPlaying)
                            ? Math.max(root.minBarHeight, Math.min(root.maxBarHeight, (root.rawValues[index] / root.visualPeak) * root.maxBarHeight))
                            : root.minBarHeight

                        Behavior on height {
                            NumberAnimation { duration: 45; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }

    // --- EXPANDED INTERACTIVE VIEW ---
    RowLayout {
        id: expandedContent
        z: 1
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        opacity: root.isExpanded ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        transform: Translate {
            x: root.isExpanded ? 0 : 8
            Behavior on x {
                NumberAnimation { duration: 280; easing.type: Easing.OutQuint }
            }
        }

        // Clean Music Icon
        Item {
            implicitWidth: 16
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: "monospace"
                font.pixelSize: 13
                color: Theme.primary
            }
        }

        // Track Title (Single bold title, no artist)
        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 120
            text: root.trackTitle
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
        }

        // Media Control Buttons: Prev, Play/Pause, Next with Micro-Spring Animations
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            // Previous Button
            Item {
                implicitWidth: 18
                implicitHeight: 20

                Text {
                    id: prevIcon
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.family: "monospace"
                    font.pixelSize: 13
                    color: Theme.primary
                    opacity: prevMouse.containsMouse ? 1.0 : 0.70
                    scale: prevMouse.pressed ? 0.82 : (prevMouse.containsMouse ? 1.25 : 1.0)

                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.previousTrack()
                }
            }

            // Play / Pause Button
            Item {
                implicitWidth: 18
                implicitHeight: 20

                Text {
                    id: playPauseExpandedIcon
                    anchors.centerIn: parent
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    font.family: "monospace"
                    font.pixelSize: 14
                    color: Theme.primary
                    opacity: playPauseExpandedMouse.containsMouse ? 1.0 : (root.isPlaying ? 0.95 : 0.75)
                    scale: playPauseExpandedMouse.pressed ? 0.82 : (playPauseExpandedMouse.containsMouse ? 1.25 : 1.0)

                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: playPauseExpandedMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.togglePlay()
                }
            }

            // Next Button
            Item {
                implicitWidth: 18
                implicitHeight: 20

                Text {
                    id: nextIcon
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.family: "monospace"
                    font.pixelSize: 13
                    color: Theme.primary
                    opacity: nextMouse.containsMouse ? 1.0 : 0.70
                    scale: nextMouse.pressed ? 0.82 : (nextMouse.containsMouse ? 1.25 : 1.0)

                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextTrack()
                }
            }
        }

        // Expanded View CAVA Spectrum (Always visible while player is visible)
        Item {
            id: expandedBarsContainer
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root.totalBarsWidth
            implicitHeight: root.maxBarHeight
            width: root.totalBarsWidth
            height: root.maxBarHeight
            opacity: root.isPlaying ? 1.0 : 0.50
            clip: true

            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }

            Row {
                id: expandedBarsRow
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.barSpacing

                Repeater {
                    model: root.barCount
                    Rectangle {
                        required property int index
                        anchors.bottom: parent.bottom
                        width: root.barWidth
                        radius: root.barRadius
                        color: Theme.primary
                        height: (root.rawValues && root.rawValues[index] !== undefined && root.isPlaying)
                            ? Math.max(root.minBarHeight, Math.min(root.maxBarHeight, (root.rawValues[index] / root.visualPeak) * root.maxBarHeight))
                            : root.minBarHeight

                        Behavior on height {
                            NumberAnimation { duration: 45; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }
}
