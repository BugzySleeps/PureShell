pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification server: every notification is kept (the newest first) for the control centre, and
// announced (arrived) so the island can show it.
Singleton {
    id: root

    property var list: []
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
            root.list = [n].concat(root.list.filter(x => x !== n)).slice(0, 50);
            n.closed.connect(() => root.list = root.list.filter(x => x !== n));
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.arrived(n);
        }
    }

    function clear() {
        for (const n of list.slice())
            n.dismiss();
    }
}
