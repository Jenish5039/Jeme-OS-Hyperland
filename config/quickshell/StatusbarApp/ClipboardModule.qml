import Quickshell
import QtQuick

// Opens the clipboard manager / history.
BarButton {
    iconSrc: "../shared/icons/clipboard.svg"
    onClicked: {
        Quickshell.execDetached(["bash", "-c",
            "qs ipc call statusbar collapse 2>/dev/null; " + Quickshell.env("HOME") + "/.config/ml4w/scripts/ml4w-cliphist"])
    }
}
