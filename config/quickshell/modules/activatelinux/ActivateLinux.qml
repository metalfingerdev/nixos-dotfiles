import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.components

// A text OSD in every screen's bottom-right corner, over everything (fullscreen windows too), and
// click-through. By default it says "Activate Linux". Config.activateLinux turns it off.
Scope {
	id: root

	property string title: "Activate Linux"
	property string subtitle: "Go to Settings to activate Linux"

	Variants {
		// Create the panel once on each monitor.
		model: Config.activateLinux ? Quickshell.screens : []

		PanelWindow {
			id: w

			required property var modelData
			screen: modelData

			anchors {
				right: true
				bottom: true
			}

			margins {
				right: 50
				bottom: 50
			}

			implicitWidth: content.width
			implicitHeight: content.height

			color: "transparent"

			// Give the window an empty click mask so all clicks pass through it.
			mask: Region {}

			// Use the wlroots specific layer property to ensure it displays over
			// fullscreen windows.
			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.namespace: "quickshell:activatelinux"

			ColumnLayout {
				id: content

				Text {
					text: root.title
					color: "#50ffffff"
					font.pointSize: 22
				}

				Text {
					text: root.subtitle
					color: "#50ffffff"
					font.pointSize: 14
				}
			}
		}
	}
}
