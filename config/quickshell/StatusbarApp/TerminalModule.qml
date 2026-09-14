import Quickshell
import QtQuick

// Opens the configured terminal.
BarButton {
    iconSrc: "../shared/icons/terminal.svg"
    onClicked: {
        Quickshell.execDetached(["bash", "-c",
            "qs ipc call statusbar collapse 2>/dev/null; " + Quickshell.env("HOME") + "/.config/ml4w/settings/terminal.sh"])
    }
}
