import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import QtQuick

import qs.panels

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

  IpcHandler {
    target: "notifications"
    function toggle() : void { root.centerOpen = !root.centerOpen }
  }

  Timer {
    id: barHideTimer
    interval: Config.animation.normal
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
  property bool barVisible: true
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