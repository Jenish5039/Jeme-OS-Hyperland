//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import "PowerApp"
import "SidebarApp"
import "CalendarApp"
import "WallpaperApp"
import "WallpaperEngineApp"
import "StatusbarApp"
import "DockApp"
import "ConnectivityApp"
import "AudioApp"
import "CustomTheme"

ShellRoot {
    // Test IPC tools: qs ipc show

    IpcHandler {
        target: "theme-manager" 
        function reload(): void {
            Theme.reloadTheme()
        }
    }

    IpcHandler {
        target: "welcome"
        function toggle(): void {
            Quickshell.execDetached(["bash", "-c", "qs -p " + Quickshell.env("HOME") + "/.local/share/ml4w-dotfiles-settings/quickshell ipc call settings toggle"])
        }
        function open(): void {
            Quickshell.execDetached(["bash", "-c", "qs -p " + Quickshell.env("HOME") + "/.local/share/ml4w-dotfiles-settings/quickshell ipc call settings open"])
        }
        function close(): void {
            Quickshell.execDetached(["bash", "-c", "qs -p " + Quickshell.env("HOME") + "/.local/share/ml4w-dotfiles-settings/quickshell ipc call settings close"])
        }
        function isOpen(): bool { return false }
    }
    PowerWindow {}
    SidebarWindow {}
    CalendarWindow {}
    WallpaperWindow {}
    WallpaperEngineWindow {}
    StatusbarWindow {}
    ConnectivityPopup {}
    AudioPopup {}
    // Creates the dock window only while the dock is enabled in dock.json.
    DockLoader {}
}