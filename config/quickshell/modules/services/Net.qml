pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// Networks sort by signal in quarters, which keeps the order from reshuffling on every scan.
// Scanning costs power, so it only runs while someone holds a scan(true).
// A failed first attempt leaves a broken profile behind: it is forgotten.
Singleton {
    id: root

    readonly property bool available: Networking.backend !== NetworkBackendType.None

    readonly property var devices: Array.from(Networking.devices.values)
    readonly property var wifi:  devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired) ?? null

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiBlocked: !Networking.wifiHardwareEnabled   // rfkill / hardware switch
    function setWifi(on) { Networking.wifiEnabled = on }

    readonly property var networks: {
        if (!wifi) return []
        return Array.from(wifi.networks.values)
            .filter(n => n.name !== "")
            .sort((a, b) => (b.connected - a.connected)
                         || (Math.floor(b.signalStrength * 4) - Math.floor(a.signalStrength * 4))
                         || a.name.localeCompare(b.name))
    }
    readonly property var current: networks.find(n => n.connected) ?? null

    readonly property bool ethernet: wired?.connected ?? false
    readonly property int linkSpeed: wired?.linkSpeed ?? 0                // Mb/s

    readonly property string summary: {
        if (!available) return "NetworkManager isn't running"
        if (current) return current.name
        if (ethernet) return "Ethernet"
        if (wifiBlocked) return "Wi-Fi is blocked"
        if (!wifiEnabled) return "Wi-Fi is off"
        return "Not connected"
    }

    function glyph(strength) {
        if (strength >= 0.75) return "signal_wifi_4_bar"
        if (strength >= 0.5)  return "network_wifi_3_bar"
        if (strength >= 0.25) return "network_wifi_2_bar"
        if (strength > 0)     return "network_wifi_1_bar"
        return "signal_wifi_0_bar"
    }
    readonly property string icon: current ? glyph(current.signalStrength)
                                 : ethernet ? "lan" : !wifiEnabled ? "wifi_off" : "wifi_find"

    // Counted, so two holders can't switch it off under each other.
    property int scanners: 0
    function scan(on) { scanners = Math.max(0, scanners + (on ? 1 : -1)) }
    Binding {
        when: root.wifi !== null
        target: root.wifi
        property: "scannerEnabled"
        value: root.scanners > 0 && root.wifiEnabled
    }

    function secured(n)      { return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe }
    // a secured network NetworkManager has no saved profile for: ask for the password first
    function needsPassword(n) { return secured(n) && !n.known }
    function busy(n)          { return n.stateChanging }

    function disconnect(n)    { n.disconnect() }
    function forget(n)        { n.forget() }

    property var attempt: null
    property bool attemptWasKnown: false
    property string lastError: ""
    property int errorMs: 6000

    function connect(n, psk) {
        lastError = ""
        attempt = n
        attemptWasKnown = n.known
        if (psk) n.connectWithPsk(psk); else n.connect()
    }

    Connections {
        target: root.attempt
        function onConnectedChanged() { if (root.attempt.connected) root.attempt = null }
        function onConnectionFailed(reason) {
            root.lastError = root.attempt.name + ": " + root.failure(reason)
            if (!root.attemptWasKnown) root.attempt.forget()
            root.attempt = null
        }
    }
    Timer {
        running: root.lastError !== ""
        interval: root.errorMs
        onTriggered: root.lastError = ""
    }

    function failure(reason) {
        if (reason === ConnectionFailReason.NoSecrets) return "Wrong password"
        if (reason === ConnectionFailReason.WifiAuthTimeout) return "Timed out"
        if (reason === ConnectionFailReason.WifiNetworkLost) return "Network lost"
        return "Couldn't connect"
    }
}
