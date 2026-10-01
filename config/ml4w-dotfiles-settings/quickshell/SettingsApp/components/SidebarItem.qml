import QtQuick
import QtQuick.Layouts
import "../../CustomTheme"

Rectangle {
    id: root

    property string text: ""
    property bool active: false
    signal clicked()

    implicitWidth: parent ? parent.width : 220
    implicitHeight: 40
    radius: 8

    color: active 
        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22)
        : (mouseArea.containsMouse ? Theme.surface_container_high : "transparent")

    border.color: active ? Theme.primary : "transparent"
    border.width: active ? 1 : 0

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
            color: root.active ? Theme.primary : Theme.on_surface
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
