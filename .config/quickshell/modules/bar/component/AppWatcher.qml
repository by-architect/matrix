import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    
    // Thresholds
    property real cpuThreshold: 30.0
    property real memoryThreshold: 15.0
    
    // Maximum usage values for color calculation
    property real maxCpu: 100.0
    property real maxMemory: 100.0
    
    // Icon paths (you can change these)
    property string cpuIcon: "root:/assets/icons/cpuIcon.png"
    property string memoryIcon: "root:/assets/icons/memoryIcon.png"


    property string cpuIconBlack: "root:/assets/icons/cpuIconBlack.png"
    property string memoryIconBlack: "root:/assets/icons/memoryIconBlack.png"
    
    // Box styling
    property real boxRadius: 5
    
    // Process data class
    function createProc(processId, name, usage, type) {
        return {
            processId: processId,
            name: name,
            usage: usage,
            type: type
        }
    }
    
    // List to store all high usage processes
    property var highUsageProcesses: []
    
    // Function to get process name from full path
    function getProcessName(fullPath) {
        var parts = fullPath.split('/')
        return parts[parts.length - 1]
    }
    
    // Function to calculate color based on usage
    function getUsageColor(usage, type) {
        var minThreshold = type === "cpu" ? cpuThreshold : memoryThreshold
        var maxUsage = type === "cpu" ? maxCpu : maxMemory
        
        // Normalize usage between threshold and max (0.0 to 1.0)
        var normalizedUsage = Math.min((usage - minThreshold) / (maxUsage - minThreshold), 1.0)
        
        // Interpolate between yellow (#FFFF00) and red (#FF0000)
        var red = 255
        var green = Math.round(255 * (1.0 - normalizedUsage))
        var blue = 0
        
        return Qt.rgba(red / 255, green / 255, blue / 255, 1.0)
    }
    
    // Function to get icon path based on type
    function getIconPath(type) {
        switch(type) {
            case "cpu": return cpuIcon
            case "mem": return memoryIcon
            default: return ""
        }
    }
    
    // Function to parse and filter processes
    function parseProcesses(output) {
        var processes = []
        var lines = output.split('\n')
        
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line === "") continue
            
            var parts = line.split(/\s+/)
            if (parts.length < 4) continue
            
            var processId = parts[0]
            var processPath = parts[1]
            var cpuUsage = parseFloat(parts[2])
            var memUsage = parseFloat(parts[3])
            
            var processName = getProcessName(processPath)
            
            // Check CPU threshold
            if (cpuUsage > cpuThreshold) {
                processes.push(createProc(processId, processName, cpuUsage, "cpu"))
            }
        }
        
        return processes
            
            // Check Memory threshold
            if (memUsage > memoryThreshold) {
                processes.push(createProc(processId, processName, memUsage, "mem"))
            }
    }
    
    // Row to display processes as individual boxes
    Row {
        anchors.fill: parent
        spacing: 10
        
        Repeater {
            model: root.highUsageProcesses
            delegate: Rectangle {
                width: processRow.width + 20
                height: processRow.height + 10
                border.color: root.getUsageColor(modelData.usage, modelData.type)
                border.width: 2
                color: "transparent"
                radius: root.boxRadius
                
                Row {
                    id: processRow
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Image {
                        width: 16
                        height: 16
                        source: root.getIconPath(modelData.type)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Text {
                        text: modelData.name + " " + modelData.usage.toFixed(1) + "%"
                        font.family: "monospace"
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
    
    // Process to get system data
    Process {
        id: systemMonitor
        command: ["sh", "-c", "ps aux --sort=-%cpu | awk 'NR>1 {print $2, $11, $3, $4}' | head -20"]
        running: true
        
        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text.trim()
                root.highUsageProcesses = root.parseProcesses(output)
            }
        }
    }
    
    // Timer to refresh data
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: systemMonitor.running = true
    }
}
