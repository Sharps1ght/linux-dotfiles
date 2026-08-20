import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtMultimedia

import "config.js" as Config

Scope {
  id: root
  NotificationServer {
    id: server
    actionsSupported: true
    bodySupported: true
    imageSupported: true
    onNotification: n => {
      history.insert(0, {
        summary: n.summary,
        body: n.body,
        appName: n.appName,
        urgency: n.urgency,
        image: n.image,
        time: Qt.formatDateTime(new Date(), "HH:mm:ss"),
        id: n.id
      })
      n.tracked = true
    }
  }

  signal dismissNotification(int id)

  AudioOutput {
    id: audioOut
  }

  MediaPlayer {
    id: player
    audioOutput: audioOut
  }

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
        root.playResolved(root.videoResolved)
      } else {
        root.onPlayFailed("Couldn't resolve link")
      }
    }
  }

  property string localCheckPath: ""
  property string localCheckName: ""
  property string localFileType: ""

  Process {
    id: fileCheckProc
    stdout: SplitParser {
      onRead: line => root.localFileType = line.trim()
    }
    onExited: exitCode => {
      if (!root.localCheckPath) return
      const path = root.localCheckPath
      const name = root.localCheckName
      root.localCheckPath = ""
      if (!root.videoOpen) return
      playWatchdog.stop()
      root.videoLoading = false
      if (exitCode === 0 && root.localFileType.indexOf("regular") === 0) {
        root.videoError = ""
        root.videoTitle = name || "Video"
        player.source = root.encodeFilePath(path)
        player.play()
      } else if (exitCode === 0 && root.localFileType === "directory") {
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
    root.localCheckName = basename.replace(/\.[^./]+$/, "") || basename
    root.localFileType = ""
    root.localCheckPath = path
    fileCheckProc.exec(["stat", "-L", "--format=%F", "--", path])
  }

  function playVideo(url) {
    const local = root.parseLocalPath(url)
    if (local !== null) {
      root.videoAttempts++
      root.playLocalFile(local)
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
      root.playVideo(root.pendingVideoUrl)
    } else {
      root.videoError = message
    }
  }

  Timer {
    id: playWatchdog
    interval: 8000
    onTriggered: root.onPlayFailed("Playback couldn't start")
  }


  Timer {
    id: pauseTitleTimer
    interval: Config.sleep.animationDurationLong
    onTriggered: {
      root.pausedTitleVisible = true
      root.updateVideoTitleVisible()
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
      root.updateVideoTitleVisible()
    }
    function onHasVideoChanged() { root.updateVideoTitleVisible() }
    function onMediaStatusChanged() {
      if (player.mediaStatus === MediaPlayer.InvalidMedia && player.playbackState !== MediaPlayer.PlayingState) {
        root.onPlayFailed("Playback failed")
      }
      root.updateVideoTitleVisible()
    }
    function onErrorOccurred(error, errorString) {
      if (error !== MediaPlayer.NoError) {
        console.log("Media error:", error, errorString)
        if (player.playbackState !== MediaPlayer.PlayingState) {
          root.onPlayFailed(errorString || "Playback failed")
        }
      }
    }
  }

  function updateVideoTitleVisible() {
    root.videoTitleVisible = !player.hasVideo ||
      player.mediaStatus === MediaPlayer.EndOfMedia ||
      root.pausedTitleVisible
  }

  Component.onCompleted: root.updateVideoTitleVisible()

  IpcHandler {
    target: "notifications"
    function toggle() : void { root.centerOpen = !root.centerOpen }
  }

  IpcHandler {
    target: "video"
    function toggle() : void {
      root.videoScreen = root.focusedScreen
      root.videoOpen = !root.videoOpen
    }
  }

  Timer {
    id: barHideTimer
    interval: Config.sleep.animationDuration
    onTriggered: bar.panelShown = false
  }

  IpcHandler {
    id: bar
    target: "bar"
    property bool panelShown: true

    function toggle() : void {
      if (root.barVisible) {
        barHideTimer.start()
      } else {
        barHideTimer.stop()
        bar.panelShown = true
      }
      root.barVisible = !root.barVisible
      root.centerOpen = false
      root.volumeOpen = false
    }
  }

  IpcHandler {
    target: "reload"
    function reload() : void {
      Quickshell.reload(true)
    }
  }

  property bool wallpaperManagerOpen: false
  property bool centerOpen: false
  property bool volumeOpen: false
  property bool videoOpen: false
  property string videoUrl: ""
  property string videoTitle: "Video"
  property bool videoUrlInputVisible: false
  property bool pausedTitleVisible: false
  property bool videoTitleVisible: false
  property bool videoLoading: false
  property string videoError: ""
  property string videoResolved: ""
  property string pendingVideoUrl: ""
  property int videoAttempts: 0
  property bool barVisible: false
  property var focusedScreen: Quickshell.screens[0]
  property var videoScreen: Quickshell.screens[0]
  property bool calendarOpen: false
  property bool settingsMenuEnabled: false
  property bool displayCenterDotEnabled: false
  property string wallpaperDir: ""
  property string wallpaperLastImage: ""
  property var wallpaperDirs: []
  property var awwwWallpapers: ({})
  property string barTime: Qt.formatDateTime(new Date(), "HH:mm:ss")
  property bool calendarCloseLock: false

  onVideoOpenChanged: {
    if (root.videoOpen) {
      root.videoUrlInputVisible = !player.hasVideo
    } else {
      playWatchdog.stop()
      root.videoLoading = false
      root.videoUrlInputVisible = false
      player.pause()
    }
  }

  Timer {
    id: calendarCloseTimer
    interval: 1000
    onTriggered: {
      root.calendarOpen = false
      root.calendarCloseLock = false
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.barTime = Qt.formatDateTime(new Date(), "HH:mm:ss")
  }

  property string calendarTitle: Qt.formatDateTime(new Date(), "dddd d MMMM yyyy")
  property var calendarCells: computeCalendar()

  function computeCalendar() {
    const now = new Date()
    const year = now.getFullYear()
    const month = now.getMonth()
    const firstDay = new Date(year, month, 1).getDay()
    const daysInMonth = new Date(year, month + 1, 0).getDate()
    const offset = firstDay === 0 ? 6 : firstDay - 1
    const totalCells = Math.ceil((offset + daysInMonth) / 7) * 7
    const cells = []
    for (let i = 0; i < totalCells; i++) {
      if (i < offset || i >= offset + daysInMonth) {
        cells.push({ day: 0, isToday: false })
      } else {
        const d = i - offset + 1
        cells.push({ day: d, isToday: d === now.getDate() })
      }
    }
    return cells
  }

  Process {
    id: niriProc
    command: ["niri", "msg", "--json", "event-stream"]
    running: true

    property var workspaceMap: ({})

    stdout: SplitParser {
      onRead: msg => {
        const event = JSON.parse(msg)
        if (event.WorkspacesChanged) {
          for (const ws of event.WorkspacesChanged.workspaces)
          niriProc.workspaceMap[ws.id] = ws.output
        } else if (event.WorkspaceActivated && event.WorkspaceActivated.focused) {
          const output = niriProc.workspaceMap[event.WorkspaceActivated.id]
          const screen = Quickshell.screens.find(s => s.name === output)
          if (screen) root.focusedScreen = screen
        }
      }
    }
  }

  function removeFromHistory(id) {
    for (let i = 0; i < history.count; i++) {
      if (history.get(i).id === id) {
        history.remove(i)
        break
      }
    }
  }

  function dismissCenterEntry(id) {
    dismissNotification(id)
  }

  ListModel { id: history }

  Theme { id: theme }
  Bar {}
  Calendar {}
  Volume {}
  Settings {}
  WallpaperManager {}
  VideoPlayer {}
  NotificationPopup {}
  NotificationCenter {}
}
