import QtQuick

Item {}

/*
Item {
    width: 800
    height: 40

    HyprlandIpc {
        id: hyprIpc
    }

    // This gets updated automatically from Hyprland
    ListView {
        id: workspaceList
        anchors.fill: parent
        orientation: Qt.Horizontal
        model: hyprIpc.workspaces

        delegate: Rectangle {
            width: 80
            height: 40
            color: modelData.active ? "#88c0d0" : "#3b4252"

            Text {
                anchors.centerIn: parent
                text: modelData.name  // Or whatever property exists
                color: "white"
            }
        }
    }
}
*/
