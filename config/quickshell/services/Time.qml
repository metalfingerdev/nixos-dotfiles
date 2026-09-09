// Time.qml

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root
  property string time

  Process {
    id: dateProc
    // sh -c lets us run a shell command that strips the newline using printf
    command: ["sh", "-c", "printf %s \"$(date)\""]
    running: true
  
    stdout: StdioCollector {
      onStreamFinished: root.time = this.text
    }
  }


  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: dateProc.running = true
  }

    IpcHandler {
      target: "clock"
      function getTime(): string { return Time.time }
  }
}