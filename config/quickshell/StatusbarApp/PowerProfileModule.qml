import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.CustomTheme

// Omarchy-styled Power Profile module for Jeme OS.
// Shows the active system power profile as an icon and opens a sleek
// Omarchy-inspired popup card to switch between Power Saver, Balanced, and Performance.
Rectangle {
    id: profileRoot

    readonly property int current: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile

    property bool menuOpen: false
    property bool focused: false

    readonly property var profiles: {
        let list = [
            { "value": PowerProfile.PowerSaver,  "label": "Power Saver",  "icon": "../shared/icons/profile-power-saver.svg" },
            { "value": PowerProfile.Balanced,    "label": "Balanced",     "icon": "../shared/icons/profile-balanced.svg" }
        ]
        if (hasPerformance)
            list.push({ "value": PowerProfile.Performance, "label": "Performance", "icon": "../shared/icons/profile-performance.svg" })
        return list
    }

    readonly property string iconSource: {
        switch (current) {
        case PowerProfile.PowerSaver:   return "../shared/icons/profile-power-saver.svg"
        case PowerProfile.Performance:  return "../shared/icons/profile-performance.svg"
        default:                        return "../shared/icons/profile-balanced.svg"
        }
    }

    function setProfile(value: int): void {
        PowerProfiles.profile = value
        profileRoot.menuOpen = false
    }

    function activate(): void {
        profileRoot.menuOpen = !profileRoot.menuOpen
    }

    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool active: hovered || profileRoot.focused || profileRoot.menuOpen

    implicitWidth: 28
    implicitHeight: 28
    radius: 14

    color: (profileRoot.focused || profileRoot.menuOpen) ? Theme.primary : (hovered ? Theme.surface_container_highest : "transparent")
    border.color: (profileRoot.focused || profileRoot.menuOpen) ? Theme.primary : (hovered ? Theme.outline : "transparent")
    border.width: active ? 1 : 0

    Behavior on color {
        ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
    }
    Behavior on border.color {
        ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
    }
    Behavior on border.width {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
    }

    scale: mouseArea.pressed ? 0.94 : 1.0
    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutBack }
    }

    // Keyboard selection ring
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: parent.radius + 2
        color: "transparent"
        border.color: Theme.primary
        border.width: 1.5
        opacity: profileRoot.focused ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }

    Image {
        anchors.centerIn: parent
        source: profileRoot.iconSource
        width: 16
        height: 16
        sourceSize.width: 16
        sourceSize.height: 16
        fillMode: Image.PreserveAspectFit
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: (profileRoot.focused || profileRoot.menuOpen) ? Theme.background : (profileRoot.hovered ? Theme.on_surface : Theme.primary)
            Behavior on colorizationColor {
                ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: profileRoot.activate()
    }

    // ==========================================
    // SWITCH POPUP CARD
    // ==========================================
    PopupWindow {
        id: popup
        anchor.item: profileRoot
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 8
        anchor.rect.x: profileRoot.width / 2 - popup.width / 2

        visible: profileRoot.menuOpen

        HyprlandFocusGrab {
            windows: [popup]
            active: profileRoot.menuOpen
            onCleared: profileRoot.menuOpen = false
        }

        implicitWidth: 230
        implicitHeight: menuColumn.implicitHeight + 20
        color: "transparent"

        FocusScope {
            id: keyScope
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: profileRoot.menuOpen = false
        }

        onVisibleChanged: {
            if (visible)
                keyScope.forceActiveFocus()
        }

        // Omarchy-style floating popup card with crisp luminous border & shadow
        RectangularShadow {
            anchors.fill: cardBg
            radius: cardBg.radius
            blur: 16
            color: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.45)
        }

        Rectangle {
            id: cardBg
            anchors.fill: parent
            radius: 12
            color: Theme.surface_container_low
            border.color: Theme.outline_variant
            border.width: 1
        }

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            Repeater {
                model: profileRoot.profiles
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: modelData.value === profileRoot.current
                    readonly property bool rowHovered: rowMouse.containsMouse

                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: 8

                    color: selected ? Theme.primary : (rowHovered ? Theme.surface_container_highest : "transparent")
                    border.color: selected ? Theme.primary : (rowHovered ? Theme.outline : "transparent")
                    border.width: 1

                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Image {
                            Layout.alignment: Qt.AlignVCenter
                            source: modelData.icon
                            width: 16
                            height: 16
                            sourceSize.width: 16
                            sourceSize.height: 16
                            fillMode: Image.PreserveAspectFit
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: selected ? Theme.background : (rowHovered ? Theme.on_surface : Theme.primary)
                                Behavior on colorizationColor {
                                    ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            text: modelData.label
                            color: selected ? Theme.background : (rowHovered ? Theme.on_surface : Theme.on_surface_variant)
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: selected

                            Behavior on color {
                                ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
                            }
                        }

                        // Subtle active checkmark or indicator dot
                        Rectangle {
                            visible: selected
                            Layout.alignment: Qt.AlignVCenter
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.background
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: profileRoot.setProfile(modelData.value)
                    }
                }
            }
        }
    }
}
