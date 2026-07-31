import QtQuick
import org.kde.plasma.plasmoid
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation
    implicitWidth: 190
    implicitHeight: 105

    property real activity: Math.max(0, Math.min(1, Number(cpu.value) / 100))

    Sensors.Sensor {
        id: cpu
        sensorId: "cpu/all/usage"
        updateRateLimit: 1000
    }

    fullRepresentation: Rectangle {
        radius: 12
        border.width: 1
        border.color: "#bfe9ff"
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#dff7ffee" }
            GradientStop { position: 0.16; color: "#659fbeee" }
            GradientStop { position: 1.0; color: "#173853ee" }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                text: "CPU activity"
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }
            Rectangle {
                width: parent.width
                height: 30
                radius: 5
                color: "#142d3caa"
                border.width: 1
                border.color: "#8ecce8"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 4
                    width: Math.max(4, (parent.width - 8) * root.activity)
                    radius: 3
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#57e36b" }
                        GradientStop { position: 0.72; color: "#f0dc45" }
                        GradientStop { position: 1.0; color: "#f16b4f" }
                    }
                    Behavior on width { NumberAnimation { duration: 450 } }
                }
            }
            Text {
                text: Math.round(root.activity * 100) + "%"
                color: "#edfaff"
                font.pixelSize: 13
            }
        }
    }
}
