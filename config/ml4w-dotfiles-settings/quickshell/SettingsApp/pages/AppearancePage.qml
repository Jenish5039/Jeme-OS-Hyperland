import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.CustomTheme
import "../components"

ColumnLayout {
    id: root

    property var settingsData: []
    property string scriptPath: Quickshell.env("HOME") + "/.local/bin/ml4w-dotfiles-settings"
    property string profile: "com.ml4w.dotfiles"

    spacing: 16
    Layout.fillWidth: true

    SectionHeader {
        title: "Appearance"
        subtitle: "Customize themes, window decorations, animations, launcher styles, and visual accents."
    }

    Text {
        text: "Theme Management"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.on_background
        Layout.topMargin: 5
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ActionCard {
            Layout.fillWidth: true
            title: "Theme & Icon Manager"
            description: "Launch nwg-look to select GTK themes, icon packs, and system fonts."
            buttonText: "Open nwg-look"
            onClicked: Quickshell.execDetached(["nwg-look"])
        }

        ActionCard {
            Layout.fillWidth: true
            title: "Toggle Dark / Light Theme"
            description: "Instantly switch color scheme across GTK, Matugen, and running applications."
            buttonText: "Toggle Mode"
            onClicked: Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-toggle-theme"])
        }
    }

    Text {
        text: "Hyprland Styling Variants"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.on_background
        Layout.topMargin: 15
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "variant_animation"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "variant_decoration"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "variant_window"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "variant_layout"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "variant_workspace"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    Text {
        text: "Application Styling & Effects"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.on_background
        Layout.topMargin: 15
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "blur_effect"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "rofi_bordersize"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "rofi_font"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "toggle_kittycursortrail"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }
}
