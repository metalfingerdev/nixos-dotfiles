import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
	id: root
	signal unlocked()
	signal failed()

	// These properties are in the context and not individual lock surfaces
	// so all surfaces can share the same state.
	property string currentText: ""
	property bool unlockInProgress: false
	property bool showFailure: false

	onCurrentTextChanged: showFailure = false;

	function reset() {
		currentText = "";
		showFailure = false;
	}

	function tryUnlock() {
		if (currentText === "") return;

		root.unlockInProgress = true;
		pam.start();
	}

	PamContext {
		id: pam

		// A config of its own: the system one might not be what this interface expects, and break in some way.
		// It only supports passwords.
		configDirectory: "pam"
		config: "password.conf"

		onPamMessage: {
			if (this.responseRequired) {
				this.respond(root.currentText);
			}
		}

		// pam_unix won't send any important messages so all we need is the completion status.
		onCompleted: result => {
			if (result == PamResult.Success) {
				// Don't keep the password: the next lock would start with it already typed.
				root.currentText = "";
				root.unlocked();
			} else {
				root.currentText = "";
				root.showFailure = true;
			}

			root.unlockInProgress = false;
		}
	}
}