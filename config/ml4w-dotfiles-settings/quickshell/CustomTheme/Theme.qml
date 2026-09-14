pragma Singleton
import QtQuick
import Quickshell 
import Quickshell.Io 

QtObject { 
    id: root
    
    // Static properties
    readonly property string fontFamily: "Fira Sans Semibold"
    
    // Dynamic color properties
    property color background: "#0e1513"
    property color error: "#ffb4ab"
    property color error_container: "#93000a"
    property color inverse_on_surface: "#2b3230"
    property color inverse_primary: "#006b5e"
    property color inverse_surface: "#dee4e1"
    property color on_background: "#dee4e1"
    property color on_error: "#690005"
    property color on_error_container: "#ffdad6"
    property color on_primary: "#003730"
    property color on_primary_container: "#9ff2e1"
    property color on_primary_fixed: "#00201b"
    property color on_primary_fixed_variant: "#005046"
    property color on_secondary: "#1c3530"
    property color on_secondary_container: "#cde8e1"
    property color on_secondary_fixed: "#06201b"
    property color on_secondary_fixed_variant: "#334b46"
    property color on_surface: "#dee4e1"
    property color on_surface_variant: "#bec9c5"
    property color on_tertiary: "#133348"
    property color on_tertiary_container: "#cae6ff"
    property color on_tertiary_fixed: "#001e30"
    property color on_tertiary_fixed_variant: "#2c4a60"
    property color outline: "#899390"
    property color outline_variant: "#3f4946"
    property color primary: "#83d5c5"
    property color primary_container: "#005046"
    property color primary_fixed: "#9ff2e1"
    property color primary_fixed_dim: "#83d5c5"
    property color scrim: "#000000"
    property color secondary: "#b1ccc5"
    property color secondary_container: "#334b46"
    property color secondary_fixed: "#cde8e1"
    property color secondary_fixed_dim: "#b1ccc5"
    property color shadow: "#000000"
    property color source_color: "#315b53"
    property color surface: "#0e1513"
    property color surface_bright: "#343b39"
    property color surface_container: "#1b211f"
    property color surface_container_high: "#252b2a"
    property color surface_container_highest: "#303634"
    property color surface_container_low: "#171d1b"
    property color surface_container_lowest: "#090f0e"
    property color surface_dim: "#0e1513"
    property color surface_tint: "#83d5c5"
    property color surface_variant: "#3f4946"
    property color tertiary: "#accae5"
    property color tertiary_container: "#2c4a60"
    property color tertiary_fixed: "#cae6ff"
    property color tertiary_fixed_dim: "#accae5"

    property var themeReader: Process {
        id: reader
        command: ["cat", Quickshell.env("HOME") + "/.local/share/ml4w-dotfiles-settings/colors/colors.json"]
        
        // REQUIRED: Quickshell needs this to parse the binary stream into text
        stdout: StdioCollector {
            onStreamFinished: {
                // "this.text" contains the full output of the cat command
                var output = this.text.trim();
                
                if (output !== "") {
                    try {
                        var newColors = JSON.parse(output);
                        for (var key in newColors) {
                            if (root.hasOwnProperty(key) && key !== "objectName") {
                                root[key] = newColors[key];
                            }
                        }
                        console.log("Theme colors loaded successfully!");
                    } catch (e) {
                        console.log("Failed to parse theme JSON: " + e);
                    }
                }
            }
        }
    }

    function reloadTheme() {
        // Toggle false then true to guarantee Quickshell restarts the cat process
        reader.running = false;
        reader.running = true;
    }

    // Load the JSON colors automatically when Quickshell starts
    Component.onCompleted: reloadTheme()
}