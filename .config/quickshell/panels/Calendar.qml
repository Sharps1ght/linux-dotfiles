import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import qs.components

import "../config.js" as Config

Variants {
  model: Quickshell.screens

  OverlayPanel {
    required property var modelData
    screen: modelData
    anchors { top: true }
    margins { top: root.barVisible ? Config.ui.barHeight + Config.ui.mainMargin * 2 : Config.ui.mainMargin }
    visible: panelState

    panelBox: calendarBox

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

    function syncState() {
      syncPanelState(root.calendarOpen && root.focusedScreen === modelData)
    }

    Connections {
      target: root
      function onCalendarOpenChanged() { syncState() }
      function onFocusedScreenChanged() { syncState() }
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
        NumberAnimation { duration: Config.animation.normal; easing.type: Easing.InOutCubic }
      }

      ColumnLayout {
        id: calendarColumns
        anchors.fill: parent
        anchors.margins: Config.ui.mainMargin
        spacing: Config.ui.mainMargin / 2

        Text {
          id: calendarTitleText
          text: calendarTitle
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
            model: calendarCells.length
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: Config.ui.fontSize * 1.25
              color: {
                if (calendarCells[index].day === 0) return "transparent"
                if (dayCellMouse.containsMouse) return theme.hoverSubtle
                return calendarCells[index].isToday ? theme.todayBg : "transparent"
              }
              radius: Config.ui.fontSize

              MouseArea {
                id: dayCellMouse
                anchors.fill: parent
                hoverEnabled: calendarCells[index].day !== 0
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
                text: calendarCells[index].day === 0 ? "" : calendarCells[index].day
                color: calendarCells[index].isToday ? theme.todayFg : theme.fg
                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize - 6
                style: dayCellMouse.containsMouse && calendarCells[index].day !== 0 ? Text.Outline : Text.Normal
                styleColor: theme.textOutlineLight
              }
            }
          }
        }
      }
    }
  }
}