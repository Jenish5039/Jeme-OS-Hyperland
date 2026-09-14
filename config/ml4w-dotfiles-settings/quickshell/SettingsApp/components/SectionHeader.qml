import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

ColumnLayout {
    id: root

    property string title: ""
    property string subtitle: ""

    spacing: 4
    Layout.fillWidth: true
    Layout.bottomMargin: 15

    Text {
        text: root.title
        font.family: Theme.fontFamily
        font.pixelSize: 26
        font.bold: true
        color: Theme.on_background
        Layout.fillWidth: true
    }

    Text {
        text: root.subtitle
        font.family: Theme.fontFamily
        font.pixelSize: 13
        color: Theme.on_background
        opacity: 0.75
        visible: root.subtitle !== ""
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
}
