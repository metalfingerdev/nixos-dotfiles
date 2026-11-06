pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.components

// "" means the default: the wallpaper, a person glyph, the full name in passwd, user@host.
Singleton {
	id: root

	property string image: ""
	property string avatar: ""
	property string avatarShape: "circle"
	property string name: ""
	property string info: ""

	property Store store: Store {
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
