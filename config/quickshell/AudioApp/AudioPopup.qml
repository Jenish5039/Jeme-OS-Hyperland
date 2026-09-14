import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtQml
import qs.CustomTheme

PanelWindow {
    id: root

    // --- WAYLAND & LAYER-SHELL CONFIGURATION ---
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore

    implicitWidth: 420
    implicitHeight: 620
    color: "transparent"

    anchors {
        top: true
        right: true
    }

    margins {
        top: 52
        right: root.currentMargin
    }

    // --- CLICK OUTSIDE TO CLOSE (Native Hyprland) ---
    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen && root.showWindow
        onCleared: {
            if (root.isOpen) {
                root.isOpen = false
            }
        }
    }

    // --- ESCAPE KEY LISTENER ---
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.isOpen) {
                root.isOpen = false
            }
        }
    }

    // --- ANIMATION & MAPPING LOGIC (Slide In / Out) ---
    property bool isOpen: false
    property bool showWindow: false
    visible: showWindow

    onIsOpenChanged: {
        if (isOpen) {
            showWindow = true
        }
    }

    property real currentMargin: isOpen ? 20 : -470

    Behavior on currentMargin {
        NumberAnimation {
            id: slideAnim
            duration: 350
            easing.type: Easing.OutQuint
            onRunningChanged: {
                if (!running && !root.isOpen) {
                    root.showWindow = false
                }
            }
        }
    }

    // --- IPC HANDLER ---
    IpcHandler {
        target: "audio"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
        function isOpen(): bool { return root.isOpen }
    }

    // --- PIPEWIRE OBJECT TRACKER ---
    PwObjectTracker {
        id: pwTracker
        objects: Pipewire.nodes ? Pipewire.nodes.values : []
    }

    // Reactive list of active Audio Output Sinks
    readonly property var outputSinks: {
        let arr = [];
        if (Pipewire.ready && Pipewire.nodes && Pipewire.nodes.values) {
            for (let i = 0; i < Pipewire.nodes.values.length; i++) {
                let n = Pipewire.nodes.values[i];
                if (n && n.isSink && !n.isStream && n.audio) {
                    arr.push(n);
                }
            }
        }
        return arr;
    }

    readonly property var outputNames: {
        let names = [];
        for (let i = 0; i < outputSinks.length; i++) {
            let s = outputSinks[i];
            let name = s.description || s.nickname || s.name || ("Device #" + s.id);
            names.push(name);
        }
        return names;
    }

    // Reactive list of active Audio Input Sources (Microphones)
    readonly property var inputSources: {
        let arr = [];
        if (Pipewire.ready && Pipewire.nodes && Pipewire.nodes.values) {
            for (let i = 0; i < Pipewire.nodes.values.length; i++) {
                let n = Pipewire.nodes.values[i];
                if (n && !n.isSink && !n.isStream && n.audio) {
                    arr.push(n);
                }
            }
        }
        return arr;
    }

    readonly property var inputNames: {
        let names = [];
        for (let i = 0; i < inputSources.length; i++) {
            let s = inputSources[i];
            let name = s.description || s.nickname || s.name || ("Microphone #" + s.id);
            names.push(name);
        }
        return names;
    }

    // Reactive list of active Playback Application Streams
    readonly property var streamNodes: {
        let arr = [];
        if (Pipewire.ready && Pipewire.nodes && Pipewire.nodes.values) {
            for (let i = 0; i < Pipewire.nodes.values.length; i++) {
                let n = Pipewire.nodes.values[i];
                if (n && n.isSink && n.isStream && n.audio) {
                    arr.push(n);
                }
            }
        }
        return arr;
    }

    // ==========================================
    // REUSABLE POPUP COMPONENTS
    // ==========================================
    component ActionIcon: Button {
        id: actBtn
        property string iconTxt: ""
        property string iconSrc: ""
        implicitWidth: 28
        implicitHeight: 28
        hoverEnabled: true
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.NoButton
        }
        background: Rectangle {
            color: actBtn.hovered ? Theme.primary_container : "transparent"
            radius: 6
        }
        contentItem: Item {
            Text {
                anchors.centerIn: parent
                text: actBtn.iconTxt
                visible: actBtn.iconSrc === ""
                color: actBtn.hovered ? Theme.on_primary_container : Theme.primary
                font.family: "monospace"
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            Image {
                anchors.centerIn: parent
                source: actBtn.iconSrc
                width: 16
                height: 16
                sourceSize.width: 16
                sourceSize.height: 16
                visible: actBtn.iconSrc !== ""
                fillMode: Image.PreserveAspectFit
                layer.enabled: actBtn.iconSrc !== ""
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: actBtn.hovered ? Theme.on_primary_container : Theme.primary
                }
            }
        }
    }

    component PopupButton: Button {
        id: btnControl
        Layout.fillWidth: true
        hoverEnabled: true
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.NoButton
        }
        background: Rectangle {
            color: btnControl.down ? Theme.primary : (btnControl.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
            border.color: Theme.primary
            border.width: 1
            radius: 8
        }
        contentItem: Text {
            text: btnControl.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            color: btnControl.down ? Theme.on_primary : Theme.primary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            padding: 6
        }
    }

    // ==========================================
    // MAIN PANEL COMPOSITE SURFACE
    // ==========================================
    Item {
        anchors.fill: parent
        anchors.margins: 15

        RectangularShadow {
            id: shadow
            anchors.fill: mainBgRect
            radius: mainBgRect.radius
            blur: 15
            color: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.4)
        }

        Rectangle {
            id: mainBgRect
            anchors.fill: parent
            radius: 12
            opacity: 0.95

            // Gradient outer border
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.primary }
                GradientStop { position: 1.0; color: Theme.on_primary }
            }

            // Inset background fill
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: parent.radius - anchors.margins
                color: Theme.background

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // --- HEADER ---
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Image {
                            source: "../shared/icons/volume.svg"
                            width: 20
                            height: 20
                            sourceSize.width: 20
                            sourceSize.height: 20
                            fillMode: Image.PreserveAspectFit
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: Theme.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "Sound & Audio"
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                font.bold: true
                                color: Theme.primary
                            }

                            Text {
                                text: Pipewire.defaultAudioSink 
                                    ? (Pipewire.defaultAudioSink.description || Pipewire.defaultAudioSink.name)
                                    : "PipeWire Audio"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.on_background
                                opacity: 0.75
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        ActionIcon {
                            iconTxt: "✕"
                            onClicked: root.isOpen = false
                        }
                    }

                    // Divider line
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.primary
                        opacity: 0.25
                    }

                    // --- SCROLLABLE CONTENT BODY ---
                    ScrollView {
                        id: contentScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            interactive: true
                            contentItem: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: Theme.primary
                                opacity: parent.pressed ? 1.0 : (parent.active ? 0.7 : 0.3)
                            }
                        }

                        ColumnLayout {
                            width: contentScroll.availableWidth
                            spacing: 12

                            // ==========================================
                            // 1. OUTPUT (MASTER) VOLUME CARD
                            // ==========================================
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: outputCardCol.implicitHeight + 20
                                radius: 8
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.06)
                                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                                border.width: 1

                                ColumnLayout {
                                    id: outputCardCol
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: "Speaker Volume"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: Theme.primary
                                            Layout.fillWidth: true
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 56
                                            Layout.preferredHeight: 22
                                            radius: 4
                                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                            border.color: Theme.primary
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: {
                                                    if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio) return "0%";
                                                    if (Pipewire.defaultAudioSink.audio.muted) return "Muted";
                                                    return Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%";
                                                }
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: Theme.primary
                                            }
                                        }
                                    }

                                    // Slider & Mute button row
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Slider {
                                            id: masterSlider
                                            Layout.fillWidth: true
                                            from: 0
                                            to: 100
                                            stepSize: 1
                                            value: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio)
                                                ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100)
                                                : 0
                                            enabled: Pipewire.defaultAudioSink !== null && Pipewire.defaultAudioSink.audio !== null

                                            onMoved: {
                                                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                                    Pipewire.defaultAudioSink.audio.volume = value / 100.0;
                                                }
                                            }

                                            background: Rectangle {
                                                x: masterSlider.leftPadding
                                                y: masterSlider.topPadding + masterSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 160
                                                implicitHeight: 6
                                                width: masterSlider.availableWidth
                                                height: implicitHeight
                                                radius: 3
                                                color: Theme.background
                                                border.color: Theme.primary
                                                border.width: 1

                                                Rectangle {
                                                    width: masterSlider.visualPosition * parent.width
                                                    height: parent.height
                                                    color: Theme.primary
                                                    radius: 3
                                                }
                                            }

                                            handle: Rectangle {
                                                x: masterSlider.leftPadding + masterSlider.visualPosition * (masterSlider.availableWidth - width)
                                                y: masterSlider.topPadding + masterSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 16
                                                implicitHeight: 16
                                                radius: 8
                                                color: masterSlider.pressed ? Theme.background : Theme.primary
                                                border.color: Theme.primary
                                                border.width: 1

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    acceptedButtons: Qt.NoButton
                                                }
                                            }
                                        }

                                        Button {
                                            id: masterMuteBtn
                                            Layout.preferredWidth: 68
                                            Layout.preferredHeight: 30
                                            hoverEnabled: true

                                            readonly property bool isMuted: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted

                                            contentItem: Text {
                                                text: masterMuteBtn.isMuted ? "Unmute" : "Mute"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: masterMuteBtn.isMuted ? Theme.on_primary : Theme.primary
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            background: Rectangle {
                                                radius: 6
                                                color: masterMuteBtn.isMuted 
                                                    ? Theme.primary 
                                                    : (masterMuteBtn.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
                                                border.color: Theme.primary
                                                border.width: 1
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                acceptedButtons: Qt.NoButton
                                            }

                                            onClicked: {
                                                if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                                    Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                                                }
                                            }
                                        }
                                    }

                                    // Output device selector dropdown
                                    ComboBox {
                                        id: outCombo
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        visible: root.outputSinks.length > 1
                                        model: root.outputNames
                                        hoverEnabled: true

                                        currentIndex: {
                                            if (!Pipewire.defaultAudioSink) return 0;
                                            for (let i = 0; i < root.outputSinks.length; i++) {
                                                if (root.outputSinks[i] && root.outputSinks[i].id === Pipewire.defaultAudioSink.id) {
                                                    return i;
                                                }
                                            }
                                            return 0;
                                        }

                                        onActivated: function(index) {
                                            if (index >= 0 && index < root.outputSinks.length) {
                                                let targetNode = root.outputSinks[index];
                                                if (targetNode) {
                                                    Pipewire.preferredDefaultAudioSink = targetNode;
                                                    Quickshell.execDetached(["wpctl", "set-default", targetNode.id.toString()]);
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            acceptedButtons: Qt.NoButton
                                        }

                                        background: Rectangle {
                                            color: Theme.background
                                            border.color: outCombo.activeFocus || outCombo.hovered ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.6)
                                            radius: 6
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            text: (outCombo.currentIndex >= 0 && outCombo.currentIndex < root.outputNames.length) 
                                                ? root.outputNames[outCombo.currentIndex] 
                                                : "Select device..."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                            color: Theme.primary
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: 8
                                            rightPadding: 24
                                            elide: Text.ElideRight
                                        }

                                        indicator: Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: outCombo.popup.visible ? "▲" : "▼"
                                            font.pixelSize: 9
                                            color: Theme.primary
                                        }

                                        popup: Popup {
                                            y: outCombo.height + 2
                                            width: outCombo.width
                                            implicitHeight: Math.min(180, Math.max(40, root.outputNames.length * 32 + 12))
                                            padding: 4

                                            contentItem: ListView {
                                                clip: true
                                                implicitHeight: contentHeight
                                                model: outCombo.popup.visible ? outCombo.delegateModel : null
                                                currentIndex: outCombo.highlightedIndex
                                                ScrollIndicator.vertical: ScrollIndicator { }
                                            }

                                            background: Rectangle {
                                                color: Theme.background
                                                border.color: Theme.primary
                                                border.width: 1
                                                radius: 6
                                            }
                                        }

                                        delegate: ItemDelegate {
                                            width: outCombo.width - 8
                                            implicitHeight: 30
                                            hoverEnabled: true

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                acceptedButtons: Qt.NoButton
                                            }

                                            contentItem: Text {
                                                text: modelData
                                                font.family: Theme.fontFamily
                                                color: highlighted ? Theme.on_primary : Theme.primary
                                                font.pixelSize: 12
                                                font.bold: outCombo.currentIndex === index
                                                verticalAlignment: Text.AlignVCenter
                                                leftPadding: 6
                                                rightPadding: 6
                                                elide: Text.ElideRight
                                            }

                                            background: Rectangle {
                                                color: highlighted ? Theme.primary : (outCombo.currentIndex === index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
                                                radius: 4
                                            }
                                            highlighted: outCombo.highlightedIndex === index
                                        }
                                    }
                                }
                            }

                            // ==========================================
                            // 2. INPUT (MICROPHONE) VOLUME CARD
                            // ==========================================
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: inputCardCol.implicitHeight + 20
                                radius: 8
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.06)
                                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                                border.width: 1

                                ColumnLayout {
                                    id: inputCardCol
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: "Microphone Volume"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: Theme.primary
                                            Layout.fillWidth: true
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 56
                                            Layout.preferredHeight: 22
                                            radius: 4
                                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                            border.color: Theme.primary
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: {
                                                    if (!Pipewire.defaultAudioSource || !Pipewire.defaultAudioSource.audio) return "0%";
                                                    if (Pipewire.defaultAudioSource.audio.muted) return "Muted";
                                                    return Math.round(Pipewire.defaultAudioSource.audio.volume * 100) + "%";
                                                }
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: Theme.primary
                                            }
                                        }
                                    }

                                    // Slider & Mute button row
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Slider {
                                            id: micSlider
                                            Layout.fillWidth: true
                                            from: 0
                                            to: 100
                                            stepSize: 1
                                            value: (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio)
                                                ? Math.round(Pipewire.defaultAudioSource.audio.volume * 100)
                                                : 0
                                            enabled: Pipewire.defaultAudioSource !== null && Pipewire.defaultAudioSource.audio !== null

                                            onMoved: {
                                                if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                                                    Pipewire.defaultAudioSource.audio.volume = value / 100.0;
                                                }
                                            }

                                            background: Rectangle {
                                                x: micSlider.leftPadding
                                                y: micSlider.topPadding + micSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 160
                                                implicitHeight: 6
                                                width: micSlider.availableWidth
                                                height: implicitHeight
                                                radius: 3
                                                color: Theme.background
                                                border.color: Theme.primary
                                                border.width: 1

                                                Rectangle {
                                                    width: micSlider.visualPosition * parent.width
                                                    height: parent.height
                                                    color: Theme.primary
                                                    radius: 3
                                                }
                                            }

                                            handle: Rectangle {
                                                x: micSlider.leftPadding + micSlider.visualPosition * (micSlider.availableWidth - width)
                                                y: micSlider.topPadding + micSlider.availableHeight / 2 - height / 2
                                                implicitWidth: 16
                                                implicitHeight: 16
                                                radius: 8
                                                color: micSlider.pressed ? Theme.background : Theme.primary
                                                border.color: Theme.primary
                                                border.width: 1

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    acceptedButtons: Qt.NoButton
                                                }
                                            }
                                        }

                                        Button {
                                            id: micMuteBtn
                                            Layout.preferredWidth: 68
                                            Layout.preferredHeight: 30
                                            hoverEnabled: true

                                            readonly property bool isMuted: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted

                                            contentItem: Text {
                                                text: micMuteBtn.isMuted ? "Unmute" : "Mute"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: micMuteBtn.isMuted ? Theme.on_primary : Theme.primary
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            background: Rectangle {
                                                radius: 6
                                                color: micMuteBtn.isMuted 
                                                    ? Theme.primary 
                                                    : (micMuteBtn.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
                                                border.color: Theme.primary
                                                border.width: 1
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                acceptedButtons: Qt.NoButton
                                            }

                                            onClicked: {
                                                if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                                                    Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted;
                                                }
                                            }
                                        }
                                    }

                                    // Input device selector dropdown
                                    ComboBox {
                                        id: inCombo
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        visible: root.inputSources.length > 1
                                        model: root.inputNames
                                        hoverEnabled: true

                                        currentIndex: {
                                            if (!Pipewire.defaultAudioSource) return 0;
                                            for (let i = 0; i < root.inputSources.length; i++) {
                                                if (root.inputSources[i] && root.inputSources[i].id === Pipewire.defaultAudioSource.id) {
                                                    return i;
                                                }
                                            }
                                            return 0;
                                        }

                                        onActivated: function(index) {
                                            if (index >= 0 && index < root.inputSources.length) {
                                                let targetNode = root.inputSources[index];
                                                if (targetNode) {
                                                    Pipewire.preferredDefaultAudioSource = targetNode;
                                                    Quickshell.execDetached(["wpctl", "set-default", targetNode.id.toString()]);
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            acceptedButtons: Qt.NoButton
                                        }

                                        background: Rectangle {
                                            color: Theme.background
                                            border.color: inCombo.activeFocus || inCombo.hovered ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.6)
                                            radius: 6
                                            border.width: 1
                                        }

                                        contentItem: Text {
                                            text: (inCombo.currentIndex >= 0 && inCombo.currentIndex < root.inputNames.length) 
                                                ? root.inputNames[inCombo.currentIndex] 
                                                : "Select microphone..."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                            color: Theme.primary
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: 8
                                            rightPadding: 24
                                            elide: Text.ElideRight
                                        }

                                        indicator: Text {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: inCombo.popup.visible ? "▲" : "▼"
                                            font.pixelSize: 9
                                            color: Theme.primary
                                        }

                                        popup: Popup {
                                            y: inCombo.height + 2
                                            width: inCombo.width
                                            implicitHeight: Math.min(180, Math.max(40, root.inputNames.length * 32 + 12))
                                            padding: 4

                                            contentItem: ListView {
                                                clip: true
                                                implicitHeight: contentHeight
                                                model: inCombo.popup.visible ? inCombo.delegateModel : null
                                                currentIndex: inCombo.highlightedIndex
                                                ScrollIndicator.vertical: ScrollIndicator { }
                                            }

                                            background: Rectangle {
                                                color: Theme.background
                                                border.color: Theme.primary
                                                border.width: 1
                                                radius: 6
                                            }
                                        }

                                        delegate: ItemDelegate {
                                            width: inCombo.width - 8
                                            implicitHeight: 30
                                            hoverEnabled: true

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                acceptedButtons: Qt.NoButton
                                            }

                                            contentItem: Text {
                                                text: modelData
                                                font.family: Theme.fontFamily
                                                color: highlighted ? Theme.on_primary : Theme.primary
                                                font.pixelSize: 12
                                                font.bold: inCombo.currentIndex === index
                                                verticalAlignment: Text.AlignVCenter
                                                leftPadding: 6
                                                rightPadding: 6
                                                elide: Text.ElideRight
                                            }

                                            background: Rectangle {
                                                color: highlighted ? Theme.primary : (inCombo.currentIndex === index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
                                                radius: 4
                                            }
                                            highlighted: inCombo.highlightedIndex === index
                                        }
                                    }
                                }
                            }

                            // ==========================================
                            // 3. APPLICATION PLAYBACK STREAMS CARD
                            // ==========================================
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: appStreamsCol.implicitHeight + 20
                                radius: 8
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.06)
                                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                                border.width: 1

                                ColumnLayout {
                                    id: appStreamsCol
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Text {
                                        text: "Application Volume"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.primary
                                    }

                                    Text {
                                        text: "No active audio streams playing."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: Theme.on_background
                                        opacity: 0.6
                                        visible: root.streamNodes.length === 0
                                    }

                                    Repeater {
                                        model: root.streamNodes

                                        delegate: Rectangle {
                                            required property var modelData
                                            required property int index

                                            Layout.fillWidth: true
                                            Layout.preferredHeight: singleStreamCol.implicitHeight + 12
                                            radius: 6
                                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.04)
                                            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                                            border.width: 1

                                            ColumnLayout {
                                                id: singleStreamCol
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                spacing: 6

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 6

                                                    Text {
                                                        text: {
                                                            let appName = modelData.properties ? (modelData.properties["application.name"] || modelData.properties["media.name"]) : "";
                                                            if (appName && appName.length > 0) return appName;
                                                            return modelData.description || modelData.name || ("Stream #" + modelData.id);
                                                        }
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        color: Theme.primary
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }

                                                    Text {
                                                        text: {
                                                            if (!modelData.audio) return "0%";
                                                            if (modelData.audio.muted) return "Muted";
                                                            return Math.round(modelData.audio.volume * 100) + "%";
                                                        }
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        color: Theme.primary
                                                    }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 8

                                                    Slider {
                                                        id: stSlider
                                                        Layout.fillWidth: true
                                                        from: 0
                                                        to: 100
                                                        stepSize: 1
                                                        value: modelData.audio ? Math.round(modelData.audio.volume * 100) : 0
                                                        enabled: modelData.audio !== null

                                                        onMoved: {
                                                            if (modelData.audio) {
                                                                modelData.audio.volume = value / 100.0;
                                                            }
                                                        }

                                                        background: Rectangle {
                                                            x: stSlider.leftPadding
                                                            y: stSlider.topPadding + stSlider.availableHeight / 2 - height / 2
                                                            implicitWidth: 120
                                                            implicitHeight: 4
                                                            width: stSlider.availableWidth
                                                            height: implicitHeight
                                                            radius: 2
                                                            color: Theme.background
                                                            border.color: Theme.primary
                                                            border.width: 1

                                                            Rectangle {
                                                                width: stSlider.visualPosition * parent.width
                                                                height: parent.height
                                                                color: Theme.primary
                                                                radius: 2
                                                            }
                                                        }

                                                        handle: Rectangle {
                                                            x: stSlider.leftPadding + stSlider.visualPosition * (stSlider.availableWidth - width)
                                                            y: stSlider.topPadding + stSlider.availableHeight / 2 - height / 2
                                                            implicitWidth: 12
                                                            implicitHeight: 12
                                                            radius: 6
                                                            color: stSlider.pressed ? Theme.background : Theme.primary
                                                            border.color: Theme.primary
                                                            border.width: 1

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                acceptedButtons: Qt.NoButton
                                                            }
                                                        }
                                                    }

                                                    Button {
                                                        id: stMuteBtn
                                                        Layout.preferredWidth: 60
                                                        Layout.preferredHeight: 24
                                                        hoverEnabled: true

                                                        readonly property bool isMuted: modelData.audio && modelData.audio.muted

                                                        contentItem: Text {
                                                            text: stMuteBtn.isMuted ? "Unmute" : "Mute"
                                                            font.family: Theme.fontFamily
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: stMuteBtn.isMuted ? Theme.on_primary : Theme.primary
                                                            horizontalAlignment: Text.AlignHCenter
                                                            verticalAlignment: Text.AlignVCenter
                                                        }

                                                        background: Rectangle {
                                                            radius: 4
                                                            color: stMuteBtn.isMuted 
                                                                ? Theme.primary 
                                                                : (stMuteBtn.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
                                                            border.color: Theme.primary
                                                            border.width: 1
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            acceptedButtons: Qt.NoButton
                                                        }

                                                        onClicked: {
                                                            if (modelData.audio) {
                                                                modelData.audio.muted = !modelData.audio.muted;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // --- FOOTER ACTIONS ---
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Theme.primary
                        opacity: 0.25
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        PopupButton {
                            text: "Open Pavucontrol"
                            onClicked: {
                                Quickshell.execDetached(["pavucontrol"]);
                                root.isOpen = false;
                            }
                        }

                        PopupButton {
                            text: "Audio Settings"
                            onClicked: {
                                Quickshell.execDetached(["bash", "-c", "qs -p " + Quickshell.env("HOME") + "/.local/share/ml4w-dotfiles-settings/quickshell ipc call settings openPage 5"]);
                                root.isOpen = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
