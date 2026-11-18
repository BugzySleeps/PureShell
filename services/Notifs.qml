pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification server: every notification is kept (the newest first) for the control centre, and
// announced (arrived) so the island can show it.
Singleton {
    id: root

    property var list: []
    property var times: ({})                     // id → when it came (ms)
    property bool dnd: false
    signal arrived(var n)

    NotificationServer {
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true
        onNotification: n => {
            n.tracked = true;
            root.times[n.id] = Date.now();
            root.list = [n].concat(root.list.filter(x => x !== n)).slice(0, 50);
            n.closed.connect(() => root.list = root.list.filter(x => x !== n));
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.arrived(n);
        }
    }

    // "now", "5m", "2h", "3d"
    function ago(n) {
        const s = (Date.now() - (times[n?.id] ?? Date.now())) / 1000;
        return s < 60 ? "now" : s < 3600 ? Math.floor(s / 60) + "m" : s < 86400 ? Math.floor(s / 3600) + "h" : Math.floor(s / 86400) + "d";
    }
    // grouped by app, the app with the newest first: [{ app, icon, items: [...] }]
    readonly property var groups: {
        const out = [];
        for (const n of list) {
            const app = n.appName || "Notifications";
            let g = out.find(x => x.app === app);
            if (!g) {
                g = { app, icon: n.appIcon, items: [] };
                out.push(g);
            }
            g.items.push(n);
        }
        return out;
    }

    function clear() {
        for (const n of list.slice())
            n.dismiss();
    }
}
