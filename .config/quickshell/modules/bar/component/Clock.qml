import Quickshell
import Quickshell.Io
import QtQuick

Item {

    Text {
        id: clock
    }

    Process {
        id: dateProc
        command: ["date", "+%d/%m/%Y %H:%M"]
        running: true
        stdout: StdioCollector {

            onStreamFinished: clock.text = this.text
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: dateProc.running = true
    }
}
