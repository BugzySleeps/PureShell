pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// What's open, and the screen things go on (the focused one). The ipc answers the same calls as liquid's, so the
// keybinds work in either shell:
//   qs -c pureshell ipc call launcher toggle | open <text>     (SUPER + R; "= " maths, ": " emoji, "v " clipboard)
//   qs -c pureshell ipc call panel toggle quick|notifs|today|music    (SUPER + A, SUPER + N, a click on the clock)
//   qs -c pureshell ipc call widgets edit                        (SUPER + W: the workbench)
Singleton {
    id: root

    readonly property var screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    // one of: "" · "today" (the island opened into the Today card) · "music" (the same, on its player) · "quick"
    // (quick settings) · "notifs"
    property string panel: ""
    function toggle(name) {
        panel = panel === name ? "" : name;
        if (panel)
            launcher = false;
    }

    property bool launcher: false
    property string launcherText: ""             // what the launcher opens with (a mode's prefix)
    function toggleLauncher(text) {
        if (launcher && launcherText === text) {
            launcher = false;
            return;
        }
        launcherText = text;
        launcher = true;
        panel = "";
    }

    // Claude Code finished, or is waiting on you (config/rice/claude-island, a Claude Code hook)
    signal claude(string kind, string project, string text)
    IpcHandler {
        target: "island"
        function claude(kind: string, project: string, text: string): void {
            root.claude(kind, project, text);
        }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.toggleLauncher("");
        }
        function open(text: string): void {
            root.launcher = false;
            root.toggleLauncher(text === ":" ? ": " : text);
        }
    }
    IpcHandler {
        target: "panel"
        function toggle(name: string): void {
            root.toggle(name === "control" ? "notifs" : name);   // (liquid's SUPER + N says "control")
        }
        function close(): void {
            root.panel = "";
        }
    }
}
