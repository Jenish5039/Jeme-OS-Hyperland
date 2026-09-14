import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.CustomTheme
import "../components"

ColumnLayout {
    id: root

    spacing: 16
    Layout.fillWidth: true

    SectionHeader {
        title: "Hyprland"
        subtitle: "Monitors, display arrangement, input settings, gestures, and compositor modes."
    }

    Text {
        text: "Displays & Hardware"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.on_background
        Layout.topMargin: 5
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Displays & Monitors"
        description: "Arrange monitors, adjust resolutions, refresh rates, scaling, and positioning with nwg-displays."
        buttonText: "Open Displays"
        isPrimary: true
        onClicked: Quickshell.execDetached(["nwg-displays"])
    }

    Text {
        text: "Input & Controls"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.on_background
        Layout.topMargin: 10
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Input Configuration"
        description: "Configure keyboard layouts, touchpad sensitivity, natural scrolling, and acceleration."
        buttonText: "Edit input.lua"
        onClicked: Quickshell.execDetached(["gnome-text-editor", Quickshell.env("HOME") + "/.config/hypr/input.lua"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Gestures Configuration"
        description: "Customize touchpad gestures, swipe sensitivity, and multi-finger bindings."
        buttonText: "Edit gestures.lua"
        onClicked: Quickshell.execDetached(["gnome-text-editor", Quickshell.env("HOME") + "/.config/hypr/gestures.lua"])
    }

    Text {
        text: "Compositor Modes & Features"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.on_background
        Layout.topMargin: 10
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Night Light (Hyprsunset)"
        description: "Toggle blue-light reduction filter for comfortable night-time viewing."
        buttonText: "Toggle Filter"
        onClicked: Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-toggle-hyprsunset"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Gamemode"
        description: "Disable window animations, blur, and rounding to maximize gaming and GPU performance."
        buttonText: "Toggle Gamemode"
        onClicked: Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/gamemode.sh"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Compositor Animations"
        description: "Quickly toggle all window and workspace animations on or off."
        buttonText: "Toggle Animations"
        onClicked: Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/toggle-animations.sh"])
    }
}
