import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.CustomTheme

// Media-Centric Status Bar Module with Stable CAVA Spectrum & Interactive Micro-Expansion
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
    readonly property string trackArtist: {
        if (!hasPlayer) return "";
        if (activePlayer.trackArtist) return activePlayer.trackArtist;
        if (activePlayer.trackArtists && activePlayer.trackArtists.length > 0) return activePlayer.trackArtists[0];
        return "";
    }
    readonly property string artUrl: hasPlayer && activePlayer.trackArtUrl ? activePlayer.trackArtUrl : ""

    // Collapse completely when nothing is playing/available
    readonly property bool collapsed: !hasPlayer || (trackTitle === "" && !isPlaying)
    visible: !collapsed

    // Expansion state on hover or manual lock
    property bool manualExpanded: false
    property bool isExpanded: (mediaMouse.containsMouse || manualExpanded) && !collapsed

    // Keyboard navigation focus flag
    property bool focused: false

    function activate(): void {
        manualExpanded = !manualExpanded;
    }

    implicitHeight: 28
    implicitWidth: collapsed ? 0 : (isExpanded ? (expandedContent.implicitWidth + 16) : (compactContent.implicitWidth + 12))
    radius: 14
    color: (mediaMouse.containsMouse || root.focused) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
    border.color: (mediaMouse.containsMouse || root.focused) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.30) : "transparent"
    border.width: 1
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: 320; easing.type: Easing.OutQuint }
    }

    Behavior on color {
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
        running: root.isPlaying && !root.collapsed

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

    // --- COMPACT VIEW ---
    RowLayout {
        id: compactContent
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        opacity: root.isExpanded ? 0 : 1
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
        }

        // Cover Art / Music Glyph
        Rectangle {
            implicitWidth: 20
            implicitHeight: 20
            radius: 5
            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            clip: true
            Layout.alignment: Qt.AlignVCenter

            Image {
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: root.artUrl !== ""
            }

            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: "monospace"
                font.pixelSize: 12
                color: Theme.primary
                visible: root.artUrl === ""
            }
        }

        // Title
        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 100
            text: root.trackTitle
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
        }

        // Dot separator (if artist exists)
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: "•"
            color: Theme.outline
            font.family: Theme.fontFamily
            font.pixelSize: 11
            visible: root.trackArtist !== ""
            opacity: 0.6
        }

        // Artist
        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 75
            text: root.trackArtist
            color: Theme.on_background
            font.family: Theme.fontFamily
            font.pixelSize: 12
            opacity: 0.8
            elide: Text.ElideRight
            visible: root.trackArtist !== ""
        }

        // Mini Play/Pause button
        Rectangle {
            implicitWidth: 20
            implicitHeight: 20
            radius: 10
            color: playBtnMouse.containsMouse ? Theme.primary : "transparent"
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation { duration: 200 }
            }

            Text {
                anchors.centerIn: parent
                text: root.isPlaying ? "󰏤" : "󰐊"
                font.family: "monospace"
                font.pixelSize: 12
                color: playBtnMouse.containsMouse ? Theme.background : Theme.primary
            }

            MouseArea {
                id: playBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.activePlayer) {
                        root.activePlayer.isPlaying = !root.activePlayer.isPlaying;
                    }
                }
            }
        }

        // Fixed-dimension CAVA spectrum container to prevent any layout vibration
        Item {
            id: barsContainer
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: root.totalBarsWidth
            implicitHeight: root.maxBarHeight
            width: root.totalBarsWidth
            height: root.maxBarHeight
            visible: root.isPlaying
            clip: true

            Row {
                id: barsRow
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
                    }
                }
            }
        }
    }

    // --- EXPANDED INTERACTIVE VIEW ---
    RowLayout {
        id: expandedContent
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        opacity: root.isExpanded ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
        }

        // Cover Art / Music Glyph
        Rectangle {
            implicitWidth: 22
            implicitHeight: 22
            radius: 6
            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            clip: true
            Layout.alignment: Qt.AlignVCenter

            Image {
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: root.artUrl !== ""
            }

            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: "monospace"
                font.pixelSize: 13
                color: Theme.primary
                visible: root.artUrl === ""
            }
        }

        // Track & Artist Column
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.maximumWidth: 120
                text: root.trackTitle
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.maximumWidth: 120
                text: root.trackArtist !== "" ? root.trackArtist : "Unknown Artist"
                color: Theme.on_background
                font.family: Theme.fontFamily
                font.pixelSize: 10
                opacity: 0.75
                elide: Text.ElideRight
            }
        }

        // Media Control Buttons: Prev, Play/Pause, Next
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            // Previous
            Rectangle {
                implicitWidth: 22
                implicitHeight: 22
                radius: 11
                color: prevMouse.containsMouse ? Theme.primary : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    font.family: "monospace"
                    font.pixelSize: 12
                    color: prevMouse.containsMouse ? Theme.background : Theme.primary
                }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.activePlayer) root.activePlayer.previous()
                }
            }

            // Play / Pause
            Rectangle {
                implicitWidth: 24
                implicitHeight: 24
                radius: 12
                color: Theme.primary
                Text {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    font.family: "monospace"
                    font.pixelSize: 13
                    color: Theme.background
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.activePlayer) root.activePlayer.isPlaying = !root.activePlayer.isPlaying
                }
            }

            // Next
            Rectangle {
                implicitWidth: 22
                implicitHeight: 22
                radius: 11
                color: nextMouse.containsMouse ? Theme.primary : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    font.family: "monospace"
                    font.pixelSize: 12
                    color: nextMouse.containsMouse ? Theme.background : Theme.primary
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.activePlayer) root.activePlayer.next()
                }
            }
        }
    }

    MouseArea {
        id: mediaMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["qs", "ipc", "call", "audio", "toggle"])
            } else {
                root.activate()
            }
        }
    }
}
