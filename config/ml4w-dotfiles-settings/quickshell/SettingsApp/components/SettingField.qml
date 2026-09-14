import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.CustomTheme

Rectangle {
    id: root

    property string settingId: ""
    property var settingsData: []
    property var setting: null
    property string scriptPath: Quickshell.env("HOME") + "/.local/bin/ml4w-dotfiles-settings"
    property string profile: "com.ml4w.dotfiles"

    property string exactVal: ""
    property var dropdownOptions: []
    property bool isSavedFeedback: false

    implicitWidth: 500
    implicitHeight: Math.max(80, contentRow.implicitHeight + 24)
    radius: 10
    color: Theme.background
    border.color: Theme.primary
    border.width: 1

    onSettingsDataChanged: refresh()
    onSettingIdChanged: refresh()
    onSettingChanged: loadSetting()

    Component.onCompleted: {
        refresh();
        if (root.setting) loadSetting();
    }

    function refresh() {
        if (root.settingId !== "" && root.settingsData && root.settingsData.length > 0) {
            for (var i = 0; i < root.settingsData.length; i++) {
                var grp = root.settingsData[i];
                if (grp && grp.settings) {
                    for (var s = 0; s < grp.settings.length; s++) {
                        if (grp.settings[s].id === root.settingId) {
                            root.setting = grp.settings[s];
                            return;
                        }
                    }
                }
            }
        }
    }

    function loadSetting() {
        if (!root.setting || !root.setting.id) return;

        // 1. Fetch current persisted value (--get)
        getProc.command = [root.scriptPath, "--get", "--id", root.setting.id, root.profile];
        getProc.running = false;
        getProc.running = true;

        // 2. Populate available dropdown options
        if (root.setting.type === "choose") {
            root.dropdownOptions = (root.setting.options && root.setting.options.length > 0) ? root.setting.options : [];
            combo.updateIndex();
        } else if (root.setting.type === "files" || root.setting.type === "folders") {
            var rawFolder = root.setting.folder || "";
            var folder = rawFolder.replace(/^~/, Quickshell.env("HOME"));
            var cmd = "";
            if (root.setting.type === "files") {
                cmd = "ls -1p '" + folder + "' 2>/dev/null | grep -v /";
                if (root.setting.filetypes) {
                    var pattern = root.setting.filetypes.replace(/\./g, "\\.").replace(/,/g, "|");
                    cmd += " | grep -E '(" + pattern + ")$'";
                }
                cmd += " || true";
            } else if (root.setting.type === "folders") {
                cmd = "ls -1p '" + folder + "' 2>/dev/null | grep / | sed 's|/$||' || true";
            }
            filesProc.command = ["bash", "-c", cmd];
            filesProc.running = false;
            filesProc.running = true;
        }
    }

    // Process: Fetch current persisted value
    Process {
        id: getProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.exactVal = this.text.trim();
                combo.updateIndex();
            }
        }
    }

    // Process: Fetch options list for files / folders
    Process {
        id: filesProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text.trim();
                if (out !== "") {
                    root.dropdownOptions = out.split("\n");
                    combo.updateIndex();
                }
            }
        }
    }

    // Process: Persist setting (--set)
    Process {
        id: saveProc
        running: false
        onExited: {
            root.isSavedFeedback = true;
            feedbackTimer.restart();
        }
    }

    Timer {
        id: feedbackTimer
        interval: 1500
        onTriggered: root.isSavedFeedback = false
    }

    function saveValue(val) {
        if (!root.setting || !root.setting.id) return;
        saveProc.command = [root.scriptPath, "--set", "--id", root.setting.id, "--value", val, root.profile];
        saveProc.running = false;
        saveProc.running = true;
        root.exactVal = val;
        combo.updateIndex();
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: root.setting && root.setting.name ? root.setting.name : ""
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.bold: true
                color: Theme.primary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: root.setting && root.setting.instructions ? root.setting.instructions : ""
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.on_background
                opacity: 0.8
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                visible: root.setting && root.setting.instructions !== undefined && root.setting.instructions !== ""
            }
        }

        Item {
            id: fieldContainer
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.preferredWidth: (root.setting && root.setting.type === "toggle") ? 60 : 300
            Layout.preferredHeight: 40

            // ========================================================
            // 1. TOGGLE (Switch)
            // ========================================================
            Switch {
                id: toggleControl
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.setting && root.setting.type === "toggle"
                hoverEnabled: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.NoButton
                }

                checked: {
                    if (!root.setting) return false;
                    var tVal = root.setting.true_value !== undefined ? root.setting.true_value : "true";
                    return root.exactVal === tVal;
                }

                indicator: Rectangle {
                    implicitWidth: 48
                    implicitHeight: 26
                    radius: 13
                    color: toggleControl.checked ? Theme.primary : Theme.background
                    border.color: Theme.primary
                    border.width: 1

                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        x: toggleControl.checked ? parent.width - width - 2 : 2
                        y: 2
                        width: 22
                        implicitHeight: 22
                        radius: 11
                        color: toggleControl.checked ? Theme.background : Theme.on_primary
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                }

                onClicked: {
                    var tVal = root.setting.true_value !== undefined ? root.setting.true_value : "true";
                    var fVal = root.setting.false_value !== undefined ? root.setting.false_value : "false";
                    var newVal = checked ? tVal : fVal;
                    root.saveValue(newVal);
                }
            }

            // ========================================================
            // 2. TEXTFIELD (Enter saves, explicit Save button saves)
            // ========================================================
            RowLayout {
                anchors.fill: parent
                visible: root.setting && root.setting.type === "textfield"
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    color: Theme.background
                    radius: 8
                    border.color: Theme.primary
                    border.width: 1

                    TextInput {
                        id: valInput
                        anchors.fill: parent
                        anchors.margins: 8
                        verticalAlignment: Text.AlignVCenter
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        text: root.exactVal
                        clip: true

                        Connections {
                            target: root
                            function onExactValChanged() {
                                if (!valInput.activeFocus) {
                                    valInput.text = root.exactVal;
                                }
                            }
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Enter value..."
                            color: Theme.primary
                            opacity: 0.5
                            visible: valInput.text === ""
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        onAccepted: {
                            root.saveValue(valInput.text);
                            valInput.focus = false;
                        }
                    }
                }

                Button {
                    id: saveBtn
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 38
                    hoverEnabled: true

                    contentItem: Text {
                        text: root.isSavedFeedback ? "Saved" : "Save"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: root.isSavedFeedback ? Theme.on_primary : Theme.primary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 8
                        color: root.isSavedFeedback 
                            ? Theme.primary 
                            : (saveBtn.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : "transparent")
                        border.color: Theme.primary
                        border.width: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.NoButton
                    }

                    onClicked: {
                        root.saveValue(valInput.text);
                        valInput.focus = false;
                    }
                }
            }

            // ========================================================
            // 3. DROPDOWN (ComboBox for choose / files / folders)
            // ========================================================
            ComboBox {
                id: combo
                anchors.fill: parent
                visible: root.setting && (root.setting.type === "choose" || root.setting.type === "files" || root.setting.type === "folders")
                model: root.dropdownOptions
                hoverEnabled: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.NoButton
                }

                onModelChanged: updateIndex()
                Connections {
                    target: root
                    function onExactValChanged() { combo.updateIndex() }
                    function onDropdownOptionsChanged() { combo.updateIndex() }
                }

                function updateIndex() {
                    if (root.exactVal && root.dropdownOptions && root.dropdownOptions.length > 0) {
                        var idx = root.dropdownOptions.indexOf(root.exactVal);
                        if (idx >= 0) {
                            combo.currentIndex = idx;
                        }
                    }
                }

                onActivated: function(index) {
                    var newVal = (root.dropdownOptions && index >= 0 && index < root.dropdownOptions.length)
                        ? root.dropdownOptions[index]
                        : combo.textAt(index);
                    root.saveValue(newVal);
                }

                background: Rectangle {
                    color: Theme.background
                    border.color: combo.activeFocus || combo.hovered ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.6)
                    radius: 8
                    border.width: 1
                }

                contentItem: Text {
                    text: {
                        if (combo.currentIndex >= 0 && root.dropdownOptions && combo.currentIndex < root.dropdownOptions.length) {
                            return root.dropdownOptions[combo.currentIndex];
                        }
                        if (root.exactVal && root.exactVal !== "") {
                            return root.exactVal;
                        }
                        return (root.setting && root.setting.default) ? root.setting.default : "Select...";
                    }
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
                    text: combo.popup.visible ? "▲" : "▼"
                    font.pixelSize: 10
                    color: Theme.primary
                }

                popup: Popup {
                    y: combo.height + 2
                    width: combo.width
                    implicitHeight: Math.min(260, Math.max(48, (root.dropdownOptions ? root.dropdownOptions.length * 36 : 0) + 16))
                    padding: 6

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: combo.popup.visible ? combo.delegateModel : null
                        currentIndex: combo.highlightedIndex
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
                    width: combo.width - 12
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
                        font.bold: combo.currentIndex === index
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                        rightPadding: 8
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        color: highlighted ? Theme.primary : (combo.currentIndex === index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
                        radius: 4
                    }
                    highlighted: combo.highlightedIndex === index
                }
            }
        }
    }
}
