import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.components

Scope {
	id: root

	property string title: "Activate Linux"
	property string subtitle: "Go to Settings to activate Linux"

	Variants {
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

			// An empty mask: clicks pass through.
			mask: Region {}

			// The overlay layer, or it wouldn't show over fullscreen windows.
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
