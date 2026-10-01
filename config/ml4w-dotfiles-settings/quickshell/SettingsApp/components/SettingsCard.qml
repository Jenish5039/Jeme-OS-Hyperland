import QtQuick
import QtQuick.Layouts
import "../../CustomTheme"

Rectangle {
    id: root

    property string title: ""
    property string instructions: ""
    default property alias content: controlArea.data

    implicitWidth: 500
    implicitHeight: Math.max(76, contentRow.implicitHeight + 24)
    radius: 10
    color: Theme.surface_container
    border.color: Theme.outline_variant
    border.width: 1

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: root.title
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.bold: true
                color: Theme.on_surface
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: root.instructions
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.on_surface_variant
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                visible: root.instructions !== ""
            }
        }

        Item {
            id: controlArea
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.preferredWidth: 220
            Layout.preferredHeight: 40
        }
    }
}
