import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme

Rectangle {
    id: root

    property string title: ""
    property string description: ""
    property string buttonText: "Open"
    property bool isPrimary: false
    signal clicked()

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
                text: root.description
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.on_background
                opacity: 0.8
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                visible: root.description !== ""
            }
        }

        Button {
            id: actionBtn
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            text: root.buttonText
            hoverEnabled: true

            contentItem: Text {
                text: actionBtn.text
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                color: root.isPrimary ? Theme.on_primary : Theme.primary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                leftPadding: 16
                rightPadding: 16
                topPadding: 8
                bottomPadding: 8
            }

            background: Rectangle {
                radius: 8
                color: root.isPrimary 
                    ? (actionBtn.hovered ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
                    : (actionBtn.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent")
                border.color: Theme.primary
                border.width: 1
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }

            onClicked: root.clicked()
        }
    }
}
