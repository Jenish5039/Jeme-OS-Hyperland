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
        title: "System"
        subtitle: "Core system variants, desktop environment, display manager, and system tools."
    }

    Text {
        text: "Hyprland Configuration Variants"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.on_background
        Layout.topMargin: 5
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "variant_keybinding"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "variant_monitor"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "variant_environment"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "variant_windowrule"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "system_launcher"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    Text {
        text: "System Administration & Tools"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: Theme.on_background
        Layout.topMargin: 15
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Display Manager (SDDM)"
        description: "Configure or reinstall the ML4W SDDM login theme."
        buttonText: "Run Installer"
        onClicked: Quickshell.execDetached(["kitty", "--class", "dotfiles-floating", "-e", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-install-sddm"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Change User Shell"
        description: "Switch your interactive shell between Bash, Zsh, or Fish."
        buttonText: "Change Shell"
        onClicked: Quickshell.execDetached(["kitty", "--class", "dotfiles-floating", "-e", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-change-shell"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Network Manager Applet"
        description: "Toggle the nm-applet status notifier item in the system tray."
        buttonText: "Toggle Applet"
        onClicked: Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-toggle-nmapplet"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "System Hardware & OS Info"
        description: "Launch terminal system specifications and hardware overview."
        buttonText: "View Specs"
        onClicked: Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-hyprsysteminfo"])
    }
}
