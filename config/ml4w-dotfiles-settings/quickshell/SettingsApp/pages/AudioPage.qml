import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import qs.CustomTheme
import "../components"

ColumnLayout {
    id: root

    spacing: 18
    Layout.fillWidth: true

    // Track all PipeWire nodes so their audio state, volumes, and mute flags are live-bound
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
            let name = s.description || s.nickname || s.name || ("Output Device #" + s.id);
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

    // ========================================================
    // HEADER
    // ========================================================
    SectionHeader {
        title: "Audio"
        subtitle: "PipeWire & WirePlumber native sound control center, device routing, and application volume."
    }

    // ========================================================
    // OUTPUT DEVICES & MASTER VOLUME
    // ========================================================
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: outputColumn.implicitHeight + 32
        radius: 10
        color: Theme.background
        border.color: Theme.primary
        border.width: 1

        ColumnLayout {
            id: outputColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // Section Title & Status
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Output Device"
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                        color: Theme.primary
                    }

                    Text {
                        text: Pipewire.defaultAudioSink 
                            ? (Pipewire.defaultAudioSink.description || Pipewire.defaultAudioSink.name)
                            : "Searching for output devices..."
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.on_background
                        opacity: 0.8
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Volume Percent Badge
                Rectangle {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 28
                    radius: 6
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
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
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.primary
                    }
                }
            }

            // Output Volume Slider & Mute Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Slider {
                    id: outputSlider
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
                        x: outputSlider.leftPadding
                        y: outputSlider.topPadding + outputSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 6
                        width: outputSlider.availableWidth
                        height: implicitHeight
                        radius: 3
                        color: Theme.background
                        border.color: Theme.primary
                        border.width: 1

                        Rectangle {
                            width: outputSlider.visualPosition * parent.width
                            height: parent.height
                            color: Theme.primary
                            radius: 3
                        }
                    }

                    handle: Rectangle {
                        x: outputSlider.leftPadding + outputSlider.visualPosition * (outputSlider.availableWidth - width)
                        y: outputSlider.topPadding + outputSlider.availableHeight / 2 - height / 2
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 8
                        color: outputSlider.pressed ? Theme.background : Theme.primary
                        border.color: Theme.primary
                        border.width: 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }

                // Output Mute Button
                Button {
                    id: outputMuteBtn
                    Layout.preferredWidth: 84
                    Layout.preferredHeight: 34
                    hoverEnabled: true

                    readonly property bool isMuted: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted

                    contentItem: Text {
                        text: outputMuteBtn.isMuted ? "Unmute" : "Mute"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: outputMuteBtn.isMuted ? Theme.on_primary : Theme.primary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        color: outputMuteBtn.isMuted 
                            ? Theme.primary 
                            : (outputMuteBtn.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
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

            // Output Device Switcher Dropdown
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.outputSinks.length > 1

                Text {
                    text: "Select Output Device"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.primary
                }

                ComboBox {
                    id: outputCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
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
                        border.color: outputCombo.activeFocus || outputCombo.hovered ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.6)
                        radius: 8
                        border.width: 1
                    }

                    contentItem: Text {
                        text: (outputCombo.currentIndex >= 0 && outputCombo.currentIndex < root.outputNames.length) 
                            ? root.outputNames[outputCombo.currentIndex] 
                            : "Choose device..."
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.primary
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 12
                        rightPadding: 32
                        elide: Text.ElideRight
                    }

                    indicator: Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: outputCombo.popup.visible ? "▲" : "▼"
                        font.pixelSize: 10
                        color: Theme.primary
                    }

                    popup: Popup {
                        y: outputCombo.height + 2
                        width: outputCombo.width
                        implicitHeight: Math.min(240, Math.max(48, root.outputNames.length * 36 + 16))
                        padding: 6

                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: outputCombo.popup.visible ? outputCombo.delegateModel : null
                            currentIndex: outputCombo.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator { }
                        }

                        background: Rectangle {
                            color: Theme.background
                            border.color: Theme.primary
                            border.width: 1
                            radius: 8
                        }
                    }

                    delegate: ItemDelegate {
                        width: outputCombo.width - 12
                        implicitHeight: 34
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
                            font.pixelSize: 13
                            font.bold: outputCombo.currentIndex === index
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                            rightPadding: 8
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            color: highlighted ? Theme.primary : (outputCombo.currentIndex === index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
                            radius: 4
                        }
                        highlighted: outputCombo.highlightedIndex === index
                    }
                }
            }
        }
    }

    // ========================================================
    // INPUT DEVICES (MICROPHONE) & INPUT VOLUME
    // ========================================================
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: inputColumn.implicitHeight + 32
        radius: 10
        color: Theme.background
        border.color: Theme.primary
        border.width: 1

        ColumnLayout {
            id: inputColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // Section Title & Status
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Input Device (Microphone)"
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.bold: true
                        color: Theme.primary
                    }

                    Text {
                        text: Pipewire.defaultAudioSource 
                            ? (Pipewire.defaultAudioSource.description || Pipewire.defaultAudioSource.name)
                            : "No microphone detected"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.on_background
                        opacity: 0.8
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Volume Percent Badge
                Rectangle {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 28
                    radius: 6
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
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
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.primary
                    }
                }
            }

            // Input Volume Slider & Mute Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Slider {
                    id: inputSlider
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
                        x: inputSlider.leftPadding
                        y: inputSlider.topPadding + inputSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 6
                        width: inputSlider.availableWidth
                        height: implicitHeight
                        radius: 3
                        color: Theme.background
                        border.color: Theme.primary
                        border.width: 1

                        Rectangle {
                            width: inputSlider.visualPosition * parent.width
                            height: parent.height
                            color: Theme.primary
                            radius: 3
                        }
                    }

                    handle: Rectangle {
                        x: inputSlider.leftPadding + inputSlider.visualPosition * (inputSlider.availableWidth - width)
                        y: inputSlider.topPadding + inputSlider.availableHeight / 2 - height / 2
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 8
                        color: inputSlider.pressed ? Theme.background : Theme.primary
                        border.color: Theme.primary
                        border.width: 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }

                // Input Mute Button
                Button {
                    id: inputMuteBtn
                    Layout.preferredWidth: 84
                    Layout.preferredHeight: 34
                    hoverEnabled: true

                    readonly property bool isMuted: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted

                    contentItem: Text {
                        text: inputMuteBtn.isMuted ? "Unmute" : "Mute"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: inputMuteBtn.isMuted ? Theme.on_primary : Theme.primary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        color: inputMuteBtn.isMuted 
                            ? Theme.primary 
                            : (inputMuteBtn.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
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

            // Input Device Switcher Dropdown
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.inputSources.length > 1

                Text {
                    text: "Select Input Device"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.primary
                }

                ComboBox {
                    id: inputCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
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
                        border.color: inputCombo.activeFocus || inputCombo.hovered ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.6)
                        radius: 8
                        border.width: 1
                    }

                    contentItem: Text {
                        text: (inputCombo.currentIndex >= 0 && inputCombo.currentIndex < root.inputNames.length) 
                            ? root.inputNames[inputCombo.currentIndex] 
                            : "Choose microphone..."
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.primary
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 12
                        rightPadding: 32
                        elide: Text.ElideRight
                    }

                    indicator: Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: inputCombo.popup.visible ? "▲" : "▼"
                        font.pixelSize: 10
                        color: Theme.primary
                    }

                    popup: Popup {
                        y: inputCombo.height + 2
                        width: inputCombo.width
                        implicitHeight: Math.min(240, Math.max(48, root.inputNames.length * 36 + 16))
                        padding: 6

                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: inputCombo.popup.visible ? inputCombo.delegateModel : null
                            currentIndex: inputCombo.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator { }
                        }

                        background: Rectangle {
                            color: Theme.background
                            border.color: Theme.primary
                            border.width: 1
                            radius: 8
                        }
                    }

                    delegate: ItemDelegate {
                        width: inputCombo.width - 12
                        implicitHeight: 34
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
                            font.pixelSize: 13
                            font.bold: inputCombo.currentIndex === index
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                            rightPadding: 8
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            color: highlighted ? Theme.primary : (inputCombo.currentIndex === index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
                            radius: 4
                        }
                        highlighted: inputCombo.highlightedIndex === index
                    }
                }
            }
        }
    }

    // ========================================================
    // APPLICATION PLAYBACK STREAMS
    // ========================================================
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: streamsColumn.implicitHeight + 32
        radius: 10
        color: Theme.background
        border.color: Theme.primary
        border.width: 1

        ColumnLayout {
            id: streamsColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "Application Volume"
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.bold: true
                color: Theme.primary
            }

            Text {
                text: "Granular playback levels for active media and application audio streams."
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.on_background
                opacity: 0.8
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            // Empty state when no playback streams exist
            Text {
                text: "No active application audio streams currently playing."
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.on_background
                opacity: 0.6
                visible: root.streamNodes.length === 0
                Layout.topMargin: 8
                Layout.bottomMargin: 8
            }

            // List of active streams
            Repeater {
                model: root.streamNodes

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: streamRow.implicitHeight + 16
                    radius: 8
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.05)
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                    border.width: 1

                    ColumnLayout {
                        id: streamRow
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: {
                                    let appName = modelData.properties ? (modelData.properties["application.name"] || modelData.properties["media.name"]) : "";
                                    if (appName && appName.length > 0) return appName;
                                    return modelData.description || modelData.name || ("Stream #" + modelData.id);
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
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
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.primary
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Slider {
                                id: streamSlider
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
                                    x: streamSlider.leftPadding
                                    y: streamSlider.topPadding + streamSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 150
                                    implicitHeight: 5
                                    width: streamSlider.availableWidth
                                    height: implicitHeight
                                    radius: 2
                                    color: Theme.background
                                    border.color: Theme.primary
                                    border.width: 1

                                    Rectangle {
                                        width: streamSlider.visualPosition * parent.width
                                        height: parent.height
                                        color: Theme.primary
                                        radius: 2
                                    }
                                }

                                handle: Rectangle {
                                    x: streamSlider.leftPadding + streamSlider.visualPosition * (streamSlider.availableWidth - width)
                                    y: streamSlider.topPadding + streamSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 14
                                    implicitHeight: 14
                                    radius: 7
                                    color: streamSlider.pressed ? Theme.background : Theme.primary
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
                                id: streamMuteBtn
                                Layout.preferredWidth: 70
                                Layout.preferredHeight: 28
                                hoverEnabled: true

                                readonly property bool isMuted: modelData.audio && modelData.audio.muted

                                contentItem: Text {
                                    text: streamMuteBtn.isMuted ? "Unmute" : "Mute"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: streamMuteBtn.isMuted ? Theme.on_primary : Theme.primary
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    radius: 5
                                    color: streamMuteBtn.isMuted 
                                        ? Theme.primary 
                                        : (streamMuteBtn.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
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

    // ========================================================
    // ADVANCED AUDIO ROUTING (PAVUCONTROL)
    // ========================================================
    ActionCard {
        Layout.fillWidth: true
        title: "Advanced Audio Mixer"
        description: "Launch pavucontrol for hardware port selection, loopback devices, and granular channel calibration."
        buttonText: "Open Pavucontrol"
        isPrimary: false
        onClicked: Quickshell.execDetached(["pavucontrol"])
    }
}

