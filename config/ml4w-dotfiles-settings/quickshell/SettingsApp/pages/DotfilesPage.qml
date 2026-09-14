import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.CustomTheme
import "../components"

ColumnLayout {
    id: root

    spacing: 16
    Layout.fillWidth: true

    property string dotfilesId: "com.ml4w.dotfiles"

    Process {
        command: [Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-dotfiles-id"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text.trim();
                if (out !== "") root.dotfilesId = out;
            }
        }
    }

    SectionHeader {
        title: "Dotfiles"
        subtitle: "Manage Fedora system package updates, create configuration snapshots, and inspect installation metadata."
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Check System Package Updates"
        description: "Check Fedora system package manager (DNF) for available software updates."
        buttonText: "System Updates"
        isPrimary: true
        onClicked: Quickshell.execDetached(["kitty", "--class", "dotfiles-floating", "-e", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-check-system-updates"])
    }

    ActionCard {
        Layout.fillWidth: true
        title: "Create Dotfiles Snapshot"
        description: "Create a compressed backup archive of your current dotfiles and active configuration."
        buttonText: "Create Snapshot"
        onClicked: Quickshell.execDetached(["kitty", "--class", "dotfiles-floating", "-e", Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-snapshot"])
    }

    // Dotfiles Metadata Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: infoColumn.implicitHeight + 28
        color: Theme.background
        border.color: Theme.primary
        border.width: 1
        radius: 10
        Layout.topMargin: 10

        ColumnLayout {
            id: infoColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Text {
                text: "Dotfiles Profile Information"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
                color: Theme.primary
            }

            Text {
                text: "• Profile: " + root.dotfilesId + "\n• Base Location: ~/.mydotfiles/com.ml4w.dotfiles\n• Config Symlinks: ~/.config/hypr, ~/.config/ml4w, ~/.config/quickshell"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.on_background
                opacity: 0.8
                lineHeight: 1.4
            }
        }
    }
}
