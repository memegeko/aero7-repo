import QtQuick
import QtQuick.Controls
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    implicitWidth: 230
    implicitHeight: 190

    fullRepresentation: Rectangle {
        radius: 9
        color: "#fff4a9f2"
        border.width: 1
        border.color: "#b79d45"
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#fffbc9f4" }
            GradientStop { position: 1.0; color: "#f1d86df4" }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 28
            radius: 9
            color: "#ffffff66"

            Text {
                anchors.centerIn: parent
                text: "Aero7 Notes"
                color: "#58440b"
                font.bold: true
            }
        }

        TextArea {
            anchors.fill: parent
            anchors.topMargin: 30
            anchors.margins: 9
            text: plasmoid.configuration.noteText
            color: "#3f350f"
            wrapMode: TextEdit.Wrap
            background: Item { }
            onTextChanged: plasmoid.configuration.noteText = text
        }
    }
}
