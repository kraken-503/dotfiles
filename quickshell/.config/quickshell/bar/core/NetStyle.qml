pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property var styles: ({
        wifiOff:      { icon: "󰀝",         color: Theme.subtext, opacity: 0.35 },  // Wi-Fi radio off, no VPN
        disconnected: { icon: "",         color: Theme.subtext, opacity: 0.6  },  // radio on, no network
        connecting:   { icon: "󱛄",         color: Theme.blue,    opacity: 1.0  },  // connecting to Wi-Fi or VPN
        connected:    { icon: "󰖩",         color: Theme.text,    opacity: 1.0  },  // Wi-Fi connected
        connectedVpn: { icon: "󰖂",  color: Theme.green,   opacity: 1.0  },  // Wi-Fi connected + VPN active
        vpnOnly:      { icon: "󰖂",         color: Theme.green,   opacity: 1.0  }   // VPN active, no Wi-Fi (e.g. Ethernet)
    })

    readonly property bool vpn: Vpn.activeProfiles.length > 0
    readonly property bool wifi: Wifi.ssid !== ""
    readonly property bool connecting: Wifi.message.indexOf("Connecting") === 0
                                    || Vpn.message.indexOf("Connecting") === 0

    readonly property string state:
        connecting ? "connecting"
        : vpn ? (wifi ? "connectedVpn" : "vpnOnly")
        : wifi ? "connected"
        : Wifi.enabled ? "disconnected" : "wifiOff"

    readonly property var current: styles[state]
}
