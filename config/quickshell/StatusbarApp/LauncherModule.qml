import Quickshell
import QtQuick

// Opens the application launcher.
BarButton {
    iconSrc: "../shared/icons/launcher.svg"
    onClicked: {
        Quickshell.execDetached(["bash", "-c",
            "qs ipc call statusbar collapse 2>/dev/null; " + Quickshell.env("HOME") + "/.config/hypr/scripts/launcher.sh"])
    }
}
