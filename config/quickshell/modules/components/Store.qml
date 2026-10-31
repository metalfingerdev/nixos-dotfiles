import QtCore

// Everything remembered lives in one file, and not in the config dir: that's a read-only Nix store path.
Settings {
    location: StandardPaths.writableLocation(StandardPaths.GenericStateLocation) + "/quickshell/island.ini"
}
