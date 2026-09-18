import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
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
    implicitHeight: 600
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
            passwordNetwork = null
            passwordText = ""
            // Trigger Wi-Fi scan on open if device is available
            if (root.wifiDevice) {
                root.wifiDevice.scannerEnabled = true
            }
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
        target: "connectivity"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
        function isOpen(): bool { return root.isOpen }
        function openWifi(): void {
            root.currentTab = 0
            root.isOpen = true
        }
        function openBluetooth(): void {
            root.currentTab = 1
            root.isOpen = true
        }
        function toggleWifi(): void {
            if (root.isOpen && root.currentTab === 0) {
                root.isOpen = false
            } else {
                root.currentTab = 0
                root.isOpen = true
            }
        }
        function toggleBluetooth(): void {
            if (root.isOpen && root.currentTab === 1) {
                root.isOpen = false
            } else {
                root.currentTab = 1
                root.isOpen = true
            }
        }
    }

    // --- STATE & HELPER PROPERTIES ---
    property int currentTab: 0 // 0: Wi-Fi, 1: Bluetooth
    property var passwordNetwork: null
    property string passwordText: ""

    // Reactively track active WifiDevice
    property var wifiDevice: null

    Instantiator {
        model: Networking.devices
        delegate: QtObject {
            Component.onCompleted: {
                if (modelData.networks !== undefined) {
                    root.wifiDevice = modelData
                }
            }
        }
    }

    // Reactively track active connected Wi-Fi network
    property var connectedWifi: null

    Instantiator {
        model: root.wifiDevice ? root.wifiDevice.networks : null
        delegate: QtObject {
            readonly property bool isConn: modelData.connected
            onIsConnChanged: {
                if (isConn) root.connectedWifi = modelData
                else if (root.connectedWifi === modelData) root.connectedWifi = null
            }
            Component.onCompleted: {
                if (modelData.connected) root.connectedWifi = modelData
            }
        }
    }

    // Active default Bluetooth adapter
    readonly property var btAdapter: Bluetooth.defaultAdapter

    // Format Battery safely
    function formatBattery(b) {
        if (b === undefined || b === null || isNaN(b)) return "";
        let pct = (b <= 1.0) ? Math.round(b * 100) : Math.round(b);
        return pct + "%";
    }

    // Resolve Bluetooth device icon
    function getBtIcon(iconName) {
        if (!iconName) return "󰂯";
        let ic = iconName.toLowerCase();
        if (ic.includes("headset") || ic.includes("audio") || ic.includes("headphone")) return "󰋋";
        if (ic.includes("phone")) return "󰏲";
        if (ic.includes("gamepad") || ic.includes("gaming") || ic.includes("joystick")) return "󰊴";
        if (ic.includes("computer") || ic.includes("laptop")) return "󰌢";
        if (ic.includes("mouse") || ic.includes("keyboard")) return "󰌌";
        return "󰂯";
    }

    // --- REUSABLE DESIGN COMPONENTS ---
    component ML4WMenuItemButton: Button {
        id: control
        hoverEnabled: true
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.NoButton
        }
        background: Rectangle {
            color: control.down ? Theme.primary : (control.hovered ? Theme.primary_container : "transparent")
            border.color: Theme.primary
            border.width: 1
            radius: 6
        }
        contentItem: Text {
            text: control.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.bold: true
            color: control.down ? Theme.background : (control.hovered ? Theme.on_primary_container : Theme.primary)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            padding: 4
            leftPadding: 8
            rightPadding: 8
        }
    }

    component ML4WButton: Button {
        id: btnControl
        Layout.fillWidth: true
        hoverEnabled: true
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.NoButton
        }
        background: Rectangle {
            color: btnControl.down ? Theme.primary : (btnControl.hovered ? Theme.primary_container : "transparent")
            border.color: Theme.primary
            border.width: 1
            radius: 8
        }
        contentItem: Text {
            text: btnControl.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: true
            color: btnControl.down ? Theme.background : (btnControl.hovered ? Theme.on_primary_container : Theme.primary)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            padding: 6
        }
    }

    component ML4WSwitch: Switch {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 48
        implicitHeight: 26
        hoverEnabled: true
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.NoButton
        }
        indicator: Rectangle {
            implicitWidth: 48
            implicitHeight: 26
            radius: 13
            color: parent.checked ? Theme.primary : Theme.background
            border.color: Theme.primary
            border.width: 1
            Rectangle {
                x: parent.parent.checked ? parent.width - width - 2 : 2
                y: 2
                implicitWidth: 22
                implicitHeight: 22
                radius: 11
                color: parent.parent.checked ? Theme.background : Theme.on_primary
                Behavior on x { NumberAnimation { duration: 150 } }
            }
        }
    }

    component ActionIcon: Button {
        id: actBtn
        property string iconTxt: ""
        property string iconSrc: ""
        property bool animating: false
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
                id: iconTextItem
                anchors.centerIn: parent
                text: actBtn.iconTxt
                visible: actBtn.iconSrc === ""
                color: actBtn.hovered ? Theme.on_primary_container : Theme.primary
                font.family: "monospace"
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                transformOrigin: Item.Center

                NumberAnimation on rotation {
                    running: actBtn.animating
                    from: 0
                    to: 360
                    duration: 1200
                    loops: Animation.Infinite
                }
            }
            Connections {
                target: actBtn
                function onAnimatingChanged() {
                    if (!actBtn.animating) {
                        iconTextItem.rotation = 0
                    }
                }
            }
            Image {
                anchors.centerIn: parent
                source: actBtn.iconSrc
                width: 18
                height: 18
                sourceSize.width: 18
                sourceSize.height: 18
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

    component SignalBars: Row {
        property real strength: 0.0
        property color activeColor: Theme.primary
        spacing: 2
        Layout.alignment: Qt.AlignVCenter
        Repeater {
            model: 4
            Rectangle {
                width: 3
                height: (index + 1) * 3 + 2
                radius: 1
                anchors.bottom: parent.bottom
                color: (strength >= (index + 1) * 0.25 - 0.1) ? activeColor : Theme.outline_variant
                opacity: (strength >= (index + 1) * 0.25 - 0.1) ? 1.0 : 0.35
            }
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
            }
        }

        // ==========================================
        // CONTENT LAYOUT
        // ==========================================
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // --- HEADER & TOOLBAR ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: root.currentTab === 0 ? "󰖩" : "󰂯"
                    color: Theme.primary
                    font.family: "monospace"
                    font.pixelSize: 20
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: root.currentTab === 0 ? "Wi-Fi Connections" : "Bluetooth Devices"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Fallback action button: nm-connection-editor
                ActionIcon {
                    iconTxt: "󱛄"
                    ToolTip.visible: hovered
                    ToolTip.text: "Network Settings"
                    onClicked: {
                        root.isOpen = false
                        Quickshell.execDetached(["nm-connection-editor"])
                    }
                }

                // Fallback action button: blueman-manager
                ActionIcon {
                    iconTxt: "󰂱"
                    ToolTip.visible: hovered
                    ToolTip.text: "Bluetooth Manager"
                    onClicked: {
                        root.isOpen = false
                        Quickshell.execDetached(["blueman-manager"])
                    }
                }
            }

            // --- SEGMENTED 2-TAB SWITCHER (Wi-Fi & Bluetooth only) ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: ["Wi-Fi", "Bluetooth"]
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: 6
                        color: root.currentTab === index ? Theme.primary : "transparent"
                        border.color: Theme.primary
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: index === 0 ? "󰖩" : "󰂯"
                                font.family: "monospace"
                                font.pixelSize: 14
                                color: root.currentTab === index ? Theme.background : Theme.primary
                            }

                            Text {
                                text: modelData
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                color: root.currentTab === index ? Theme.background : Theme.primary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = index
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.3 }

            // --- SCROLLABLE MAIN CONTENT ---
            ScrollView {
                id: mainScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    interactive: true
                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: Theme.primary
                        opacity: parent.pressed ? 1.0 : (parent.active ? 0.8 : 0.4)
                    }
                }

                ColumnLayout {
                    width: mainScroll.availableWidth
                    spacing: 16

                    // ==========================================
                    // 1. WI-FI SECTION (Tab 0)
                    // ==========================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: root.currentTab === 0

                        // Section Header + Master Switch
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "Wi-Fi Adapter"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: Networking.wifiEnabled ? "Enabled" : "Disabled"
                                color: Theme.primary
                                opacity: 0.7
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }

                            ML4WSwitch {
                                checked: Networking.wifiEnabled
                                onClicked: Networking.wifiEnabled = checked
                            }
                        }

                        // Wi-Fi Disabled State
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 60
                            radius: 8
                            color: Theme.surface_container ? Theme.surface_container : Theme.background
                            border.color: Theme.outline ? Theme.outline : Theme.primary
                            border.width: 1
                            visible: !Networking.wifiEnabled

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 10
                                Text { text: "󰖪"; color: Theme.primary; font.family: "monospace"; font.pixelSize: 22 }
                                Text { text: "Wi-Fi is currently turned off"; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 14 }
                            }
                        }

                        // Wi-Fi Enabled: Connected Card
                        Rectangle {
                            id: connectedCard
                            Layout.fillWidth: true
                            implicitHeight: connectedCol.implicitHeight + 20
                            radius: 10
                            color: Theme.background
                            border.color: Theme.primary
                            border.width: 1.5
                            visible: Networking.wifiEnabled && root.connectedWifi !== null

                            ColumnLayout {
                                id: connectedCol
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    // Active Status Indicator Pill (Theme dynamic)
                                    Rectangle {
                                        implicitWidth: 10
                                        implicitHeight: 10
                                        radius: 5
                                        color: Theme.primary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: root.connectedWifi ? root.connectedWifi.name : ""
                                            color: Theme.primary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 15
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "Connected & Active"
                                            color: Theme.primary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    SignalBars {
                                        strength: root.connectedWifi ? root.connectedWifi.signalStrength : 0
                                        activeColor: Theme.primary
                                    }

                                    ML4WMenuItemButton {
                                        text: "Disconnect"
                                        onClicked: {
                                            if (root.connectedWifi) root.connectedWifi.disconnect()
                                        }
                                    }
                                }
                            }
                        }

                        // Available Networks Header & Rescan
                        RowLayout {
                            Layout.fillWidth: true
                            visible: Networking.wifiEnabled
                            spacing: 8

                            Text {
                                text: "Available Networks"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                opacity: 0.85
                            }

                            Item { Layout.fillWidth: true }

                            ActionIcon {
                                iconTxt: "󰑐"
                                animating: Boolean(root.wifiDevice && root.wifiDevice.scannerEnabled)
                                ToolTip.visible: hovered
                                ToolTip.text: (root.wifiDevice && root.wifiDevice.scannerEnabled) ? "Scanning Networks..." : "Scan Networks"
                                onClicked: {
                                    if (root.wifiDevice) {
                                        root.wifiDevice.scannerEnabled = true
                                    }
                                }
                            }
                        }

                        // Inline Password Prompt Card
                        Rectangle {
                            id: passwordPromptCard
                            Layout.fillWidth: true
                            implicitHeight: pwdCol.implicitHeight + 16
                            radius: 8
                            color: Theme.surface_container ? Theme.surface_container : Theme.background
                            border.color: Theme.primary
                            border.width: 1
                            visible: Networking.wifiEnabled && root.passwordNetwork !== null

                            ColumnLayout {
                                id: pwdCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                Text {
                                    text: "Connect to \"" + (root.passwordNetwork ? root.passwordNetwork.name : "") + "\""
                                    color: Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                TextField {
                                    id: pwdInput
                                    Layout.fillWidth: true
                                    placeholderText: "Enter Wi-Fi Passphrase"
                                    echoMode: TextInput.Password
                                    color: Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    padding: 8

                                    background: Rectangle {
                                        color: Theme.background
                                        border.color: Theme.primary
                                        border.width: 1
                                        radius: 6
                                    }

                                    onAccepted: {
                                        if (root.passwordNetwork && text.length > 0) {
                                            root.passwordNetwork.connectWithPsk(text)
                                            root.passwordNetwork = null
                                            text = ""
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    ML4WMenuItemButton {
                                        text: "Cancel"
                                        onClicked: {
                                            root.passwordNetwork = null
                                            pwdInput.text = ""
                                        }
                                    }

                                    ML4WMenuItemButton {
                                        text: "Connect"
                                        onClicked: {
                                            if (root.passwordNetwork && pwdInput.text.length > 0) {
                                                root.passwordNetwork.connectWithPsk(pwdInput.text)
                                                root.passwordNetwork = null
                                                pwdInput.text = ""
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Available Networks ListView
                        ListView {
                            id: wifiList
                            Layout.fillWidth: true
                            implicitHeight: Math.min(320, contentHeight)
                            clip: true
                            spacing: 4
                            visible: Networking.wifiEnabled

                            model: root.wifiDevice ? root.wifiDevice.networks : null

                            delegate: Rectangle {
                                id: wifiRow
                                property var net: modelData
                                width: wifiList.width
                                implicitHeight: 40
                                radius: 6
                                color: rowMouse.containsMouse ? (Theme.surface_container ? Theme.surface_container : Theme.primary_container) : "transparent"

                                visible: Boolean(net && net !== root.connectedWifi && net.name)
                                height: visible ? implicitHeight : 0

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    // Lock / Open Icon
                                    Text {
                                        text: (net && net.security !== 10) ? "󰌾" : "󰌿"
                                        color: Theme.primary
                                        font.family: "monospace"
                                        font.pixelSize: 14
                                        opacity: 0.7
                                    }

                                    Text {
                                        text: net ? (net.name || "") : ""
                                        color: Theme.primary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    SignalBars {
                                        strength: net ? (net.signalStrength || 0) : 0
                                    }

                                    Item {
                                        id: rowSpinnerItem
                                        implicitWidth: 16
                                        implicitHeight: 16
                                        visible: Boolean(net && (net.stateChanging || (net.state !== undefined && net.state === ConnectionState.Connecting)))

                                        Text {
                                            id: rowSpinnerText
                                            anchors.centerIn: parent
                                            text: "󰑐"
                                            color: Theme.primary
                                            font.family: "monospace"
                                            font.pixelSize: 14
                                            transformOrigin: Item.Center

                                            NumberAnimation on rotation {
                                                running: rowSpinnerItem.visible
                                                from: 0
                                                to: 360
                                                duration: 1000
                                                loops: Animation.Infinite
                                            }
                                        }

                                        Connections {
                                            target: rowSpinnerItem
                                            function onVisibleChanged() {
                                                if (!rowSpinnerItem.visible) {
                                                    rowSpinnerText.rotation = 0
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!net) return
                                        if (net.known || net.security === 10) {
                                            net.connect()
                                        } else {
                                            root.passwordNetwork = net
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ==========================================
                    // 2. BLUETOOTH SECTION (Tab 1)
                    // ==========================================
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: root.currentTab === 1

                        // Section Header + Master Switch
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "Bluetooth Adapter"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: (root.btAdapter && root.btAdapter.enabled) ? "Enabled" : "Disabled"
                                color: Theme.primary
                                opacity: 0.7
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }

                            ML4WSwitch {
                                checked: root.btAdapter ? root.btAdapter.enabled : false
                                onClicked: {
                                    if (root.btAdapter) root.btAdapter.enabled = checked
                                }
                            }
                        }

                        // Bluetooth Disabled State
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 60
                            radius: 8
                            color: Theme.surface_container ? Theme.surface_container : Theme.background
                            border.color: Theme.outline ? Theme.outline : Theme.primary
                            border.width: 1
                            visible: !root.btAdapter || !root.btAdapter.enabled

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 10
                                Text { text: "󰂲"; color: Theme.primary; font.family: "monospace"; font.pixelSize: 22 }
                                Text { text: "Bluetooth is currently turned off"; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 14 }
                            }
                        }

                        // Bluetooth Enabled: Discovery / Devices Header
                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.btAdapter && root.btAdapter.enabled
                            spacing: 8

                            Text {
                                text: "Paired & Discovered Devices"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                opacity: 0.85
                            }

                            Item { Layout.fillWidth: true }

                            ActionIcon {
                                iconTxt: (root.btAdapter && root.btAdapter.discovering) ? "󰑐" : "󰍉"
                                animating: Boolean(root.btAdapter && root.btAdapter.discovering)
                                ToolTip.visible: hovered
                                ToolTip.text: (root.btAdapter && root.btAdapter.discovering) ? "Stop Scan" : "Scan Devices"
                                onClicked: {
                                    if (root.btAdapter) {
                                        root.btAdapter.discovering = !root.btAdapter.discovering
                                    }
                                }
                            }
                        }

                        // Bluetooth Devices ListView
                        ListView {
                            id: btList
                            Layout.fillWidth: true
                            implicitHeight: Math.min(340, contentHeight)
                            clip: true
                            spacing: 6
                            visible: root.btAdapter && root.btAdapter.enabled

                            model: root.btAdapter ? root.btAdapter.devices : null

                            delegate: Rectangle {
                                id: btCard
                                property var dev: modelData
                                width: btList.width
                                implicitHeight: 46
                                radius: 8
                                color: dev.connected ? (Theme.surface_container ? Theme.surface_container : Theme.background) : "transparent"
                                border.color: dev.connected ? Theme.primary : (Theme.outline ? Theme.outline : Theme.primary)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    // Device Type Icon
                                    Text {
                                        text: root.getBtIcon(dev.icon)
                                        color: dev.connected ? Theme.primary : Theme.primary
                                        font.family: "monospace"
                                        font.pixelSize: 16
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: dev.name ? dev.name : (dev.deviceName ? dev.deviceName : dev.address)
                                            color: Theme.primary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        RowLayout {
                                            spacing: 6
                                            Text {
                                                text: dev.connected ? "Connected" : (dev.paired ? "Paired" : "Discovered")
                                                color: dev.connected ? Theme.primary : Theme.on_background
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                opacity: 0.75
                                            }

                                            // Battery Badge
                                            RowLayout {
                                                visible: dev.batteryAvailable
                                                spacing: 2
                                                Text { text: "󰁹"; color: Theme.primary; font.family: "monospace"; font.pixelSize: 11 }
                                                Text {
                                                    text: root.formatBattery(dev.battery)
                                                    color: Theme.primary
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                }
                                            }
                                        }
                                    }

                                    // Connect / Disconnect Action Button
                                    ML4WMenuItemButton {
                                        text: dev.connected ? "Disconnect" : "Connect"
                                        onClicked: {
                                            if (dev.connected) {
                                                dev.disconnect()
                                            } else {
                                                dev.connect()
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
}
