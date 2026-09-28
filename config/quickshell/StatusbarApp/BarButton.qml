import QtQuick
import QtQuick.Effects
import qs.CustomTheme

// Reusable round icon button used across the status bar modules.
Rectangle {
    id: btn
    property string iconSrc: ""
    property bool colorize: true
    // Set by the keyboard navigation in StatusbarWindow to highlight the
    // currently selected module.
    property bool focused: false
    signal clicked()

    // Run the button's action (mouse click or keyboard Return).
    function activate(): void { btn.clicked() }

    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool active: hovered || btn.focused

    implicitWidth: 28
    implicitHeight: 28
    radius: 14

    color: btn.focused ? Theme.primary : (hovered ? Theme.surface_container_highest : "transparent")
    border.color: btn.focused ? Theme.primary : (hovered ? Theme.outline : "transparent")
    border.width: active ? 1 : 0

    Behavior on color {
        ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
    }
    Behavior on border.color {
        ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
    }
    Behavior on border.width {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
    }

    scale: mouseArea.pressed ? 0.92 : (hovered ? 1.05 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutBack }
    }

    Image {
        anchors.centerIn: parent
        source: btn.iconSrc
        width: 16
        height: 16
        sourceSize.width: 16
        sourceSize.height: 16
        fillMode: Image.PreserveAspectFit
        layer.enabled: btn.colorize
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: btn.focused ? Theme.background : (btn.hovered ? Theme.on_surface : Theme.primary)

            Behavior on colorizationColor {
                ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
