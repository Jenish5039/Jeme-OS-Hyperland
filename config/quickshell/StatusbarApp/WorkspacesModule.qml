import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Workspace switcher for Jeme OS.
// Preserves Hyprland Lua dispatching, dynamic workspace detection, and keyboard navigation.
RowLayout {
    id: wsRoot
    spacing: 6

    // Minimum number of workspaces to always display, even when empty.
    property int minWorkspaces: 5

    // The individual workspace buttons, exposed for StatusbarWindow keyboard navigation.
    property var navButtons: []

    function rebuildNavButtons(): void {
        let a = []
        for (let i = 0; i < rep.count; i++)
            a.push(rep.itemAt(i))
        wsRoot.navButtons = a
    }

    // Dynamic range of workspace IDs (1..max(minWorkspaces, activeId))
    readonly property var workspaceIds: {
        let maxId = Math.max(1, wsRoot.minWorkspaces)
        const list = Hyprland.workspaces.values
        for (let i = 0; i < list.length; i++)
            if (list[i].id > maxId)
                maxId = list[i].id
        let ids = []
        for (let id = 1; id <= maxId; id++)
            ids.push(id)
        return ids
    }

    function workspaceById(id: int): var {
        const list = Hyprland.workspaces.values
        for (let i = 0; i < list.length; i++)
            if (list[i].id === id)
                return list[i]
        return null
    }

    Repeater {
        id: rep
        model: wsRoot.workspaceIds

        onItemAdded: wsRoot.rebuildNavButtons()
        onItemRemoved: wsRoot.rebuildNavButtons()

        delegate: Rectangle {
            id: ws
            required property var modelData   // workspace id (int)
            property bool focused: false

            readonly property bool isActive: Hyprland.focusedWorkspace
                && Hyprland.focusedWorkspace.id === ws.modelData
            readonly property bool occupied: wsRoot.workspaceById(ws.modelData) !== null

            function activate(): void {
                if (Hyprland.usingLua)
                    Hyprland.dispatch("hl.dsp.focus({workspace = '" + ws.modelData + "'})")
                else
                    Hyprland.dispatch("workspace " + ws.modelData)
            }

            implicitWidth: 26
            implicitHeight: 26
            radius: 13

            // Visual hierarchy: Active (1.0) > Occupied (0.90) > Hover (0.75) > Inactive (0.45)
            opacity: ws.isActive ? 1.0 : (ws.occupied ? 0.90 : (wsMouse.containsMouse ? 0.75 : 0.45))
            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
            }

            color: ws.isActive
                ? Theme.primary
                : (wsMouse.containsMouse ? Theme.surface_container_high : "transparent")
            border.color: ws.isActive ? Theme.primary : (ws.occupied ? Theme.outline : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4))
            border.width: ws.isActive ? 0 : 1

            Behavior on color {
                ColorAnimation { duration: 300; easing.type: Easing.OutQuint }
            }
            Behavior on border.color {
                ColorAnimation { duration: 300; easing.type: Easing.OutQuint }
            }
            Behavior on border.width {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
            }

            scale: wsMouse.pressed ? 0.92 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutBack }
            }

            // Keyboard-selection ring
            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                radius: parent.radius + 2
                color: "transparent"
                border.color: Theme.primary
                border.width: 1.5
                opacity: ws.focused ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }

            // Clean centered workspace number (no selection dot)
            Text {
                anchors.centerIn: parent
                text: ws.modelData
                color: ws.isActive ? Theme.background : (ws.occupied ? Theme.primary : Theme.on_surface_variant)
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true

                Behavior on color {
                    ColorAnimation { duration: 300; easing.type: Easing.OutQuint }
                }
            }

            MouseArea {
                id: wsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ws.activate()
            }
        }
    }
}
