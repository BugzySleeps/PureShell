pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory, 0 … 1, and the CPU's temperature (°C), read from /proc only while something shows them (wanted > 0: the Today card adds 1
// while it's open, and takes it away).
Singleton {
    id: root

    property int wanted: 0
    property real cpu: 0
    property real mem: 0
    property real temp: 0
    property var last: null

    FileView {
        id: stat
        path: "/proc/stat"
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
    }
    // the CPU package's sensor, else the first one there is
    property string zone: "/sys/class/thermal/thermal_zone0"
    Process {
        running: true
        command: ["sh", "-c", "grep -l x86_pkg_temp /sys/class/thermal/thermal_zone*/type 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim())
                root.zone = text.trim().replace(/\/type$/, "")
        }
    }
    FileView {
        id: thermal
        path: root.zone + "/temp"
        printErrors: false
    }
    Timer {
        running: root.wanted > 0
        interval: 1500
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] || 0), total = f.reduce((a, b) => a + b, 0);
            if (root.last)
                root.cpu = Math.max(0, Math.min(1, 1 - (idle - root.last[0]) / Math.max(1, total - root.last[1])));
            root.last = [idle, total];
            const m = k => Number((new RegExp("^" + k + ":\\s+(\\d+)", "m").exec(meminfo.text()) ?? [0, 0])[1]);
            root.mem = 1 - m("MemAvailable") / Math.max(1, m("MemTotal"));
            thermal.reload();
            root.temp = (Number(thermal.text()) || 0) / 1000;
        }
    }
}
