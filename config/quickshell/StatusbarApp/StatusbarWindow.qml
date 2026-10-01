import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.CustomTheme

PanelWindow {
    id: root

    // --- WAYLAND & LAYER-SHELL CONFIGURATION ---
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: root.barEnabled ? root.reservedHeight : 0

    // Grabs the keyboard for the bar while focused so SUPER + SPACE can
    // drive Left/Right/Return navigation across the HUD capsules.
    HyprlandFocusGrab {
        windows: [root]
        active: root.barExpanded
        onCleared: root.barExpanded = false
    }

    // --- USER SETTINGS ---
    readonly property var defaultSettings: ({
        "bar":    { "height": 38, "reservedHeight": 50, "enabled": true, "alwaysExpanded": true },
        "border": { "width": 1.0, "colorTop": "", "colorBottom": "" },
        "clock":  { "format": "HH:mm", "dateFormat": "ddd, dd MMM" },
        "workspaces": { "count": 5 }
    })

    property var settings: defaultSettings
    property bool overrideExists: false

    FileView {
        id: overrideFile
        path: Quickshell.env("HOME") + "/.config/ml4w-statusbar/statusbar.json"
        blockLoading: true
        printErrors: false
        onLoaded: { root.overrideExists = true; root.applySettings() }
        onLoadFailed: { root.overrideExists = false; root.applySettings() }
    }

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/ml4w/settings/statusbar.json"
        blockLoading: true
        onLoaded: root.applySettings()
    }

    function masterFile() {
        return root.overrideExists ? overrideFile : settingsFile
    }

    function reloadSettings(): void {
        overrideFile.reload()
        settingsFile.reload()
        applySettings()
    }

    function parseSettings(src) {
        if (!src) return undefined
        let raw = src.replace(/\/\*[\s\S]*?\*\//g, "")
        if (raw.trim() === "") return undefined
        try {
            return JSON.parse(raw)
        } catch (e) {
            try {
                return JSON.parse(raw.replace(/,(\s*[}\]])/g, "$1"))
            } catch (e2) {
                console.warn("statusbar settings parse error:", e2)
                return undefined
            }
        }
    }

    function mergeSettings(merged, src): void {
        let parsed = parseSettings(src)
        if (parsed === undefined) return
        for (let group in parsed)
            for (let key in parsed[group])
                if (merged[group] !== undefined)
                    merged[group][key] = parsed[group][key]
    }

    function applySettings(masterText): void {
        let merged = JSON.parse(JSON.stringify(root.defaultSettings))
        let text = (masterText !== undefined) ? masterText : root.masterFile().text()
        mergeSettings(merged, text)
        root.settings = merged
    }

    function persistBarFlag(key, on): string {
        let file = root.masterFile()
        let src = file.text()
        let re = new RegExp('("' + key + '"\\s*:\\s*)(true|false)')
        let updated
        if (re.test(src)) {
            updated = src.replace(re, "$1" + (on ? "true" : "false"))
        } else {
            let obj = root.parseSettings(src)
            if (obj === undefined && src && src.trim() !== "") {
                return src
            }
            if (typeof obj !== "object" || obj === null) obj = {}
            if (obj.bar === undefined) obj.bar = {}
            obj.bar[key] = on
            updated = JSON.stringify(obj, null, 4) + "\n"
        }
        file.setText(updated)
        return updated
    }

    property int barHeight: settings.bar.height
    property int reservedHeight: settings.bar.reservedHeight
    property bool barEnabled: settings.bar.enabled

    visible: barEnabled
    exclusiveZone: barEnabled ? reservedHeight : 0

    function setEnabled(on: bool): void {
        applySettings(persistBarFlag("enabled", on))
    }

    property bool barExpanded: false
    property bool alwaysExpanded: settings.bar.alwaysExpanded

    function setAlwaysExpanded(on: bool): void {
        applySettings(persistBarFlag("alwaysExpanded", on))
    }

    // --- MODULE COMPONENTS ---
    Component { id: cTerminal;     TerminalModule {} }
    Component { id: cClipboard;    ClipboardModule {} }
    Component {
        id: cWorkspaces
        WorkspacesModule {
            minWorkspaces: root.settings.workspaces.count
        }
    }
    Component { id: cLauncher;     LauncherModule {} }
    Component {
        id: cClock
        ClockModule {
            timeFormat: root.settings.clock.format
            dateFormat: root.settings.clock.dateFormat
        }
    }
    Component { id: cSwaync;       SwayncModule {} }
    Component { id: cMedia;        MediaModule {} }
    Component { id: cUpdates;      UpdatesModule { onCollapsedChanged: Qt.callLater(root.rebuildNavItems) } }
    Component { id: cBattery;      BatteryModule { onCollapsedChanged: Qt.callLater(root.rebuildNavItems) } }
    Component { id: cPowerProfile; PowerProfileModule {} }
    Component { id: cVolume;       VolumeModule {} }
    Component {
        id: cSystemTray
        SystemTrayModule {
            onCollapsedChanged: Qt.callLater(root.rebuildNavItems)
            Binding {
                target: root
                property: "trayMenuOpen"
                value: menuOpen
            }
        }
    }
    Component { id: cLogo;         Ml4wLogoModule {} }
    Component { id: cPower;        PowerModule {} }

    property bool trayMenuOpen: false

    // --- KEYBOARD NAVIGATION ---
    property var navItems: []
    property int focusIndex: -1
    property var workspacesRef: null

    Connections {
        target: root.workspacesRef
        ignoreUnknownSignals: true
        function onNavButtonsChanged(): void { root.rebuildNavItems() }
    }

    function collectFromRow(row, items) {
        if (!row) return;
        for (let i = 0; i < row.children.length; i++) {
            let child = row.children[i];
            if (!child || !child.visible) continue;
            let m = (child.item !== undefined) ? child.item : child;
            if (!m || m.collapsed === true) continue;
            if (m.navButtons !== undefined) {
                root.workspacesRef = m;
                for (let b = 0; b < m.navButtons.length; b++) {
                    items.push(m.navButtons[b]);
                }
            } else if (typeof m.activate === "function") {
                items.push(m);
            }
        }
    }

    function rebuildNavItems(): void {
        let items = []
        root.workspacesRef = null
        collectFromRow(leftRow, items)
        collectFromRow(centerRow, items)
        collectFromRow(rightRow, items)
        root.navItems = items
    }

    Component.onCompleted: Qt.callLater(rebuildNavItems)
    onSettingsChanged: Qt.callLater(rebuildNavItems)

    function applyFocus(): void {
        let items = root.navItems
        for (let i = 0; i < items.length; i++)
            items[i].focused = (i === root.focusIndex)
    }

    onFocusIndexChanged: applyFocus()
    onNavItemsChanged: {
        if (root.focusIndex >= root.navItems.length)
            root.focusIndex = root.navItems.length - 1
        applyFocus()
    }

    onBarExpandedChanged: {
        if (barExpanded) {
            focusIndex = 0
            keyHandler.forceActiveFocus()
        } else {
            focusIndex = -1
        }
    }

    function moveFocus(dir: int): void {
        if (!barExpanded) return
        let n = root.navItems.length
        if (n === 0) return
        root.focusIndex = (root.focusIndex + dir + n) % n
    }

    function stepFocused(dir: int): void {
        if (root.focusIndex < 0 || root.focusIndex >= root.navItems.length) return
        let m = root.navItems[root.focusIndex]
        if (typeof m.step === "function") m.step(dir)
    }

    function activateFocused(): void {
        if (root.focusIndex >= 0 && root.focusIndex < root.navItems.length)
            root.navItems[root.focusIndex].activate()
        root.barExpanded = false
    }

    IpcHandler {
        target: "statusbar"
        function toggle(): void { root.setEnabled(!root.settings.bar.enabled) }
        function enable(): void { root.setEnabled(true) }
        function disable(): void { root.setEnabled(false) }
        function alwaysExpand(): void { root.setAlwaysExpanded(true) }
        function autoCollapse(): void { root.setAlwaysExpanded(false) }
        function refresh(): void { root.reloadSettings() }
        function focus(): void {
            if (root.barExpanded) {
                root.barExpanded = false
            } else {
                root.barExpanded = true
                keyHandler.forceActiveFocus()
            }
        }
        function expand(): void { root.barExpanded = true }
        function collapse(): void { root.barExpanded = false }
        function reload(): void { root.reloadSettings() }
    }

    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 0
    }

    implicitHeight: barHeight + 16

    FocusScope {
        id: keyHandler
        anchors.fill: parent
        focus: root.barExpanded
        Keys.onLeftPressed: root.moveFocus(-1)
        Keys.onRightPressed: root.moveFocus(1)
        Keys.onTabPressed: root.moveFocus(1)
        Keys.onBacktabPressed: root.moveFocus(-1)
        Keys.onUpPressed: root.stepFocused(1)
        Keys.onDownPressed: root.stepFocused(-1)
        Keys.onReturnPressed: root.activateFocused()
        Keys.onEnterPressed: root.activateFocused()
        Keys.onEscapePressed: root.barExpanded = false
    }

    // =========================================================================
    // 1. LEFT FLOATING GLASS CAPSULE (Workspaces, Terminal & Media HUD)
    // =========================================================================
    GlassCapsule {
        id: leftCapsule
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 6
        height: root.barHeight
        customRadius: 14
        width: leftRow.implicitWidth + 20

        Behavior on width {
            NumberAnimation { duration: 320; easing.type: Easing.OutQuint }
        }

        RowLayout {
            id: leftRow
            anchors.centerIn: parent
            spacing: 8

            Loader {
                id: wsLoader
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cWorkspaces
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 16
                color: Theme.outline_variant
                opacity: 0.35
            }

            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cTerminal
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }

            // Divider separating terminal from media (only when media is playing)
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 16
                color: Theme.outline_variant
                opacity: 0.35
                visible: mediaLoader.item && !mediaLoader.item.collapsed
            }

            // Media Player + CAVA Section (moved to the left next to terminal)
            Loader {
                id: mediaLoader
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cMedia
                visible: item && !item.collapsed
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }
        }
    }

    // =========================================================================
    // 2. CENTER FLOATING GLASS CAPSULE (Launcher, Clock & Notification Center)
    // =========================================================================
    GlassCapsule {
        id: centerCapsule
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 6
        height: root.barHeight
        customRadius: 14
        width: centerRow.implicitWidth + 24

        Behavior on width {
            NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
        }

        RowLayout {
            id: centerRow
            anchors.centerIn: parent
            spacing: 8

            // Application Launcher (moved to the clock pill)
            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cLauncher
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 16
                color: Theme.outline_variant
                opacity: 0.35
            }

            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cClock
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 16
                color: Theme.outline_variant
                opacity: 0.35
            }

            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cSwaync
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }
        }
    }

    // =========================================================================
    // 3. RIGHT FLOATING GLASS CAPSULE (System Status & Controls HUD)
    // =========================================================================
    GlassCapsule {
        id: rightCapsule
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 6
        height: root.barHeight
        customRadius: 14
        width: rightRow.implicitWidth + 20

        Behavior on width {
            NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
        }

        RowLayout {
            id: rightRow
            anchors.centerIn: parent
            spacing: 8

            // Updates Module
            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cUpdates
                visible: item && !item.collapsed
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }

            // Clipboard History Module
            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cClipboard
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }

            // Battery Module
            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cBattery
                visible: item && !item.collapsed
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }

            // Power Profile Module
            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cPowerProfile
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }

            // Volume Module
            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cVolume
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }

            // System Tray Module
            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cSystemTray
                visible: item && !item.collapsed
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }

            // Divider before branding & power
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 16
                color: Theme.outline_variant
                opacity: 0.35
            }

            // ML4W Logo Module
            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cLogo
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }

            // Power Module
            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: cPower
                onLoaded: Qt.callLater(root.rebuildNavItems)
            }
        }
    }
}
