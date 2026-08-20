import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "config.js" as Config

Variants {
  model: Quickshell.screens

  OverlayPanel {
    id: volumePanel
    required property var modelData
    screen: modelData
    anchors { top: true; left: true }
    margins {
      top: root.barVisible ? Config.ui.barHeight + Config.ui.mainMargin * 2 : Config.ui.mainMargin
      left: Config.ui.mainMargin
    }
    visible: volumePanelState

    property bool volumePanelState: false
    property bool spawning: false
    property bool closing: false

    function syncState() {
      const shouldShow = root.volumeOpen && root.focusedScreen === modelData
      if (shouldShow) {
        if (!volumePanelState) {
          closeTimer.stop()
          closing = false
          volumePanelState = true
          spawnFadeIn()
        }
      } else {
        fadeClose()
      }
    }

    function spawnFadeIn() {
      spawning = false
      volumeBox.opacity = 0
      Qt.callLater(() => {
        spawning = true
        volumeBox.opacity = 1
      })
    }

    function fadeClose() {
      if (!volumePanelState || closing) return
      spawning = false
      closing = true
      volumeBox.opacity = 0
      closeTimer.start()
    }

    Connections {
      target: root
      function onVolumeOpenChanged() { syncState() }
      function onFocusedScreenChanged() { syncState() }
    }

    Timer {
      id: closeTimer
      interval: Config.sleep.animationDuration
      onTriggered: {
        closing = false
        volumePanelState = false
      }
    }

    implicitWidth: Config.ui.notificationIconSize + Config.ui.barHeight * 8 + Config.ui.mainMargin * 4
    implicitHeight: volumeColumn.implicitHeight + Config.ui.mainMargin * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    PwObjectTracker {
      objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    component VolumeRow : Item {
      id: row
      required property var node
      required property string title

      width: volumeColumn.width
      implicitHeight: rowColumn.implicitHeight + Config.ui.mainMargin

      visible: node && node.audio

      Column {
        id: rowColumn
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: Config.ui.mainMargin / 2

        Text {
          text: row.title + (row.node ? " — " + (row.node.description || row.node.nickname || row.node.name) : "")
          color: theme.heading
          font.bold: true
          font.family: Config.ui.fontFamily
          font.pixelSize: Config.ui.fontSize - 6
        }

        Text {
          id: volumeText
          text: "…"
          color: theme.fg
          font.family: Config.ui.fontFamily
          font.pixelSize: Config.ui.fontSize - 8
        }

        Slider {
          id: volumeSlider
          width: parent.width
          implicitHeight: Config.ui.fontSize
          from: 0
          to: 1
          stepSize: 0.01
          onMoved: row.preview()
          onPressedChanged: if (!pressed) row.commit()

          background: Rectangle {
            x: volumeSlider.leftPadding
            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
            width: volumeSlider.availableWidth
            height: 6
            radius: height / 2
            color: theme.hoverStrong

            Rectangle {
              width: volumeSlider.visualPosition * parent.width
              height: parent.height
              radius: height / 2
              color: theme.accent
            }
          }

          handle: Rectangle {
            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
            width: 14
            height: 14
            radius: width / 2
            color: theme.fg
          }
        }
      }

      function preview() {
        volumeText.text = Math.round(volumeSlider.value * 100) + "%"
      }

      function commit() {
        if (!row.node || !row.node.audio) return
        row.node.audio.volume = volumeSlider.value
      }

      function syncFromNode() {
        if (!row.node || !row.node.audio) return
        if (!volumeSlider.pressed) volumeSlider.value = row.node.audio.volume
        volumeText.text = Math.round(row.node.audio.volume * 100) + "%"
      }

      Component.onCompleted: Qt.callLater(() => row.syncFromNode())

      Connections {
        target: row.node ? row.node.audio : null
        function onVolumesChanged() {
          row.syncFromNode()
        }
      }
    }

    Rectangle {
      id: volumeBox
      anchors.fill: parent
      radius: Config.ui.fontSize
      clip: true
      color: theme.panelBg

      Behavior on opacity {
        enabled: spawning || closing
        NumberAnimation { duration: Config.sleep.animationDuration; easing.type: Easing.InOutCubic }
      }

      Column {
        id: volumeColumn
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors.margins: Config.ui.mainMargin * 2
        spacing: Config.ui.mainMargin / 2

        Text {
          text: "Volume"
          color: theme.heading
          font.bold: true
          font.family: Config.ui.fontFamily
          font.pixelSize: Config.ui.fontSize + 2
        }

        VolumeRow {
          node: Pipewire.defaultAudioSink
          title: "Output"
        }

        VolumeRow {
          node: Pipewire.defaultAudioSource
          title: "Input"
        }
      }
    }
  }
}
