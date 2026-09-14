import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import qs.CustomTheme

PanelWindow {
    id: root

    // --- WAYLAND CONFIGURATION ---
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: WlrLayershell.Ignore

    color: "transparent"

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // --- CLICK OUTSIDE TO CLOSE ---
    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen
        onCleared: {
            if (root.isOpen) {
                root.isOpen = false;
            }
        }
    }

    // --- KEYBOARD SHORTCUTS ---
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.isOpen) {
                root.isOpen = false;
            }
        }
    }

    Shortcut {
        sequences: ["Super+Q", "Meta+Q", "Super+W", "Meta+W", "Alt+F4", "Ctrl+Q", "Ctrl+W"]
        onActivated: {
            if (root.isOpen) {
                root.isOpen = false;
            }
        }
    }

    // --- VISIBILITY & ANIMATION ---
    property bool isOpen: false
    visible: isOpen || modalFadeAnim.running

    onIsOpenChanged: {
        if (isOpen) {
            modalWrapper.x = 0;
            modalWrapper.y = 0;
            refreshStatus();
            loadFavorites();
            loadRecents();
            loadWallpapers();
            checkThemeMode();
            checkWorkshopSignature();
        }
    }

    // --- IPC HANDLER ---
    IpcHandler {
        target: "wallpaper-engine"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
        function refresh(): void {
            root.currentWorkshopSignature = "";
            root.loadWallpapers();
            root.loadFavorites();
            root.loadRecents();
            root.refreshStatus();
            root.checkWorkshopSignature();
        }
        function isOpen(): bool { return root.isOpen }
    }

    // --- STATE PROPERTIES ---
    property int currentTab: 0 // 0: Wallpapers, 1: Theme Sync
    property var allWallpapers: []
    property var filteredWallpapers: []
    property var favoritesList: []
    property var recentsList: []
    property var selectedWallpaper: null
    property var engineState: ({ "running": false, "mode": "static", "id": "", "title": "", "monitor": "all", "fps": 10 })
    property bool isDarkTheme: true
    property string selectedMonitor: "all"
    property int selectedFps: 10
    property bool isPreviewing: false
    property string currentWorkshopSignature: ""
    property bool isSyncing: false

    // Filter & Search State
    property string searchQuery: ""
    property string selectedFilter: "all" // "all", "scene", "video", "web", "favorites", "recent"
    property string selectedSort: "name_asc" // "name_asc", "name_desc", "recent"

    // Display Monitor Options
    property var monitorModel: {
        let list = [{"name": "all", "label": "All Displays"}];
        if (Hyprland && Hyprland.monitors && Hyprland.monitors.values) {
            for (let i = 0; i < Hyprland.monitors.values.length; i++) {
                let m = Hyprland.monitors.values[i];
                list.push({"name": m.name, "label": m.name + " (" + m.width + "x" + m.height + "@" + Math.round(m.refreshRate) + "Hz)"});
            }
        }
        return list;
    }

    // --- FILTER & SEARCH LOGIC ---
    function updateFilteredWallpapers() {
        let list = root.allWallpapers || [];
        let q = root.searchQuery.trim().toLowerCase();
        let filter = root.selectedFilter;
        let favs = root.favoritesList || [];
        let recents = root.recentsList || [];

        let res = [];
        for (let i = 0; i < list.length; i++) {
            let item = list[i];
            if (!item || item.supported === false || item.supported === "false") continue;

            let idStr = (item.id || "").toString().toLowerCase();
            let titleStr = (item.title || "").toLowerCase();
            let typeStr = (item.type || "").toLowerCase();
            let descStr = (item.description || "").toLowerCase();
            let isFav = (favs.indexOf(item.id) !== -1) || (item.is_favorite === true);
            let isRec = (recents.indexOf(item.id) !== -1);

            // Filter check
            if (filter === "favorites" && !isFav) continue;
            if (filter === "recent" && !isRec) continue;
            if (filter === "scene" && typeStr !== "scene" && typeStr !== "preset") continue;
            if (filter === "video" && typeStr !== "video") continue;
            if (filter === "web" && typeStr !== "web" && typeStr !== "application") continue;

            // Search query check
            if (q !== "") {
                let matches = (titleStr.indexOf(q) !== -1) ||
                              (idStr.indexOf(q) !== -1) ||
                              (typeStr.indexOf(q) !== -1) ||
                              (descStr.indexOf(q) !== -1);
                if (!matches && item.tags && Array.isArray(item.tags)) {
                    for (let t = 0; t < item.tags.length; t++) {
                        if (String(item.tags[t]).toLowerCase().indexOf(q) !== -1) {
                            matches = true;
                            break;
                        }
                    }
                }
                if (!matches) continue;
            }

            res.push(item);
        }

        // Sorting
        if (root.selectedSort === "name_asc") {
            res.sort(function(a, b) {
                return (a.title || "").localeCompare(b.title || "");
            });
        } else if (root.selectedSort === "name_desc") {
            res.sort(function(a, b) {
                return (b.title || "").localeCompare(a.title || "");
            });
        } else if (root.selectedSort === "recent") {
            res.sort(function(a, b) {
                let idxA = recents.indexOf(a.id);
                let idxB = recents.indexOf(b.id);
                if (idxA === -1 && idxB === -1) return (a.title || "").localeCompare(b.title || "");
                if (idxA === -1) return 1;
                if (idxB === -1) return -1;
                return idxA - idxB;
            });
        }

        root.filteredWallpapers = res;

        // Maintain or update selected wallpaper
        if (res.length > 0) {
            let found = false;
            if (root.selectedWallpaper) {
                for (let k = 0; k < res.length; k++) {
                    if (res[k].id === root.selectedWallpaper.id) {
                        root.selectedWallpaper = res[k];
                        found = true;
                        break;
                    }
                }
            }
            if (!found) {
                let activeId = root.engineState.running ? root.engineState.id : "";
                let activeItem = null;
                if (activeId) {
                    for (let m = 0; m < res.length; m++) {
                        if (res[m].id === activeId) {
                            activeItem = res[m];
                            break;
                        }
                    }
                }
                root.selectedWallpaper = activeItem ? activeItem : res[0];
            }
        } else {
            root.selectedWallpaper = null;
        }
    }

    function getFilterCount(filterType) {
        let list = root.allWallpapers || [];
        let favs = root.favoritesList || [];
        let recents = root.recentsList || [];
        let count = 0;
        for (let i = 0; i < list.length; i++) {
            let item = list[i];
            if (!item || item.supported === false || item.supported === "false") continue;
            let typeStr = (item.type || "").toLowerCase();
            let isFav = (favs.indexOf(item.id) !== -1) || (item.is_favorite === true);
            let isRec = (recents.indexOf(item.id) !== -1);

            if (filterType === "all") count++;
            else if (filterType === "scene" && (typeStr === "scene" || typeStr === "preset")) count++;
            else if (filterType === "video" && typeStr === "video") count++;
            else if (filterType === "web" && (typeStr === "web" || typeStr === "application")) count++;
            else if (filterType === "favorites" && isFav) count++;
            else if (filterType === "recent" && isRec) count++;
        }
        return count;
    }

    function isWallpaperFavorite(wpId) {
        if (!wpId) return false;
        return (root.favoritesList.indexOf(wpId) !== -1);
    }

    function toggleFavorite(wpId) {
        if (!wpId) return;
        let favs = root.favoritesList.slice();
        let idx = favs.indexOf(wpId);
        if (idx !== -1) {
            favs.splice(idx, 1);
        } else {
            favs.push(wpId);
        }
        root.favoritesList = favs;

        for (let i = 0; i < root.allWallpapers.length; i++) {
            if (root.allWallpapers[i].id === wpId) {
                root.allWallpapers[i].is_favorite = (idx === -1);
                break;
            }
        }

        favToggleProcess.command = ["jeme-wallpaper-engine", "favorites", "toggle", wpId];
        favToggleProcess.running = false;
        favToggleProcess.running = true;

        root.updateFilteredWallpapers();
    }

    // --- BACKEND PROCESS CALLS ---
    function loadWallpapers() {
        root.isSyncing = true;
        listProcess.running = false;
        listProcess.running = true;
    }

    function checkWorkshopSignature() {
        if (!signatureProcess.running && !listProcess.running) {
            signatureProcess.running = false;
            signatureProcess.running = true;
        }
    }

    Timer {
        id: syncCheckTimer
        interval: 1500
        running: root.isOpen
        repeat: true
        onTriggered: {
            root.checkWorkshopSignature();
        }
    }

    function loadFavorites() {
        favoritesProcess.running = false;
        favoritesProcess.running = true;
    }

    function loadRecents() {
        recentsProcess.running = false;
        recentsProcess.running = true;
    }

    function refreshStatus() {
        statusProcess.running = false;
        statusProcess.running = true;
    }

    function checkThemeMode() {
        themeCheckProcess.running = false;
        themeCheckProcess.running = true;
    }

    function applySelectedWallpaper(withTheme) {
        if (!selectedWallpaper) return;
        let mon = monitorComboBox.currentValue ? monitorComboBox.currentValue.name : "all";
        let fps = selectedFps;

        if (withTheme) {
            themeApplyProcess.command = ["jeme-wallpaper-engine", "apply-theme", selectedWallpaper.id];
            themeApplyProcess.running = false;
            themeApplyProcess.running = true;
        }

        let cmd = ["jeme-wallpaper-engine", "start", selectedWallpaper.id, "--fps", fps.toString()];
        if (mon && mon !== "all") {
            cmd.push("--monitor", mon);
        }
        startProcess.command = cmd;
        startProcess.running = false;
        startProcess.running = true;
        root.isPreviewing = false;

        let rec = root.recentsList.slice();
        let idx = rec.indexOf(selectedWallpaper.id);
        if (idx !== -1) rec.splice(idx, 1);
        rec.unshift(selectedWallpaper.id);
        root.recentsList = rec;
    }

    function togglePreviewSelected() {
        if (!selectedWallpaper) return;
        if (root.isPreviewing) {
            stopProcess.running = false;
            stopProcess.running = true;
            root.isPreviewing = false;
        } else {
            let mon = monitorComboBox.currentValue ? monitorComboBox.currentValue.name : "all";
            let fps = selectedFps;
            let cmd = ["jeme-wallpaper-engine", "preview", selectedWallpaper.id, "--fps", fps.toString()];
            if (mon && mon !== "all") {
                cmd.push("--monitor", mon);
            }
            startProcess.command = cmd;
            startProcess.running = false;
            startProcess.running = true;
            root.isPreviewing = true;
        }
    }

    function changeFps(fpsVal) {
        root.selectedFps = fpsVal;
        if (root.engineState.running) {
            fpsProcess.command = ["jeme-wallpaper-engine", "set-fps", fpsVal.toString()];
            fpsProcess.running = false;
            fpsProcess.running = true;
        }
    }

    function stopWallpaperEngine() {
        stopProcess.running = false;
        stopProcess.running = true;
        root.isPreviewing = false;
    }

    Process {
        id: signatureProcess
        command: ["jeme-wallpaper-engine", "sync-signature"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let raw = this.text.trim();
                    if (!raw) return;
                    let data = JSON.parse(raw);
                    let sig = data.signature || "";
                    if (sig) {
                        if (root.currentWorkshopSignature !== "" && root.currentWorkshopSignature !== sig) {
                            root.currentWorkshopSignature = sig;
                            root.loadWallpapers();
                            root.refreshStatus();
                        } else if (root.currentWorkshopSignature === "") {
                            root.currentWorkshopSignature = sig;
                        }
                    }
                } catch(e) {
                }
            }
        }
    }

    Process {
        id: listProcess
        command: ["jeme-wallpaper-engine", "rescan"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isSyncing = false;
                try {
                    let data = JSON.parse(this.text.trim());
                    let supportedList = [];
                    for (let i = 0; i < data.length; i++) {
                        if (data[i] && data[i].supported !== false && data[i].supported !== "false") {
                            supportedList.push(data[i]);
                        }
                    }
                    root.allWallpapers = supportedList;
                    root.updateFilteredWallpapers();
                } catch(e) {
                    console.log("Error parsing wallpaper list JSON:", e);
                }
            }
        }
    }

    Process {
        id: favoritesProcess
        command: ["jeme-wallpaper-engine", "favorites", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    if (Array.isArray(data)) {
                        root.favoritesList = data;
                        root.updateFilteredWallpapers();
                    }
                } catch(e) {
                    console.log("Error parsing favorites JSON:", e);
                }
            }
        }
    }

    Process {
        id: recentsProcess
        command: ["jeme-wallpaper-engine", "recents", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    if (Array.isArray(data)) {
                        root.recentsList = data;
                        root.updateFilteredWallpapers();
                    }
                } catch(e) {
                    console.log("Error parsing recents JSON:", e);
                }
            }
        }
    }

    Process {
        id: favToggleProcess
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                root.loadFavorites();
            }
        }
    }

    Process {
        id: statusProcess
        command: ["jeme-wallpaper-engine", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    root.engineState = data;
                    if (data.running && data.id) {
                        for (let i = 0; i < root.allWallpapers.length; i++) {
                            if (root.allWallpapers[i].id === data.id) {
                                root.selectedWallpaper = root.allWallpapers[i];
                                break;
                            }
                        }
                        if (data.fps) {
                            root.selectedFps = data.fps;
                        }
                    }
                } catch(e) {
                    console.log("Error parsing status JSON:", e);
                }
            }
        }
    }

    Process {
        id: startProcess
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                root.refreshStatus();
                root.loadRecents();
            }
        }
    }

    Process {
        id: stopProcess
        command: ["jeme-wallpaper-engine", "stop"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.refreshStatus();
            }
        }
    }

    Process {
        id: fpsProcess
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                root.refreshStatus();
            }
        }
    }

    Process {
        id: themeApplyProcess
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                Theme.reloadTheme();
            }
        }
    }

    Process {
        id: themeCheckProcess
        command: ["bash", "-c", "grep -E '^gtk-application-prefer-dark-theme=' ~/.config/gtk-3.0/settings.ini 2>/dev/null || echo '0'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text.trim().toLowerCase();
                root.isDarkTheme = (out.indexOf("1") !== -1 || out.indexOf("true") !== -1);
            }
        }
    }

    Process {
        id: themeToggleProcess
        command: ["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-toggle-theme"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.checkThemeMode();
                Theme.reloadTheme();
            }
        }
    }

    // --- REUSABLE COMPONENTS ---

    component HeaderTabButton: Item {
        id: tabBtn
        property string label: ""
        property bool active: false
        signal clicked()

        implicitWidth: tabLabel.implicitWidth + 24
        implicitHeight: 30

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: tabBtn.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.14) : (tabMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.06) : "transparent")
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Text {
            id: tabLabel
            anchors.centerIn: parent
            text: tabBtn.label
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: tabBtn.active
            color: tabBtn.active ? Theme.primary : Theme.on_surface_variant
        }

        MouseArea {
            id: tabMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tabBtn.clicked()
        }
    }

    component NavFilterItem: Item {
        id: navItem
        property string label: ""
        property int count: 0
        property bool active: false
        signal clicked()

        implicitWidth: navRow.implicitWidth + 16
        implicitHeight: 28

        Rectangle {
            anchors.fill: parent
            radius: 5
            color: navItem.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) : (navMouse.containsMouse ? Theme.surface_container_high : "transparent")
            border.color: navItem.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : "transparent"
            border.width: 1
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        RowLayout {
            id: navRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: navItem.label
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: navItem.active
                color: navItem.active ? Theme.primary : Theme.on_surface_variant
            }

            Text {
                text: navItem.count.toString()
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.bold: navItem.active
                color: navItem.active ? Theme.primary : Theme.outline
                opacity: navItem.active ? 0.9 : 0.6
            }
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: navItem.clicked()
        }
    }

    component AppButton: Button {
        id: btn
        property bool isPrimary: false
        property bool isDanger: false
        property bool isSecondary: false
        property string iconSource: ""

        implicitHeight: isPrimary ? 36 : 32
        Layout.fillWidth: true
        hoverEnabled: true

        background: Rectangle {
            radius: 6
            color: {
                if (btn.isPrimary) {
                    return btn.hovered ? Theme.primary_fixed_dim : Theme.primary;
                }
                if (btn.isDanger) {
                    return btn.hovered ? Theme.error_container : "transparent";
                }
                if (btn.isSecondary) {
                    return btn.hovered ? Theme.surface_container_highest : Theme.surface_container_high;
                }
                return btn.hovered ? Theme.surface_container_highest : Theme.surface_container;
            }
            border.color: {
                if (btn.isPrimary) return Theme.primary;
                if (btn.isDanger) return btn.hovered ? Theme.error : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.4);
                return Theme.outline_variant;
            }
            border.width: 1
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        contentItem: RowLayout {
            spacing: 6
            anchors.centerIn: parent

            Image {
                visible: btn.iconSource !== ""
                source: btn.iconSource
                width: 14
                height: 14
                sourceSize.width: 14
                sourceSize.height: 14
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: btn.isPrimary ? Theme.background : (btn.isDanger ? Theme.error : Theme.on_surface)
                }
            }

            Text {
                text: btn.text
                font.family: Theme.fontFamily
                font.pixelSize: btn.isPrimary ? 12 : 11
                font.bold: btn.isPrimary
                color: {
                    if (btn.isPrimary) return Theme.background;
                    if (btn.isDanger) return Theme.error;
                    return Theme.on_surface;
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.NoButton
        }
    }

    // --- MAIN MODAL CONTAINER ---
    Item {
        id: modalWrapper
        anchors.centerIn: parent
        width: 1060
        height: 680

        opacity: root.isOpen ? 1.0 : 0.0
        scale: root.isOpen ? 1.0 : 0.97

        Behavior on opacity {
            NumberAnimation {
                id: modalFadeAnim
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        DragHandler {
            target: modalWrapper
            xAxis.enabled: true
            yAxis.enabled: true
        }

        // Soft Backdrop Shadow
        RectangularShadow {
            anchors.fill: mainContainer
            radius: mainContainer.radius
            blur: 24
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        // Window Frame
        Rectangle {
            id: mainContainer
            anchors.fill: parent
            radius: 12
            clip: true
            color: Theme.background
            border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // ========================================================
                // 1. WINDOW TITLE & TOOLBAR HEADER
                // ========================================================
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Left: Brand & Live Status
                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 6
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)

                            Image {
                                anchors.centerIn: parent
                                source: "../shared/icons/wallpaper.svg"
                                width: 16
                                height: 16
                                sourceSize.width: 16
                                sourceSize.height: 16
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: Theme.primary
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 0
                            Text {
                                text: "Wallpaper Engine"
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                color: Theme.on_surface
                            }
                            Text {
                                text: "Live Desktop Backdrops"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.outline
                            }
                        }

                        // Subtle Status Indicator
                        Rectangle {
                            Layout.leftMargin: 8
                            implicitWidth: statusRow.implicitWidth + 10
                            implicitHeight: 20
                            radius: 4
                            color: root.engineState.running ? Qt.rgba(0.1, 0.6, 0.2, 0.15) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                            border.color: root.engineState.running ? Qt.rgba(0.2, 0.8, 0.3, 0.35) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                            border.width: 1

                            RowLayout {
                                id: statusRow
                                anchors.centerIn: parent
                                spacing: 5

                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: root.engineState.running ? "#4ade80" : Theme.outline
                                }

                                Text {
                                    text: root.engineState.running ? "Active (" + (root.engineState.fps || 10) + " FPS)" : "Static"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: root.engineState.running
                                    color: root.engineState.running ? "#86efac" : Theme.outline
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Center: Navigation Tabs
                    RowLayout {
                        spacing: 4
                        HeaderTabButton {
                            label: "Wallpapers"
                            active: root.currentTab === 0
                            onClicked: root.currentTab = 0
                        }
                        HeaderTabButton {
                            label: "Theme Sync"
                            active: root.currentTab === 1
                            onClicked: root.currentTab = 1
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Right: Close Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: closeMouse.containsMouse ? Theme.surface_container_highest : "transparent"

                        Image {
                            anchors.centerIn: parent
                            source: "../shared/icons/x.svg"
                            width: 12
                            height: 12
                            sourceSize.width: 12
                            sourceSize.height: 12
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: closeMouse.containsMouse ? Theme.error : Theme.outline
                            }
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.isOpen = false
                        }
                    }
                }

                // Divider Line
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.outline_variant
                    opacity: 0.25
                }

                // ========================================================
                // 2. MAIN CONTENT AREA (TABS)
                // ========================================================
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.currentTab

                    // ----------------------------------------------------
                    // TAB 0: WALLPAPERS BROWSER & HERO PREVIEW
                    // ----------------------------------------------------
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            // SUB-TOOLBAR: Search + Filter Navigation Bar + Sort + Refresh
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Search Field
                                Rectangle {
                                    implicitWidth: 220
                                    implicitHeight: 30
                                    radius: 6
                                    color: Theme.surface_container_lowest
                                    border.color: searchInput.activeFocus ? Theme.primary : Theme.outline_variant
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 6

                                        Image {
                                            source: "../shared/icons/search.svg"
                                            width: 13
                                            height: 13
                                            sourceSize.width: 13
                                            sourceSize.height: 13
                                            opacity: 0.5
                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                colorization: 1.0
                                                colorizationColor: Theme.outline
                                            }
                                        }

                                        TextInput {
                                            id: searchInput
                                            Layout.fillWidth: true
                                            text: root.searchQuery
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            color: Theme.on_surface
                                            selectByMouse: true

                                            onTextChanged: {
                                                root.searchQuery = text;
                                                root.updateFilteredWallpapers();
                                            }

                                            Text {
                                                anchors.fill: parent
                                                visible: !searchInput.text && !searchInput.activeFocus
                                                text: "Search wallpapers..."
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                color: Theme.outline
                                                opacity: 0.7
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        // Clear Search
                                        Image {
                                            visible: root.searchQuery.length > 0
                                            source: "../shared/icons/x.svg"
                                            width: 11
                                            height: 11
                                            sourceSize.width: 11
                                            sourceSize.height: 11
                                            opacity: 0.6
                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                colorization: 1.0
                                                colorizationColor: Theme.outline
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    searchInput.text = "";
                                                    root.searchQuery = "";
                                                    root.updateFilteredWallpapers();
                                                }
                                            }
                                        }
                                    }
                                }

                                // Filter Category Navigation Bar
                                RowLayout {
                                    spacing: 2

                                    NavFilterItem {
                                        label: "All"
                                        count: root.getFilterCount("all")
                                        active: root.selectedFilter === "all"
                                        onClicked: {
                                            root.selectedFilter = "all";
                                            root.updateFilteredWallpapers();
                                        }
                                    }

                                    NavFilterItem {
                                        label: "Scenes"
                                        count: root.getFilterCount("scene")
                                        active: root.selectedFilter === "scene"
                                        onClicked: {
                                            root.selectedFilter = "scene";
                                            root.updateFilteredWallpapers();
                                        }
                                    }

                                    NavFilterItem {
                                        label: "Videos"
                                        count: root.getFilterCount("video")
                                        active: root.selectedFilter === "video"
                                        onClicked: {
                                            root.selectedFilter = "video";
                                            root.updateFilteredWallpapers();
                                        }
                                    }

                                    NavFilterItem {
                                        label: "Web"
                                        count: root.getFilterCount("web")
                                        active: root.selectedFilter === "web"
                                        onClicked: {
                                            root.selectedFilter = "web";
                                            root.updateFilteredWallpapers();
                                        }
                                    }

                                    NavFilterItem {
                                        label: "Favorites"
                                        count: root.getFilterCount("favorites")
                                        active: root.selectedFilter === "favorites"
                                        onClicked: {
                                            root.selectedFilter = "favorites";
                                            root.updateFilteredWallpapers();
                                        }
                                    }

                                    NavFilterItem {
                                        label: "Recent"
                                        count: root.getFilterCount("recent")
                                        active: root.selectedFilter === "recent"
                                        onClicked: {
                                            root.selectedFilter = "recent";
                                            root.updateFilteredWallpapers();
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Sort Selector
                                ComboBox {
                                    id: sortCombo
                                    implicitWidth: 120
                                    implicitHeight: 30
                                    model: [
                                        { "value": "name_asc", "label": "Name A-Z" },
                                        { "value": "name_desc", "label": "Name Z-A" },
                                        { "value": "recent", "label": "Recent" }
                                    ]
                                    textRole: "label"
                                    valueRole: "value"
                                    currentIndex: 0
                                    onActivated: {
                                        root.selectedSort = currentValue.value;
                                        root.updateFilteredWallpapers();
                                    }

                                    background: Rectangle {
                                        radius: 6
                                        color: Theme.surface_container_lowest
                                        border.color: Theme.outline_variant
                                        border.width: 1
                                    }

                                    contentItem: Text {
                                        text: sortCombo.displayText
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: Theme.on_surface_variant
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 8
                                        elide: Text.ElideRight
                                    }
                                }

                                // Refresh Button
                                Rectangle {
                                    implicitWidth: 30
                                    implicitHeight: 30
                                    radius: 6
                                    color: refreshMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_lowest
                                    border.color: Theme.outline_variant
                                    border.width: 1

                                    Image {
                                        anchors.centerIn: parent
                                        source: "../shared/icons/refresh.svg"
                                        width: 13
                                        height: 13
                                        sourceSize.width: 13
                                        sourceSize.height: 13
                                        rotation: root.isSyncing ? 360 : 0
                                        Behavior on rotation {
                                            NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
                                        }
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            colorization: 1.0
                                            colorizationColor: root.isSyncing ? Theme.primary : Theme.on_surface_variant
                                        }
                                    }

                                    MouseArea {
                                        id: refreshMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.currentWorkshopSignature = "";
                                            root.loadWallpapers();
                                            root.loadFavorites();
                                            root.loadRecents();
                                            root.refreshStatus();
                                            root.checkWorkshopSignature();
                                        }
                                    }
                                }
                            }

                            // Body: Grid View (Left 58%) + Hero Details (Right 42%)
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 10

                                // LEFT COLUMN: Wallpaper Grid
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 8
                                    color: Theme.surface_container_lowest
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.3)
                                    border.width: 1
                                    clip: true

                                    GridView {
                                        id: wpGrid
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        cellWidth: Math.floor(width / 3)
                                        cellHeight: 122
                                        model: root.filteredWallpapers
                                        visible: root.filteredWallpapers.length > 0

                                        ScrollBar.vertical: ScrollBar {
                                            interactive: true
                                            policy: ScrollBar.AsNeeded
                                            contentItem: Rectangle {
                                                implicitWidth: 4
                                                radius: 2
                                                color: Theme.primary
                                                opacity: 0.5
                                            }
                                        }

                                        delegate: Item {
                                            width: wpGrid.cellWidth
                                            height: wpGrid.cellHeight

                                            readonly property bool isSelected: root.selectedWallpaper && root.selectedWallpaper.id === modelData.id
                                            readonly property bool isActive: root.engineState.running && root.engineState.id === modelData.id
                                            readonly property bool isFav: root.isWallpaperFavorite(modelData.id)

                                            Rectangle {
                                                anchors.fill: parent
                                                anchors.margins: 3
                                                radius: 6
                                                color: Theme.surface_container
                                                border.color: {
                                                    if (isActive) return "#4ade80";
                                                    if (isSelected) return Theme.primary;
                                                    if (cardMouse.containsMouse) return Theme.outline;
                                                    return "transparent";
                                                }
                                                border.width: (isSelected || isActive) ? 2 : 1
                                                clip: true

                                                // Thumbnail Image
                                                Image {
                                                    id: cardThumb
                                                    anchors.fill: parent
                                                    source: modelData.thumbnail ? ("file://" + modelData.thumbnail) : (modelData.preview ? ("file://" + modelData.preview) : "")
                                                    fillMode: Image.PreserveAspectCrop
                                                    asynchronous: true
                                                    sourceSize.width: 280
                                                    sourceSize.height: 160
                                                    opacity: status === Image.Ready ? 1.0 : 0.0
                                                    Behavior on opacity {
                                                        NumberAnimation { duration: 150 }
                                                    }
                                                }

                                                // Fallback Placeholder
                                                Rectangle {
                                                    anchors.fill: parent
                                                    visible: cardThumb.status !== Image.Ready
                                                    color: Theme.surface_container_highest

                                                    ColumnLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 2
                                                        Image {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            source: "../shared/icons/wallpaper.svg"
                                                            width: 18
                                                            height: 18
                                                            sourceSize.width: 18
                                                            sourceSize.height: 18
                                                            opacity: 0.3
                                                        }
                                                        Text {
                                                            Layout.alignment: Qt.AlignHCenter
                                                            text: (modelData.type || "SCENE").toUpperCase()
                                                            font.family: Theme.fontFamily
                                                            font.pixelSize: 8
                                                            font.bold: true
                                                            color: Theme.outline
                                                        }
                                                    }
                                                }

                                                // Top Status Tags Row
                                                RowLayout {
                                                    anchors.top: parent.top
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.margins: 4
                                                    spacing: 4

                                                    // Active Tag
                                                    Rectangle {
                                                        visible: isActive
                                                        implicitWidth: activeLabel.implicitWidth + 8
                                                        implicitHeight: 16
                                                        radius: 3
                                                        color: "#cc0f391b"
                                                        border.color: "#86efac"
                                                        border.width: 1

                                                        Text {
                                                            id: activeLabel
                                                            anchors.centerIn: parent
                                                            text: "Active"
                                                            font.family: Theme.fontFamily
                                                            font.pixelSize: 8
                                                            font.bold: true
                                                            color: "#86efac"
                                                        }
                                                    }

                                                    Item { Layout.fillWidth: true }

                                                    // Favorite Icon Button
                                                    Rectangle {
                                                        visible: isFav || cardMouse.containsMouse
                                                        implicitWidth: 18
                                                        implicitHeight: 16
                                                        radius: 3
                                                        color: isFav ? "#cc78350f" : "#aa000000"

                                                        Image {
                                                            anchors.centerIn: parent
                                                            source: isFav ? "../shared/icons/star-filled.svg" : "../shared/icons/star.svg"
                                                            width: 10
                                                            height: 10
                                                            sourceSize.width: 10
                                                            sourceSize.height: 10
                                                            layer.enabled: true
                                                            layer.effect: MultiEffect {
                                                                colorization: 1.0
                                                                colorizationColor: isFav ? "#fef08a" : "#ffffff"
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                root.toggleFavorite(modelData.id);
                                                            }
                                                        }
                                                    }

                                                    // Type Badge
                                                    Rectangle {
                                                        implicitWidth: typeText.implicitWidth + 6
                                                        implicitHeight: 16
                                                        radius: 3
                                                        color: "#aa000000"

                                                        Text {
                                                            id: typeText
                                                            anchors.centerIn: parent
                                                            text: (modelData.type || "SCENE").toUpperCase()
                                                            font.family: Theme.fontFamily
                                                            font.pixelSize: 8
                                                            font.bold: true
                                                            color: "#ffffff"
                                                            opacity: 0.85
                                                        }
                                                    }
                                                }

                                                // Bottom Title Gradient Overlay
                                                Rectangle {
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom
                                                    height: 24

                                                    gradient: Gradient {
                                                        GradientStop { position: 0.0; color: "#00000000" }
                                                        GradientStop { position: 1.0; color: "#e6000000" }
                                                    }

                                                    Text {
                                                        anchors.bottom: parent.bottom
                                                        anchors.left: parent.left
                                                        anchors.right: parent.right
                                                        anchors.margins: 4
                                                        text: modelData.title
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: 10
                                                        font.bold: isSelected
                                                        color: isSelected ? Theme.primary : "#ffffff"
                                                        elide: Text.ElideRight
                                                    }
                                                }

                                                MouseArea {
                                                    id: cardMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.selectedWallpaper = modelData;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Clean Empty State
                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        visible: root.filteredWallpapers.length === 0
                                        spacing: 6

                                        Image {
                                            Layout.alignment: Qt.AlignHCenter
                                            source: "../shared/icons/search.svg"
                                            width: 24
                                            height: 24
                                            sourceSize.width: 24
                                            sourceSize.height: 24
                                            opacity: 0.35
                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                colorization: 1.0
                                                colorizationColor: Theme.outline
                                            }
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: "No wallpapers found"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Theme.on_surface
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: root.searchQuery ? "No results matching '" + root.searchQuery + "'" : "No wallpapers in this category"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            color: Theme.outline
                                        }

                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.topMargin: 4
                                            implicitWidth: 100
                                            implicitHeight: 26
                                            radius: 5
                                            color: Theme.surface_container_high
                                            border.color: Theme.outline_variant
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Reset Filters"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                color: Theme.primary
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    searchInput.text = "";
                                                    root.searchQuery = "";
                                                    root.selectedFilter = "all";
                                                    root.updateFilteredWallpapers();
                                                }
                                            }
                                        }
                                    }
                                }

                                // RIGHT COLUMN: Hero Preview & Streamlined Controls
                                Rectangle {
                                    Layout.preferredWidth: 390
                                    Layout.fillHeight: true
                                    radius: 8
                                    color: Theme.surface_container_lowest
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.3)
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 8

                                        // 1. DOMINANT HERO WALLPAPER PREVIEW
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 215
                                            radius: 6
                                            color: Theme.surface_container_high
                                            clip: true
                                            border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)
                                            border.width: 1

                                            Image {
                                                id: heroPreview
                                                anchors.fill: parent
                                                source: root.selectedWallpaper ? (root.selectedWallpaper.preview ? ("file://" + root.selectedWallpaper.preview) : (root.selectedWallpaper.thumbnail ? ("file://" + root.selectedWallpaper.thumbnail) : "")) : ""
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                opacity: status === Image.Ready ? 1.0 : 0.0
                                                Behavior on opacity {
                                                    NumberAnimation { duration: 150 }
                                                }
                                            }

                                            // Placeholder
                                            Rectangle {
                                                anchors.fill: parent
                                                visible: heroPreview.status !== Image.Ready
                                                color: Theme.surface_container_high

                                                ColumnLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 4
                                                    Image {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        source: "../shared/icons/wallpaper.svg"
                                                        width: 24
                                                        height: 24
                                                        sourceSize.width: 24
                                                        sourceSize.height: 24
                                                        opacity: 0.3
                                                    }
                                                    Text {
                                                        Layout.alignment: Qt.AlignHCenter
                                                        text: root.selectedWallpaper ? "Loading preview..." : "Select a wallpaper"
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: 11
                                                        color: Theme.outline
                                                    }
                                                }
                                            }

                                            // Status Badge Overlay
                                            Rectangle {
                                                visible: root.selectedWallpaper && (root.engineState.running && root.engineState.id === root.selectedWallpaper.id)
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.margins: 6
                                                implicitWidth: activeHeroBadge.implicitWidth + 10
                                                implicitHeight: 18
                                                radius: 4
                                                color: "#cc0f391b"
                                                border.color: "#86efac"
                                                border.width: 1

                                                Text {
                                                    id: activeHeroBadge
                                                    anchors.centerIn: parent
                                                    text: "Active"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: "#86efac"
                                                }
                                            }

                                            Rectangle {
                                                visible: root.isPreviewing && root.selectedWallpaper && !(root.engineState.running && root.engineState.id === root.selectedWallpaper.id)
                                                anchors.top: parent.top
                                                anchors.right: parent.right
                                                anchors.margins: 6
                                                implicitWidth: previewHeroBadge.implicitWidth + 10
                                                implicitHeight: 18
                                                radius: 4
                                                color: "#cc451a03"
                                                border.color: "#fef08a"
                                                border.width: 1

                                                Text {
                                                    id: previewHeroBadge
                                                    anchors.centerIn: parent
                                                    text: "Preview"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: "#fef08a"
                                                }
                                            }
                                        }

                                        // 2. WALLPAPER INFORMATION & FAVORITE
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 3

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: root.selectedWallpaper ? root.selectedWallpaper.title : "No Wallpaper Selected"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 14
                                                    font.bold: true
                                                    color: Theme.on_surface
                                                    elide: Text.ElideRight
                                                }

                                                // Favorite Toggle Button
                                                Rectangle {
                                                    visible: root.selectedWallpaper !== null
                                                    implicitWidth: favBtnRow.implicitWidth + 10
                                                    implicitHeight: 22
                                                    radius: 4
                                                    color: root.selectedWallpaper && root.isWallpaperFavorite(root.selectedWallpaper.id) ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : Theme.surface_container_high
                                                    border.color: root.selectedWallpaper && root.isWallpaperFavorite(root.selectedWallpaper.id) ? Theme.primary : Theme.outline_variant
                                                    border.width: 1

                                                    RowLayout {
                                                        id: favBtnRow
                                                        anchors.centerIn: parent
                                                        spacing: 4

                                                        Image {
                                                            source: (root.selectedWallpaper && root.isWallpaperFavorite(root.selectedWallpaper.id)) ? "../shared/icons/star-filled.svg" : "../shared/icons/star.svg"
                                                            width: 11
                                                            height: 11
                                                            sourceSize.width: 11
                                                            sourceSize.height: 11
                                                            layer.enabled: true
                                                            layer.effect: MultiEffect {
                                                                colorization: 1.0
                                                                colorizationColor: (root.selectedWallpaper && root.isWallpaperFavorite(root.selectedWallpaper.id)) ? Theme.primary : Theme.outline
                                                            }
                                                        }

                                                        Text {
                                                            text: (root.selectedWallpaper && root.isWallpaperFavorite(root.selectedWallpaper.id)) ? "Favorited" : "Favorite"
                                                            font.family: Theme.fontFamily
                                                            font.pixelSize: 10
                                                            color: (root.selectedWallpaper && root.isWallpaperFavorite(root.selectedWallpaper.id)) ? Theme.primary : Theme.on_surface_variant
                                                        }
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (root.selectedWallpaper) {
                                                                root.toggleFavorite(root.selectedWallpaper.id);
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // Concise Metadata Text
                                            Text {
                                                text: {
                                                    if (!root.selectedWallpaper) return "—";
                                                    let t = (root.selectedWallpaper.type || "Scene").toUpperCase();
                                                    return t + " · ID: " + root.selectedWallpaper.id;
                                                }
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                color: Theme.outline
                                            }
                                        }

                                        // Divider Line
                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 1
                                            color: Theme.outline_variant
                                            opacity: 0.25
                                        }

                                        // 3. TARGET DISPLAY & FRAME RATE CONTROLS
                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            // Display Selector
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    text: "Target Display"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 10
                                                    color: Theme.outline
                                                }

                                                ComboBox {
                                                    id: monitorComboBox
                                                    Layout.fillWidth: true
                                                    implicitHeight: 28
                                                    model: root.monitorModel
                                                    textRole: "label"
                                                    valueRole: "name"
                                                    currentIndex: 0
                                                    onActivated: {
                                                        root.selectedMonitor = currentValue.name;
                                                    }
                                                    background: Rectangle {
                                                        radius: 5
                                                        color: Theme.surface_container_high
                                                        border.color: Theme.outline_variant
                                                        border.width: 1
                                                    }
                                                    contentItem: Text {
                                                        text: monitorComboBox.displayText
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: 10
                                                        color: Theme.on_surface
                                                        verticalAlignment: Text.AlignVCenter
                                                        leftPadding: 6
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                            }

                                            // FPS Selector
                                            ColumnLayout {
                                                Layout.preferredWidth: 170
                                                spacing: 2

                                                Text {
                                                    text: "Frame Rate"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 10
                                                    color: Theme.outline
                                                }

                                                RowLayout {
                                                    spacing: 3
                                                    Repeater {
                                                        model: [10, 15, 30, 60]
                                                        delegate: Rectangle {
                                                            Layout.fillWidth: true
                                                            implicitHeight: 28
                                                            radius: 5
                                                            color: root.selectedFps === modelData ? Theme.primary : Theme.surface_container_high
                                                            border.color: root.selectedFps === modelData ? Theme.primary : Theme.outline_variant
                                                            border.width: 1

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: modelData.toString()
                                                                font.family: Theme.fontFamily
                                                                font.pixelSize: 10
                                                                font.bold: root.selectedFps === modelData
                                                                color: root.selectedFps === modelData ? Theme.background : Theme.on_surface_variant
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                cursorShape: Qt.PointingHandCursor
                                                                onClicked: root.changeFps(modelData)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Item { Layout.fillHeight: true }

                                        // 4. ACTION BUTTONS (CLEAN HIERARCHY)
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            // Primary CTA
                                            AppButton {
                                                text: "Apply Wallpaper"
                                                isPrimary: true
                                                enabled: root.selectedWallpaper !== null
                                                onClicked: root.applySelectedWallpaper(false)
                                            }

                                            // Secondary Actions Row
                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                AppButton {
                                                    text: "Apply + Theme"
                                                    isSecondary: true
                                                    enabled: root.selectedWallpaper !== null
                                                    onClicked: root.applySelectedWallpaper(true)
                                                }

                                                AppButton {
                                                    text: root.isPreviewing ? "Stop Preview" : "Live Preview"
                                                    isSecondary: true
                                                    enabled: root.selectedWallpaper !== null
                                                    onClicked: root.togglePreviewSelected()
                                                }
                                            }

                                            // Destructive Action
                                            AppButton {
                                                text: "Stop Engine"
                                                isDanger: true
                                                enabled: root.engineState.running || root.isPreviewing
                                                onClicked: root.stopWallpaperEngine()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ----------------------------------------------------
                    // TAB 1: THEMES (MATUGEN REUSE & COLOR SYSTEM)
                    // ----------------------------------------------------
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 12

                            // Dark / Light Mode Switcher Card
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 60
                                radius: 8
                                color: Theme.surface_container_lowest
                                border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.3)
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    ColumnLayout {
                                        spacing: 1
                                        Text {
                                            text: "Desktop Theme Mode"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: Theme.on_surface
                                        }
                                        Text {
                                            text: "Current Mode: " + (root.isDarkTheme ? "Dark" : "Light")
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            color: Theme.outline
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Button {
                                        text: root.isDarkTheme ? "Switch to Light Mode" : "Switch to Dark Mode"
                                        implicitHeight: 32
                                        background: Rectangle {
                                            radius: 6
                                            color: Theme.surface_container_high
                                            border.color: Theme.outline_variant
                                            border.width: 1
                                        }
                                        contentItem: Text {
                                            text: parent.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            color: Theme.on_surface
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            padding: 6
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            acceptedButtons: Qt.NoButton
                                        }
                                        onClicked: {
                                            themeToggleProcess.running = false;
                                            themeToggleProcess.running = true;
                                        }
                                    }
                                }
                            }

                            // Live Color Palette Preview Swatches
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: Theme.surface_container_lowest
                                border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.3)
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 12

                                    Text {
                                        text: "Dynamic Material Palette Swatches"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.on_surface
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Repeater {
                                            model: [
                                                { "name": "Primary", "color": Theme.primary, "text": Theme.background },
                                                { "name": "Secondary", "color": Theme.secondary, "text": Theme.background },
                                                { "name": "Tertiary", "color": Theme.tertiary, "text": Theme.background },
                                                { "name": "Background", "color": Theme.background, "text": Theme.on_background },
                                                { "name": "Surface", "color": Theme.surface, "text": Theme.on_surface },
                                                { "name": "Container", "color": Theme.surface_container, "text": Theme.on_surface }
                                            ]

                                            delegate: Rectangle {
                                                Layout.fillWidth: true
                                                implicitHeight: 64
                                                radius: 6
                                                color: modelData.color
                                                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
                                                border.width: 1

                                                ColumnLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 2
                                                    Text {
                                                        text: modelData.name
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        color: modelData.text
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                    Text {
                                                        text: modelData.color.toString().toUpperCase()
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: 9
                                                        color: modelData.text
                                                        opacity: 0.8
                                                        horizontalAlignment: Text.AlignHCenter
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    // Action Row
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        AppButton {
                                            text: "Extract Theme from Selected Wallpaper"
                                            isPrimary: true
                                            enabled: root.selectedWallpaper !== null
                                            onClicked: {
                                                if (root.selectedWallpaper) {
                                                    themeApplyProcess.command = ["jeme-wallpaper-engine", "apply-theme", root.selectedWallpaper.id];
                                                    themeApplyProcess.running = false;
                                                    themeApplyProcess.running = true;
                                                }
                                            }
                                        }

                                        AppButton {
                                            text: "Reload System Theme Tokens"
                                            isSecondary: true
                                            onClicked: {
                                                Theme.reloadTheme();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ========================================================
                // 3. FOOTER STATUS BAR
                // ========================================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 22
                    radius: 4
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent

                        Text {
                            text: {
                                if (root.engineState.running) {
                                    return (root.engineState.title || root.engineState.id) + " · " + root.engineState.monitor + " · " + root.engineState.fps + " FPS";
                                }
                                if (root.engineState.last_error) {
                                    let err = root.engineState.last_error.split("\n")[0];
                                    if (err.length > 70) err = err.substring(0, 67) + "...";
                                    return "Notice: " + err;
                                }
                                return "Static background active";
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: root.engineState.running ? Theme.primary : (root.engineState.last_error ? Theme.error : Theme.outline)
                            opacity: 0.9
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "Press Esc or Super+Q to close"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.outline
                            opacity: 0.6
                        }
                    }
                }
            }
        }
    }
}
