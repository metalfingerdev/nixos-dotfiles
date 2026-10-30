pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

// What the lock screen shows, set over IPC (Lock.qml) or in views/Settings.qml, and remembered
// across restarts:
//   image   the background picture, a path (GIFs play)  ""  = the wallpaper
//   avatar  the profile picture, a path (GIFs play)  ""  = a person glyph
//   avatarShape  its frame: "circle" | "square"
//   name    the name under it                      ""  = the full name in the passwd entry
//   info    the line under the name                ""  = user@host
Singleton {
	id: root

	property string image: ""
	property string avatar: ""
	property string avatarShape: "circle"
	property string name: ""
	property string info: ""

	// ~/.local/state/quickshell/island.ini, like the island's settings
	property Settings store: Settings {
		location: StandardPaths.writableLocation(StandardPaths.GenericStateLocation) + "/quickshell/island.ini"
		category: "lock"
		property alias image: root.image
		property alias avatar: root.avatar
		property alias avatarShape: root.avatarShape
		property alias name: root.name
		property alias info: root.info
	}

	readonly property string user: Quickshell.env("USER") ?? ""
	property string fullName: ""
	property string host: ""
	readonly property string defaultInfo: host ? `${user}@${host}` : user
	readonly property string shownName: name || fullName || user
	readonly property string shownInfo: info || defaultInfo

	// Says what's wrong ("" = fine). A relative path can't work: neither IPC nor a text field has a
	// directory to resolve it against.
	function setPicture(key, path) {
		if (path !== "" && !path.startsWith("/")) return `not an absolute path: ${path}`;
		root[key] = path;
		return "";
	}

	// user:x:uid:gid:Full Name,office,...:home:shell
	Process {
		command: ["getent", "passwd", root.user]
		running: root.user !== ""
		stdout: StdioCollector {
			onStreamFinished: root.fullName = (text.split(":")[4] ?? "").split(",")[0];
		}
	}

	FileView {
		path: "/proc/sys/kernel/hostname"
		printErrors: false
		onLoaded: root.host = text().trim();
	}
}
