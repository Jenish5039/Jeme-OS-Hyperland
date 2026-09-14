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
        title: "Applications"
        subtitle: "Set default commands executed by Jeme OS desktop keybindings and launcher shortcuts. Press Enter or click Save to apply changes."
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "default_terminal"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "default_browser"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "default_filemanager"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "default_email"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "default_calculator"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "default_networkmanager"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "default_bluetooth"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "default_software"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "default_screenshoteditor"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "default_systemmonitor"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }

    SettingField {
        Layout.fillWidth: true
        settingId: "default_aur"
        settingsData: root.settingsData
        scriptPath: root.scriptPath
        profile: root.profile
    }
}
