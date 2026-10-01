import QtQuick
import QtQuick.Effects
import qs.CustomTheme

// Reusable Floating Glass HUD Capsule for Jeme OS Statusbar
Rectangle {
    id: capsuleRoot

    property color glassColor: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b, 0.70)
    property color borderColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22)
    property real customRadius: 14
    property bool activeHover: hoverDetector.hovered

    radius: customRadius
    height: 38
    color: glassColor
    border.color: activeHover
        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.42)
        : borderColor
    border.width: 1

    Behavior on border.color {
        ColorAnimation { duration: 300; easing.type: Easing.OutQuint }
    }

    Behavior on color {
        ColorAnimation { duration: 400; easing.type: Easing.OutQuint }
    }

    // Soft HUD depth shadow for floating spatial layer feel
    RectangularShadow {
        anchors.fill: parent
        radius: parent.radius
        blur: 14
        spread: 0
        color: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.38)
    }

    // Top subtle specular glass rim
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: Math.max(2, parent.radius * 0.75)
        radius: parent.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    HoverHandler {
        id: hoverDetector
    }
}
