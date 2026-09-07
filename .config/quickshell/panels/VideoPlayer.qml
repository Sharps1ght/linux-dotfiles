import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtMultimedia

import qs.components

import "../config.js" as Config

Scope {
  id: videoScope

  AudioOutput {
    id: audioOut
  }

  MediaPlayer {
    id: player
    audioOutput: audioOut
  }

  property string localCheckPath: ""
  property string localCheckName: ""
  property string localFileType: ""

  Process {
    id: ytDlpProc
    stdout: SplitParser {
      onRead: line => {
        const text = line.trim()
        if (text.startsWith("TITLE=")) {
          const title = text.slice(6)
          if (title) root.videoTitle = title
        } else if (text.startsWith("URL=")) {
          const url = text.slice(4)
          if (url) root.videoResolved = url
        }
      }
    }
    stderr: SplitParser {
      onRead: line => console.log("yt-dlp stderr:", line)
    }
    onExited: (exitCode) => {
      if (exitCode === 0 && root.videoResolved) {
        playResolved(root.videoResolved)
      } else {
        onPlayFailed("Couldn't resolve link")
      }
    }
  }

  Process {
    id: fileCheckProc
    stdout: SplitParser {
      onRead: line => localFileType = line.trim()
    }
    onExited: exitCode => {
      if (!localCheckPath) return
      const path = localCheckPath
      const name = localCheckName
      localCheckPath = ""
      if (!root.videoOpen) return
      playWatchdog.stop()
      root.videoLoading = false
      if (exitCode === 0 && localFileType.indexOf("regular") === 0) {
        root.videoError = ""
        root.videoTitle = name || "Video"
        player.source = encodeFilePath(path)
        player.play()
      } else if (exitCode === 0 && localFileType === "directory") {
        root.videoError = "Is a directory: " + path
      } else {
        root.videoError = "No such file: " + path
      }
    }
  }

  function parseLocalPath(input) {
    let p = input.trim()
    if (p.length >= 2 && (p[0] === '"' || p[0] === "'") && p[p.length - 1] === p[0]) {
      p = p.slice(1, -1)
    }
    let path = null
    if (p.startsWith("~/")) {
      path = (Quickshell.env("HOME") || "") + p.slice(1)
    } else if (p === "~") {
      path = Quickshell.env("HOME") || ""
    } else if (p.startsWith("/")) {
      path = p
    } else if (p.startsWith("./") || p.startsWith("../")) {
      path = (Quickshell.workingDirectory || "") + "/" + p
    } else {
      return null
    }
    const out = []
    for (const part of path.split("/")) {
      if (part === "" || part === ".") continue
      if (part === "..") {
        out.pop()
        continue
      }
      out.push(part)
    }
    return "/" + out.join("/")
  }

  function encodeFilePath(path) {
    return "file://" + path.split("/").map(encodeURIComponent).join("/")
  }

  function playLocalFile(path) {
    root.pendingVideoUrl = ""
    root.videoLoading = true
    root.videoError = ""
    root.videoTitle = "Video"
    const basename = decodeURIComponent(path.split("/").filter(Boolean).pop() || "")
    localCheckName = basename.replace(/\.[^./]+$/, "") || basename
    localFileType = ""
    localCheckPath = path
    fileCheckProc.exec(["stat", "-L", "--format=%F", "--", path])
  }

  function playVideo(url) {
    const local = parseLocalPath(url)
    if (local !== null) {
      root.videoAttempts++
      playLocalFile(local)
      return
    }
    root.videoError = ""
    root.videoAttempts++
    playWatchdog.start()
    if (/\.(mp4|webm|ogg|mov|mkv|m4v|m3u8|mpd)(\?.*)?$/i.test(url)) {
      root.pendingVideoUrl = ""
      root.videoTitle = decodeURIComponent(url.split("?")[0].split("/").pop()) || "Video"
      player.source = url
      player.play()
      return
    }
    root.pendingVideoUrl = url
    root.videoTitle = "Video"
    root.videoLoading = true
    root.videoResolved = ""
    ytDlpProc.exec(["yt-dlp", "-f", "best[height<=480][acodec!=none]/best[height<=480]/best", "--print", "TITLE=%(title)s", "--print", "URL=%(url)s", "--no-playlist", "--no-warnings", url])
  }

  function playResolved(url) {
    player.source = url
    if (root.videoOpen) {
      player.play()
    }
  }

  function onPlayFailed(message) {
    playWatchdog.stop()
    root.videoLoading = false
    if (!root.videoOpen) return
    if (root.videoAttempts < 2 && root.pendingVideoUrl) {
      playVideo(root.pendingVideoUrl)
    } else {
      root.videoError = message
    }
  }

  Timer {
    id: playWatchdog
    interval: Config.video.loadTimeout
    onTriggered: onPlayFailed("Playback couldn't start")
  }

  Timer {
    id: pauseTitleTimer
    interval: Config.animation.long
    onTriggered: {
      root.pausedTitleVisible = true
      updateVideoTitleVisible()
    }
  }

  Connections {
    target: player
    function onPlaybackStateChanged() {
      if (player.playbackState === MediaPlayer.PlayingState) {
        playWatchdog.stop()
        pauseTitleTimer.stop()
        root.videoLoading = false
        root.videoError = ""
        root.pausedTitleVisible = false
      } else if (player.playbackState === MediaPlayer.PausedState) {
        pauseTitleTimer.start()
      }
      updateVideoTitleVisible()
    }
    function onHasVideoChanged() { updateVideoTitleVisible() }
    function onMediaStatusChanged() {
      if (player.mediaStatus === MediaPlayer.InvalidMedia && player.playbackState !== MediaPlayer.PlayingState) {
        onPlayFailed("Playback failed")
      }
      updateVideoTitleVisible()
    }
    function onErrorOccurred(error, errorString) {
      if (error !== MediaPlayer.NoError) {
        console.log("Media error:", error, errorString)
        if (player.playbackState !== MediaPlayer.PlayingState) {
          onPlayFailed(errorString || "Playback failed")
        }
      }
    }
  }

  function updateVideoTitleVisible() {
    root.videoTitleVisible = !player.hasVideo ||
      player.mediaStatus === MediaPlayer.EndOfMedia ||
      root.pausedTitleVisible
  }

  Component.onCompleted: updateVideoTitleVisible()

  Connections {
    target: root
    function onVideoOpenChanged() {
      if (root.videoOpen) {
        root.videoUrlInputVisible = !player.hasVideo
      } else {
        playWatchdog.stop()
        root.videoLoading = false
        root.videoUrlInputVisible = false
        player.pause()
      }
    }
  }

  IpcHandler {
    target: "video"
    function toggle() : void {
      root.videoScreen = root.focusedScreen
      root.videoOpen = !root.videoOpen
    }
  }

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
      visible: panelState
      keyboardFocus: videoPanel.panelState && (videoPanel.panelHovered || urlInput.activeFocus)
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      panelBox: videoBox

      property bool panelHovered: false
      property bool controlsVisible: false
      property bool speedMenuOpen: false

      onPanelStateChanged: {
        if (panelState) videoKeyHandler.forceActiveFocus()
      }

      onClosingChanged: {
        if (closing) speedMenuOpen = false
      }

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
        videoScope.playVideo(url)
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
        syncPanelState(root.videoOpen && root.videoScreen === modelData)
      }

      function formatRate(r) {
        const v = Math.round(r * 100) / 100
        const s = Number.isInteger(v) ? String(v) : v.toFixed(2).replace(/0+$/, "").replace(/\.$/, "")
        return s + "×"
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
        id: controlsHideTimer
        interval: Config.animation.notificationTimeout
        onTriggered: {
          videoPanel.controlsVisible = false
          videoPanel.speedMenuOpen = false
        }
      }

      property real videoAreaHeight: Config.ui.videoHeight
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
          NumberAnimation { duration: Config.animation.normal; easing.type: Easing.InOutCubic }
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
                videoPanel.seekBy(-Config.video.seekStep * player.playbackRate)
                event.accepted = true
                break
              case Qt.Key_L:
                videoPanel.seekBy(Config.video.seekStep * player.playbackRate)
                event.accepted = true
                break
              case Qt.Key_J:
                audioOut.volume = Math.max(0, audioOut.volume - Config.video.volumeStep)
                event.accepted = true
                break
              case Qt.Key_K:
                audioOut.volume = Math.min(1, audioOut.volume + Config.video.volumeStep)
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
              NumberAnimation { duration: Config.animation.normal; easing.type: Easing.InOutCubic }
            }
            Behavior on opacity {
              NumberAnimation { duration: Config.animation.short; easing.type: Easing.InOutCubic }
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
                NumberAnimation { duration: Config.animation.short; easing.type: Easing.InOutCubic }
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
                    anchors.centerIn: parent
                    text: player.playbackState === MediaPlayer.PlayingState ? Config.icons.pause : Config.icons.play
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

                StyledSlider {
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
                }

                Rectangle {
                  id: muteBox
                  implicitWidth: Config.ui.fontSize
                  implicitHeight: Config.ui.fontSize
                  radius: height / 2
                  color: videoPanel.hoverInside(muteBox) ? theme.hoverSubtle : "transparent"

                  Text {
                    anchors.centerIn: parent
                    text: audioOut.muted ? Config.icons.muted : Config.icons.sound
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

                StyledSlider {
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
                NumberAnimation { duration: Config.animation.short; easing.type: Easing.InOutCubic }
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

                StyledSlider {
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
                }

                GridLayout {
                  columns: 4
                  width: parent.width
                  columnSpacing: Config.ui.mainMargin / 2
                  rowSpacing: Config.ui.mainMargin / 2

                  Repeater {
                    model: Config.video.speeds

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
              NumberAnimation { duration: Config.animation.normal; easing.type: Easing.InOutCubic }
            }
            Behavior on opacity {
              NumberAnimation { duration: Config.animation.short; easing.type: Easing.InOutCubic }
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
}