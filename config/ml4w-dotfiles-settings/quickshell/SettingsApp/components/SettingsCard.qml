import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: root

    property string title: ""
    property string instructions: ""
    default property alias content: controlArea.data

    implicitWidth: 500
    implicitHeight: Math.max(76, contentRow.implicitHeight + 24)
    radius: 10
    color: Theme.background
    border.color: Theme.primary
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
                color: Theme.primary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: root.instructions
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.on_background
                opacity: 0.8
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
