import Quickshell
import QtQuick

// ML4W logo -> toggles the Sidebar app via IPC.
BarButton {
    iconSrc: Quickshell.env("HOME") + "/.config/quickshell/shared/my-logo.svg"
    colorize: false
    onClicked: {
        Quickshell.execDetached(["qs", "ipc", "call", "sidebar", "toggle"])
    }
}
