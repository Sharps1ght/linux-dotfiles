import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "config.js" as Config

Variants {
  model: Quickshell.screens

  OverlayPanel {
  required property var modelData
  screen: modelData
  anchors { top: true }
  margins { top: root.barVisible ? Config.ui.barHeight + Config.ui.mainMargin * 2 : Config.ui.mainMargin }
  visible: calendarPanelState

  property bool calendarPanelState: false
  property bool spawning: false
  property bool closing: false

  function syncState() {
    const shouldShow = root.calendarOpen && root.focusedScreen === modelData
    if (shouldShow) {
      if (!calendarPanelState) {
        closeTimer.stop()
        closing = false
        calendarPanelState = true
        spawnFadeIn()
      }
    } else {
      fadeClose()
    }
  }

  function spawnFadeIn() {
    spawning = false
    calendarBox.opacity = 0
    Qt.callLater(() => {
      spawning = true
      calendarBox.opacity = 1
    })
  }

  function fadeClose() {
    if (!calendarPanelState || closing) return
    spawning = false
    closing = true
    calendarBox.opacity = 0
    closeTimer.start()
  }

  Connections {
    target: root
    function onCalendarOpenChanged() { syncState() }
    function onFocusedScreenChanged() { syncState() }
  }

  Timer {
    id: closeTimer
    interval: Config.sleep.animationDuration
    onTriggered: {
      closing = false
      calendarPanelState = false
    }
  }

  implicitWidth: calendarTitle.implicitWidth + Config.ui.barHeight / 2 + Config.ui.mainMargin * 2
  implicitHeight: calendarColumns.implicitHeight + Config.ui.barHeight / 2 + Config.ui.mainMargin * 2
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onReleased: root.calendarOpen = false
    onEntered: {
      calendarCloseTimer.stop()
      root.calendarCloseLock = false
    }
    onExited: { if (!root.calendarCloseLock) calendarCloseTimer.start() }
  }

  Rectangle {
    id: calendarBox
    anchors.centerIn: parent
    width: calendarTitle.implicitWidth + Config.ui.barHeight / 2 + Config.ui.mainMargin * 2
    height: calendarColumns.implicitHeight + Config.ui.barHeight / 2 + Config.ui.mainMargin * 2
    color: theme.panelBg
    radius: Config.ui.barHeight / 2

    Behavior on opacity {
      enabled: spawning || closing
      NumberAnimation { duration: Config.sleep.animationDuration; easing.type: Easing.InOutCubic }
    }

    ColumnLayout {
      id: calendarColumns
      anchors.fill: parent
      anchors.margins: Config.ui.mainMargin
      spacing: Config.ui.mainMargin / 2

      Text {
        id: calendarTitle
        text: root.calendarTitle
        color: theme.heading
        font.family: Config.ui.fontFamily
        font.pixelSize: Config.ui.fontSize + 2
        font.bold: true
        Layout.alignment: Qt.AlignHCenter
      }

      GridLayout {
        columns: 7
        Layout.fillWidth: true
        columnSpacing: Config.ui.mainMargin / 4
        rowSpacing: Config.ui.mainMargin / 4

        Repeater {
          model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
          Text {
            text: modelData
            color: theme.muted
            font.family: Config.ui.fontFamily
            font.pixelSize: Config.ui.fontSize - 6
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
          }
        }

        Repeater {
          model: root.calendarCells.length
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Config.ui.fontSize * 1.25
            color: {
              if (root.calendarCells[index].day === 0) return "transparent"
              if (dayCellMouse.containsMouse) return theme.hoverSubtle
              return root.calendarCells[index].isToday ? theme.todayBg : "transparent"
            }
            radius: Config.ui.fontSize

            MouseArea {
              id: dayCellMouse
              anchors.fill: parent
              hoverEnabled: root.calendarCells[index].day !== 0
              onEntered: {
                calendarCloseTimer.stop()
                root.calendarCloseLock = true
              }
              onExited: {
                root.calendarCloseLock = false
                calendarCloseTimer.start()
              }
            }

            Text {
              anchors.centerIn: parent
              text: root.calendarCells[index].day === 0 ? "" : root.calendarCells[index].day
              color: root.calendarCells[index].isToday ? theme.todayFg : theme.fg
              font.family: Config.ui.fontFamily
              font.pixelSize: Config.ui.fontSize - 6
              style: dayCellMouse.containsMouse && root.calendarCells[index].day !== 0 ? Text.Outline : Text.Normal
              styleColor: theme.textOutlineLight
            }
          }
        }
      }
    }
  }
  }
}
