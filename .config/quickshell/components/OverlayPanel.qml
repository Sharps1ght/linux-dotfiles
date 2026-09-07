import Quickshell
import Quickshell.Wayland
import QtQuick

import "../config.js" as Config

PanelWindow {
  id: panelRoot
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: keyboardFocus

  property var keyboardFocus: WlrKeyboardFocus.None

  property bool panelState: false
  property bool spawning: false
  property bool closing: false
  property Item panelBox: null

  Timer {
    id: closeTimer
    interval: Config.animation.normal
    onTriggered: {
      panelRoot.closing = false
      panelRoot.panelState = false
    }
  }

  function syncPanelState(shouldShow: bool) {
    if (shouldShow) {
      if (!panelState) {
        closeTimer.stop()
        closing = false
        panelState = true
        spawnFadeIn()
      }
    } else {
      fadeClose()
    }
  }

  function spawnFadeIn() {
    spawning = false
    if (panelBox) panelBox.opacity = 0
    Qt.callLater(() => {
      spawning = true
      if (panelBox) panelBox.opacity = 1
    })
  }

  function fadeClose() {
    if (!panelState || closing) return
    spawning = false
    closing = true
    if (panelBox) panelBox.opacity = 0
    closeTimer.start()
  }
}