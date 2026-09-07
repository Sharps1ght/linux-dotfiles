import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.components

import "../config.js" as Config

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
    visible: panelState

    panelBox: volumeBox

    function syncState() {
      syncPanelState(root.volumeOpen && root.focusedScreen === modelData)
    }

    Connections {
      target: root
      function onVolumeOpenChanged() { syncState() }
      function onFocusedScreenChanged() { syncState() }
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

        StyledSlider {
          id: volumeSlider
          width: parent.width
          implicitHeight: Config.ui.fontSize
          from: 0
          to: 1
          stepSize: 0.01
          onMoved: row.preview()
          onPressedChanged: if (!pressed) row.commit()
        }
      }

      Component.onCompleted: Qt.callLater(() => row.syncFromNode())

      Connections {
        target: row.node ? row.node.audio : null
        function onVolumesChanged() {
          row.syncFromNode()
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
    }

    Rectangle {
      id: volumeBox
      anchors.fill: parent
      radius: Config.ui.fontSize
      clip: true
      color: theme.panelBg

      Behavior on opacity {
        enabled: spawning || closing
        NumberAnimation { duration: Config.animation.normal; easing.type: Easing.InOutCubic }
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