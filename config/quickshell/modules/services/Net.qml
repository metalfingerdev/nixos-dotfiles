pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// Knows NetworkManager (through Quickshell.Networking). Knows nothing about the island.
//
// networks: nearby Wi-Fi networks, the connected one first, then strongest. Hidden SSIDs (no
//           name) are skipped. Scanning costs power, so it only runs while someone holds a
//           scan(true): the Network view does, while it's on screen.
Singleton {
    id: root

    readonly property bool available: Networking.backend !== NetworkBackendType.None

    readonly property var devices: Array.from(Networking.devices.values)
    readonly property var wifi:  devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired) ?? null

    // ---- Wi-Fi ----
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiBlocked: !Networking.wifiHardwareEnabled   // rfkill / hardware switch
    function setWifi(on) { Networking.wifiEnabled = on }

    readonly property var networks: {
        if (!wifi) return []
        return Array.from(wifi.networks.values)
            .filter(n => n.name !== "")
            .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
    }
    readonly property var current: networks.find(n => n.connected) ?? null

    // ---- Ethernet ----
    readonly property bool ethernet: wired?.connected ?? false
    readonly property int linkSpeed: wired?.linkSpeed ?? 0                // Mb/s

    // ---- one line for headers ----
    readonly property string summary: {
        if (!available) return "NetworkManager isn't running"
        if (current) return current.name
        if (ethernet) return "Ethernet"
        if (wifiBlocked) return "Wi-Fi is blocked"
        if (!wifiEnabled) return "Wi-Fi is off"
        return "Not connected"
    }

    // ---- scanning: counted, so two holders can't switch it off under each other ----
    property int scanners: 0
    function scan(on) { scanners = Math.max(0, scanners + (on ? 1 : -1)) }
    Binding {
        when: root.wifi !== null
        target: root.wifi
        property: "scannerEnabled"
        value: root.scanners > 0 && root.wifiEnabled
    }

    // ---- actions ----
    function secured(n)      { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe }
    // a secured network NetworkManager has no saved profile for: ask for the password first
    function needsPassword(n) { return secured(n) && !n.known }
    function busy(n)          { return n.stateChanging }

    function connect(n, psk)  { if (psk) n.connectWithPsk(psk); else n.connect() }
    function disconnect(n)    { n.disconnect() }
    function forget(n)        { n.forget() }

    // why the last attempt failed, for the view
    function failure(reason) {
        if (reason === ConnectionFailReason.NoSecrets) return "Wrong password"
        if (reason === ConnectionFailReason.WifiAuthTimeout) return "Timed out"
        if (reason === ConnectionFailReason.WifiNetworkLost) return "Network lost"
        return "Couldn't connect"
    }
}
