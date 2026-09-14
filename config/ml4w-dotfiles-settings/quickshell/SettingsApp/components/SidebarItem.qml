import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: root

    property string text: ""
    property bool active: false
    signal clicked()

    implicitWidth: parent ? parent.width : 220
    implicitHeight: 40
    radius: 8

    color: active 
        ? Theme.primary 
        : (mouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent")

    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 0

        Text {
            text: root.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: root.active
            color: root.active ? Theme.on_primary : Theme.on_background
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
