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
            Quickshell.execDetached(["jeme-settings", "toggle"])
        }
        function open(): void {
            Quickshell.execDetached(["jeme-settings", "open"])
        }
        function close(): void {
            Quickshell.execDetached(["jeme-settings", "close"])
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