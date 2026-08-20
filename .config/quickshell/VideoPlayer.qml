import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtMultimedia

import "config.js" as Config

Variants {
  model: Quickshell.screens

  OverlayPanel {
    id: videoPanel
    required property var modelData
    screen: modelData
    anchors { top: true; right: true }
    margins {
      top: root.barVisible ? Config.ui.barHeight + Config.ui.mainMargin * 2 : Config.ui.mainMargin
      right: Config.ui.mainMargin
    }
    visible: videoPanelState
    keyboardFocus: videoPanel.videoPanelState && (videoPanel.panelHovered || urlInput.activeFocus)
      ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool videoPanelState: false
    property bool spawning: false
    property bool closing: false
    property bool panelHovered: false
    property bool controlsVisible: false
    property bool speedMenuOpen: false

    function showControls() {
      controlsVisible = true
      controlsHideTimer.stop()
    }

    function scheduleControlsHide() {
      if (player.hasVideo) controlsHideTimer.start()
    }

    function confirmUrl() {
      const url = root.videoUrl.trim()
      if (!url) return
      root.videoUrlInputVisible = false
      root.videoAttempts = 0
      root.playVideo(url)
    }

    function togglePlay() {
      if (player.playbackState === MediaPlayer.PlayingState) {
        player.pause()
        return
      }
      if (player.mediaStatus === MediaPlayer.EndOfMedia) {
        player.position = 0
      }
      player.play()
    }

    function seekBy(deltaMs) {
      if (!player.hasVideo || player.duration <= 0) return
      player.position = Math.max(0, Math.min(player.position + deltaMs, player.duration))
    }

    function hoverInside(item) {
      if (!panelHoverArea.containsMouse) return false
      const p = panelHoverArea.mapToItem(item, panelHoverArea.hoverX, panelHoverArea.hoverY)
      return p.x >= 0 && p.y >= 0 && p.x <= item.width && p.y <= item.height
    }

    function syncState() {
      const shouldShow = root.videoOpen && root.videoScreen === modelData
      if (shouldShow) {
        if (!videoPanelState) {
          closeTimer.stop()
          closing = false
          videoPanelState = true
          spawnFadeIn()
        }
      } else {
        fadeClose()
      }
    }

    function spawnFadeIn() {
      spawning = false
      videoBox.opacity = 0
      Qt.callLater(() => {
        spawning = true
        videoBox.opacity = 1
      })
    }

    function fadeClose() {
      if (!videoPanelState || closing) return
      spawning = false
      closing = true
      speedMenuOpen = false
      videoBox.opacity = 0
      closeTimer.start()
    }

    function formatRate(r) {
      const v = Math.round(r * 100) / 100
      const s = Number.isInteger(v) ? String(v) : v.toFixed(2).replace(/0+$/, "").replace(/\.$/, "")
      return s + "×"
    }

    onVideoPanelStateChanged: {
      if (videoPanelState) videoKeyHandler.forceActiveFocus()
    }

    Connections {
      target: root
      function onVideoOpenChanged() { syncState() }
      function onVideoScreenChanged() {
        syncState()
        if (modelData === root.videoScreen) player.videoOutput = videoOutputItem
      }
      function onVideoUrlInputVisibleChanged() {
        if (!root.videoUrlInputVisible) videoKeyHandler.forceActiveFocus()
      }
    }

    Connections {
      target: player
      function onHasVideoChanged() {
        if (player.hasVideo) {
          videoPanel.showControls()
          if (!videoPanel.panelHovered) videoPanel.scheduleControlsHide()
        }
      }
    }

    Component.onCompleted: {
      if (modelData === root.videoScreen) player.videoOutput = videoOutputItem
    }

    Timer {
      id: closeTimer
      interval: Config.sleep.animationDuration
      onTriggered: {
        closing = false
        videoPanelState = false
      }
    }

    Timer {
      id: controlsHideTimer
      interval: Config.sleep.notificationTimeout
      onTriggered: {
        videoPanel.controlsVisible = false
        videoPanel.speedMenuOpen = false
      }
    }

    property real videoAreaHeight: 480
    property real videoAreaWidth: videoAreaHeight * 16 / 9

    implicitWidth: videoAreaWidth + Config.ui.mainMargin * 4
    implicitHeight: videoColumn.implicitHeight + Config.ui.mainMargin * 4
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      id: videoBox
      anchors.fill: parent
      radius: Config.ui.fontSize
      clip: true
      color: theme.panelBg

      Behavior on opacity {
        enabled: spawning || closing
        NumberAnimation { duration: Config.sleep.animationDuration; easing.type: Easing.InOutCubic }
      }

      Item {
        id: videoKeyHandler
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
          if (urlInput.visible && urlInput.activeFocus) return
          switch (event.key) {
            case Qt.Key_Space:
              videoPanel.togglePlay()
              event.accepted = true
              break
            case Qt.Key_H:
              videoPanel.seekBy(-5000 * player.playbackRate)
              event.accepted = true
              break
            case Qt.Key_L:
              videoPanel.seekBy(5000 * player.playbackRate)
              event.accepted = true
              break
            case Qt.Key_J:
              audioOut.volume = Math.max(0, audioOut.volume - 0.05)
              event.accepted = true
              break
            case Qt.Key_K:
              audioOut.volume = Math.min(1, audioOut.volume + 0.05)
              audioOut.muted = false
              event.accepted = true
              break
          }
        }
      }

      Column {
        id: videoColumn
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors.margins: Config.ui.mainMargin * 2
        spacing: Config.ui.mainMargin / 2

        Item {
          width: parent.width
          visible: implicitHeight > 0
          clip: true
          opacity: root.videoTitleVisible ? 1 : 0
          implicitHeight: root.videoTitleVisible ? titleRowContent.implicitHeight : 0

          Behavior on implicitHeight {
            NumberAnimation { duration: Config.sleep.animationDuration; easing.type: Easing.InOutCubic }
          }
          Behavior on opacity {
            NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.InOutCubic }
          }

          RowLayout {
            id: titleRowContent
            width: parent.width

            Text {
              id: titleRowText
              Layout.fillWidth: true
              text: root.videoTitle
              elide: Text.ElideRight
              color: theme.heading
              font.bold: true
              font.family: Config.ui.fontFamily
              font.pixelSize: Config.ui.fontSize + 2
            }
          }
        }

        Rectangle {
          width: videoPanel.videoAreaWidth
          height: videoPanel.videoAreaHeight
          radius: Config.ui.fontSize
          color: "transparent"
          clip: true

          VideoOutput {
            id: videoOutputItem
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectFit
            visible: player.hasVideo
          }

          Shape {
            anchors.fill: parent
            visible: player.hasVideo
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
              fillColor: theme.panelBg
              strokeColor: "transparent"
              fillRule: ShapePath.OddEvenFill

              startX: 0
              startY: 0
              PathLine { x: videoPanel.videoAreaWidth; y: 0 }
              PathLine { x: videoPanel.videoAreaWidth; y: videoPanel.videoAreaHeight }
              PathLine { x: 0; y: videoPanel.videoAreaHeight }

              PathMove { x: Config.ui.fontSize; y: 0 }
              PathLine { x: videoPanel.videoAreaWidth - Config.ui.fontSize; y: 0 }
              PathArc { x: videoPanel.videoAreaWidth; y: Config.ui.fontSize; radiusX: Config.ui.fontSize; radiusY: Config.ui.fontSize }
              PathLine { x: videoPanel.videoAreaWidth; y: videoPanel.videoAreaHeight - Config.ui.fontSize }
              PathArc { x: videoPanel.videoAreaWidth - Config.ui.fontSize; y: videoPanel.videoAreaHeight; radiusX: Config.ui.fontSize; radiusY: Config.ui.fontSize }
              PathLine { x: Config.ui.fontSize; y: videoPanel.videoAreaHeight }
              PathArc { x: 0; y: videoPanel.videoAreaHeight - Config.ui.fontSize; radiusX: Config.ui.fontSize; radiusY: Config.ui.fontSize }
              PathLine { x: 0; y: Config.ui.fontSize }
              PathArc { x: Config.ui.fontSize; y: 0; radiusX: Config.ui.fontSize; radiusY: Config.ui.fontSize }
            }
          }

          Text {
            anchors.centerIn: parent
            text: root.videoError ? root.videoError : root.videoLoading ? "Loading…" : "Enter a link"
            visible: root.videoError !== ""
            color: root.videoError ? theme.error : theme.muted
            font.family: Config.ui.fontFamily
            font.pixelSize: Config.ui.fontSize - 6
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              videoPanel.speedMenuOpen = false
              videoPanel.togglePlay()
            }
          }

          Rectangle {
            id: controlsBar
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
            anchors.bottomMargin: Config.ui.mainMargin * 2
            width: parent.width - Config.ui.mainMargin * 4
            implicitHeight: controlsLayout.implicitHeight + Config.ui.mainMargin * 2
            visible: player.hasVideo
            opacity: videoPanel.controlsVisible ? 1 : 0
            enabled: videoPanel.controlsVisible
            radius: (controlsLayout.implicitHeight + Config.ui.mainMargin) / 2
            color: theme.panelBg

            Behavior on opacity {
              NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.InOutCubic }
            }

            RowLayout {
              id: controlsLayout
              anchors { fill: parent; margins: Config.ui.mainMargin }
              spacing: Config.ui.mainMargin

              Rectangle {
                id: playBox
                implicitWidth: Config.ui.fontSize
                implicitHeight: Config.ui.fontSize
                radius: height / 2
                color: videoPanel.hoverInside(playBox) ? theme.hoverSubtle : "transparent"

                Text {
                  id: playGlyph
                  anchors.centerIn: parent
                  text: player.playbackState === MediaPlayer.PlayingState ? "\uF04C" : "\uF04B"
                  color: theme.fg
                  font.family: Config.ui.fontFamily
                  font.pixelSize: Config.ui.fontSize - 6
                }

                MouseArea {
                  id: playMouse
                  anchors.fill: parent
                  onReleased: videoPanel.togglePlay()
                }
              }

              Slider {
                id: seekSlider
                Layout.fillWidth: true
                implicitHeight: Config.ui.mainMargin * 4
                from: 0
                to: Math.max(1, player.duration || 0)
                live: true
                enabled: player.seekable
                property bool seeking: false
                onPressedChanged: {
                  seekSlider.seeking = pressed
                  if (!pressed) {
                    player.setPosition(seekSlider.value)
                    videoKeyHandler.forceActiveFocus()
                  }
                }

                background: Rectangle {
                  x: seekSlider.leftPadding
                  y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                  width: seekSlider.availableWidth
                  height: 6
                  radius: height / 2
                  color: theme.hoverStrong

                  Rectangle {
                    width: seekSlider.visualPosition * parent.width
                    height: parent.height
                    radius: height / 2
                    color: theme.accent
                  }
                }

                handle: Rectangle {
                  x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                  y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                  width: 14
                  height: 14
                  radius: width / 2
                  color: theme.fg
                }
              }

              Rectangle {
                id: muteBox
                implicitWidth: Config.ui.fontSize
                implicitHeight: Config.ui.fontSize
                radius: height / 2
                color: videoPanel.hoverInside(muteBox) ? theme.hoverSubtle : "transparent"

                Text {
                  id: muteGlyph
                  anchors.centerIn: parent
                  text: audioOut.muted ? "\uF026" : "\uF028"
                  color: theme.fg
                  font.family: Config.ui.fontFamily
                  font.pixelSize: Config.ui.fontSize - 6
                }

                MouseArea {
                  id: muteMouse
                  anchors.fill: parent
                  onReleased: audioOut.muted = !audioOut.muted
                }
              }

              Slider {
                id: volumeSlider
                implicitWidth: Config.ui.mainMargin * 30
                implicitHeight: Config.ui.mainMargin * 4
                from: 0
                to: 1
                stepSize: 0.01
                onPressedChanged: if (!pressed) { audioOut.volume = value; videoKeyHandler.forceActiveFocus() }

                Binding {
                  target: volumeSlider
                  property: "value"
                  value: audioOut.volume
                  when: !volumeSlider.pressed
                }

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

              Rectangle {
                id: speedBox
                implicitWidth: speedText.implicitWidth + Config.ui.mainMargin
                implicitHeight: Config.ui.fontSize
                radius: height / 2
                color: videoPanel.hoverInside(speedBox) || videoPanel.speedMenuOpen ? theme.hoverSubtle : "transparent"

                Text {
                  id: speedText
                  anchors.centerIn: parent
                  text: videoPanel.formatRate(player.playbackRate)
                  color: theme.fg
                  font.family: Config.ui.fontFamily
                  font.pixelSize: Config.ui.fontSize - 6
                }

                MouseArea {
                  id: speedMouse
                  anchors.fill: parent
                  onClicked: videoPanel.speedMenuOpen = !videoPanel.speedMenuOpen
                }
              }
            }

            Connections {
              target: player
              function onPositionChanged() {
                if (!seekSlider.seeking) seekSlider.value = player.position
              }
            }
          }

          Rectangle {
            id: speedMenu
            anchors { right: parent.right; bottom: controlsBar.top }
            anchors.margins: Config.ui.mainMargin * 2
            width: Config.ui.fontSize * 11
            height: speedMenuColumn.implicitHeight + Config.ui.mainMargin * 4
            color: theme.panelBg
            radius: Config.ui.fontSize / 2
            visible: opacity > 0
            opacity: videoPanel.speedMenuOpen ? 1 : 0

            Behavior on opacity {
              NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.InOutCubic }
            }

            Column {
              id: speedMenuColumn
              anchors { fill: parent; margins: Config.ui.mainMargin * 2 }
              spacing: Config.ui.mainMargin

              RowLayout {
                width: parent.width
                spacing: Config.ui.mainMargin

                Text {
                  text: "Speed"
                  color: theme.heading
                  font.bold: true
                  font.family: Config.ui.fontFamily
                  font.pixelSize: Config.ui.fontSize - 6
                }

                Text {
                  Layout.fillWidth: true
                  text: videoPanel.formatRate(player.playbackRate)
                  color: theme.fg
                  font.family: Config.ui.fontFamily
                  font.pixelSize: Config.ui.fontSize - 6
                  horizontalAlignment: Text.AlignRight
                }
              }

              Slider {
                id: speedSlider
                width: parent.width
                implicitHeight: Config.ui.fontSize
                from: 0.25
                to: 2
                stepSize: 0.05
                onMoved: player.playbackRate = value
                onPressedChanged: if (!pressed) { player.playbackRate = value; videoKeyHandler.forceActiveFocus() }

                Binding {
                  target: speedSlider
                  property: "value"
                  value: player.playbackRate
                  when: !speedSlider.pressed
                }

                background: Rectangle {
                  x: speedSlider.leftPadding
                  y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                  width: speedSlider.availableWidth
                  height: 6
                  radius: height / 2
                  color: theme.hoverStrong

                  Rectangle {
                    width: speedSlider.visualPosition * parent.width
                    height: parent.height
                    radius: height / 2
                    color: theme.accent
                  }
                }

                handle: Rectangle {
                  x: speedSlider.leftPadding + speedSlider.visualPosition * (speedSlider.availableWidth - width)
                  y: speedSlider.topPadding + speedSlider.availableHeight / 2 - height / 2
                  width: 14
                  height: 14
                  radius: width / 2
                  color: theme.fg
                }
              }

              GridLayout {
                columns: 4
                width: parent.width
                columnSpacing: Config.ui.mainMargin / 2
                rowSpacing: Config.ui.mainMargin / 2

                Repeater {
                  model: [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]

                  Rectangle {
                    id: presetBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: Config.ui.fontSize + Config.ui.mainMargin
                    radius: Config.ui.fontSize / 2
                    color: videoPanel.hoverInside(presetBox)
                      ? theme.hoverSubtle
                      : (Math.abs(player.playbackRate - modelData) < 0.001 ? theme.accent : "transparent")

                    Text {
                      anchors.centerIn: parent
                      text: videoPanel.formatRate(modelData)
                      color: Math.abs(player.playbackRate - modelData) < 0.001 ? theme.bg : theme.fg
                      font.family: Config.ui.fontFamily
                      font.pixelSize: Config.ui.fontSize - 6
                    }

                    MouseArea {
                      id: presetMouse
                      anchors.fill: parent
                      onClicked: player.playbackRate = modelData
                    }
                  }
                }
              }
            }

            Binding {
              target: player
              property: "pitchCompensation"
              value: true
            }
          }
        }

        Item {
          width: parent.width
          visible: implicitHeight > 0
          clip: true
          opacity: root.videoTitleVisible ? 1 : 0
          implicitHeight: root.videoTitleVisible
            ? Math.max(linkButtonBox.implicitHeight, urlInputBox.implicitHeight)
            : 0

          Behavior on implicitHeight {
            NumberAnimation { duration: Config.sleep.animationDuration; easing.type: Easing.InOutCubic }
          }
          Behavior on opacity {
            NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.InOutCubic }
          }

          RowLayout {
            id: linkRowContent
            width: parent.width
            spacing: Config.ui.mainMargin

            Rectangle {
              id: linkButtonBox
              radius: Config.ui.fontSize / 2
              color: videoPanel.hoverInside(linkButtonBox) ? theme.hoverSubtle : "transparent"
              implicitWidth: linkText.implicitWidth + Config.ui.mainMargin
              implicitHeight: linkText.implicitHeight + Config.ui.mainMargin / 2

              Text {
                id: linkText
                anchors.centerIn: parent
                text: "Link"
                color: theme.fg
                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize - 4

                MouseArea {
                  id: linkMouse
                  anchors.fill: parent
                  onReleased: {
                    root.videoUrlInputVisible = true
                    urlInput.forceActiveFocus()
                  }
                }
              }
            }

            Rectangle {
              id: urlInputBox
              Layout.fillWidth: true
              visible: root.videoUrlInputVisible
              implicitHeight: Config.ui.fontSize + Config.ui.mainMargin
              radius: Config.ui.fontSize / 2
              color: theme.surface
              clip: true

              TextInput {
                id: urlInput
                anchors { fill: parent; margins: Config.ui.mainMargin }
                verticalAlignment: Text.AlignVCenter
                color: theme.fg
                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize - 6
                text: root.videoUrl
                onTextChanged: root.videoUrl = text
                onAccepted: confirmUrl()
              }
            }
          }
        }
      }

      MouseArea {
        id: panelHoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        property real hoverX: 0
        property real hoverY: 0
        onEntered: {
          hoverX = mouseX
          hoverY = mouseY
          videoPanel.panelHovered = true
          videoPanel.showControls()
        }
        onPositionChanged: {
          hoverX = mouseX
          hoverY = mouseY
        }
        onExited: {
          videoPanel.panelHovered = false
          videoPanel.scheduleControlsHide()
        }
      }
    }
  }
}
