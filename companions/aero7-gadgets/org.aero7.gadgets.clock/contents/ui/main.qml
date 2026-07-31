import QtQuick
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    implicitWidth: 180
    implicitHeight: 180

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    fullRepresentation: Item {
        Rectangle {
            anchors.fill: parent
            anchors.margins: 6
            radius: width / 2
            border.width: 2
            border.color: "#d7f3ff"
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#d9f5ffdd" }
                GradientStop { position: 0.45; color: "#6da9cadd" }
                GradientStop { position: 1.0; color: "#183e5ddd" }
            }

            Repeater {
                model: 12
                delegate: Rectangle {
                    required property int index
                    x: parent.width / 2 - width / 2
                    y: 10
                    width: 2
                    height: index % 3 === 0 ? 10 : 6
                    radius: 1
                    color: "white"
                    transform: Rotation {
                        origin.x: 1
                        origin.y: parent.parent.width / 2 - 10
                        angle: index * 30
                    }
                }
            }

            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: (root.now.getHours() % 12) * 30 + root.now.getMinutes() / 2
                Rectangle { x: -2; y: -parent.parent.height * 0.26; width: 5; height: parent.parent.height * 0.26; radius: 2; color: "white" }
            }
            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: root.now.getMinutes() * 6
                Rectangle { x: -1; y: -parent.parent.height * 0.35; width: 3; height: parent.parent.height * 0.35; radius: 2; color: "#f4fbff" }
            }
            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: root.now.getSeconds() * 6
                Rectangle { x: 0; y: -parent.parent.height * 0.38; width: 1; height: parent.parent.height * 0.38; color: "#e54538" }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 5
                color: "#f8fdff"
                border.width: 1
                border.color: "#315a78"
            }
        }
    }
}
