pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// sysfs has no change events, so this polls each device's `uevent` file (every value in one read).
// No UPower needed. Each threshold warns once per discharge.
Singleton {
    id: root

    property int lowAt: 15
    property int criticalAt: 5
    property int pollMs: 2000

    property string battery: ""
    property string charger: ""
    readonly property bool present: battery !== ""

    property int percent: -1             // -1 = not read yet
    property string status: ""
    property bool plugged: false
    property real watts: 0               // power draw (or charge rate); 0 = the battery doesn't say
    property real energyWh: 0
    property real fullWh: 0
    property real designWh: 0
    property int cycles: -1

    readonly property bool charging: status === "Charging"
    readonly property bool full: status === "Full" || (plugged && percent >= 100)
    readonly property bool discharging: status === "Discharging" || (!plugged && !charging && present)
    readonly property int health: designWh > 0 ? Math.round(fullWh * 100 / designWh) : -1

    readonly property int minutesLeft: {
        if (watts <= 0) return -1
        if (charging) return Math.round((fullWh - energyWh) / watts * 60)
        if (discharging) return Math.round(energyWh / watts * 60)
        return -1
    }

    readonly property string level: percent <= criticalAt ? "critical" : percent <= lowAt ? "low" : "ok"
    // a Config role, by name: services stay free of the theme. "" = the viewer's own colour
    readonly property string tone: charging || full ? "good" : level === "critical" ? "bad" : level === "low" ? "warn" : ""

    readonly property string glyph: {
        if (!present) return "power"
        if (charging) return "battery_charging_full"
        if (full || percent >= 95) return "battery_full"
        if (level === "critical") return "battery_alert"
        return "battery_" + Math.max(0, Math.min(6, Math.floor(percent / 15))) + "_bar"
    }

    signal warn(bool critical)

    function duration(minutes) {
        if (minutes < 0) return ""
        const h = Math.floor(minutes / 60), m = minutes % 60
        return h > 0 ? h + " h " + String(m).padStart(2, "0") + " min" : m + " min"
    }

    Process {
        running: true
        command: ["sh", "-c",
            "for d in /sys/class/power_supply/*; do t=$(cat \"$d/type\" 2>/dev/null); "
          + "case \"$t\" in Battery) [ \"$(cat \"$d/scope\" 2>/dev/null)\" = Device ] || echo \"bat $d\";; "
          + "Mains) echo \"ac $d\";; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const [kind, path] = line.split(" ")
                    if (kind === "bat" && root.battery === "") root.battery = path
                    if (kind === "ac" && root.charger === "")  root.charger = path
                }
            }
        }
    }

    function parse(text) {
        const out = {}
        for (const line of text.split("\n")) {
            const i = line.indexOf("=")
            if (i > 0) out[line.slice(0, i).replace("POWER_SUPPLY_", "")] = line.slice(i + 1)
        }
        return out
    }
    // energy in µWh, or charge in µAh (some batteries only report that) times the voltage
    function wh(u, key) {
        if (u["ENERGY_" + key] !== undefined) return u["ENERGY_" + key] / 1e6
        if (u["CHARGE_" + key] !== undefined && u.VOLTAGE_NOW !== undefined)
            return u["CHARGE_" + key] / 1e6 * u.VOLTAGE_NOW / 1e6
        return 0
    }

    property int lastPercent: -1
    function update(u) {
        status = u.STATUS ?? ""
        energyWh = wh(u, "NOW")
        fullWh = wh(u, "FULL")
        designWh = wh(u, "FULL_DESIGN")
        cycles = u.CYCLE_COUNT !== undefined ? parseInt(u.CYCLE_COUNT) : -1
        if (u.POWER_NOW !== undefined) watts = Math.abs(u.POWER_NOW) / 1e6
        else if (u.CURRENT_NOW !== undefined && u.VOLTAGE_NOW !== undefined)
            watts = Math.abs(u.CURRENT_NOW) / 1e6 * u.VOLTAGE_NOW / 1e6
        else watts = 0
        if (charger === "") plugged = status === "Charging" || status === "Full"

        const p = u.CAPACITY !== undefined ? parseInt(u.CAPACITY)
                : fullWh > 0 ? Math.round(energyWh * 100 / fullWh) : -1
        // crossing a threshold downwards, on battery: warn once
        if (lastPercent >= 0 && discharging) {
            if (p <= criticalAt && lastPercent > criticalAt) warn(true)
            else if (p <= lowAt && lastPercent > lowAt) warn(false)
        }
        lastPercent = p
        percent = p
    }

    FileView {
        id: batFile
        path: root.battery === "" ? "" : root.battery + "/uevent"
        printErrors: false
        onLoaded: root.update(root.parse(text()))
    }

    FileView {
        id: acFile
        path: root.charger === "" ? "" : root.charger + "/online"
        printErrors: false
        onLoaded: root.plugged = text().trim() === "1"
    }

    Timer {
        interval: root.pollMs
        repeat: true
        running: root.present
        triggeredOnStart: true
        onTriggered: { acFile.reload(); batFile.reload() }
    }
}
