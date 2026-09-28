import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.CustomTheme

// Omarchy-inspired Battery module for Jeme OS.
// Displays battery charge percentage and dynamic status icon.
// Shown only on machines with a laptop battery; auto-collapses on desktop.
Rectangle {
    id: battery

    readonly property var device: UPower.displayDevice
    readonly property bool hasBattery: device !== null
        && device.isLaptopBattery && device.isPresent
    readonly property bool pluggedIn: !UPower.onBattery
    readonly property int percent: device ? Math.round(device.percentage * 100) : 0

    property bool preview: false

    readonly property bool collapsed: !preview && !hasBattery
    readonly property int shownPercent: preview && !hasBattery ? 72 : percent
    readonly property bool shownCharging: preview && !hasBattery ? false : pluggedIn

    readonly property string iconSource: {
        if (shownCharging)
            return "../shared/icons/battery-charging.svg"
        if (shownPercent <= 20)
            return "../shared/icons/battery-low.svg"
        if (shownPercent <= 65)
            return "../shared/icons/battery-medium.svg"
        return "../shared/icons/battery-full.svg"
    }

    visible: !collapsed

    readonly property bool hovered: mouseArea.containsMouse

    implicitWidth: collapsed ? 0 : row.implicitWidth + 16
    implicitHeight: 28
    radius: 14

    color: hovered ? Theme.surface_container_high : "transparent"
    border.color: hovered ? Theme.outline : "transparent"
    border.width: hovered ? 1 : 0

    Behavior on color {
        ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
    }
    Behavior on border.color {
        ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
    }
    Behavior on border.width {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
    }
    Behavior on implicitWidth {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuint }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Image {
            Layout.alignment: Qt.AlignVCenter
            source: battery.iconSource
            sourceSize.width: 16
            sourceSize.height: 16
            width: 16
            height: 16
            fillMode: Image.PreserveAspectFit
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: battery.hovered ? Theme.on_surface : (battery.shownPercent <= 20 && !battery.shownCharging ? Theme.error : Theme.primary)
                Behavior on colorizationColor {
                    ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: battery.shownPercent + "%"
            color: battery.hovered ? Theme.on_surface : (battery.shownPercent <= 20 && !battery.shownCharging ? Theme.error : Theme.primary)
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            Behavior on color {
                ColorAnimation { duration: 250; easing.type: Easing.OutQuint }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
