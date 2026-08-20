import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "config.js" as Config

Variants {
  model: Quickshell.screens

  OverlayPanel {
    id: settingsPanel
    required property var modelData
    screen: modelData
    anchors { top: true; left: true }
    margins {
      top: root.barVisible ? Config.ui.barHeight + Config.ui.mainMargin * 2 : Config.ui.mainMargin
      left: Config.ui.mainMargin
    }
    visible: settingsPanelState

    property bool settingsPanelState: false
    property bool spawning: false
    property bool closing: false

    function syncState() {
      const shouldShow = root.settingsMenuEnabled && root.focusedScreen === modelData
      if (shouldShow) {
        if (!settingsPanelState) {
          closeTimer.stop()
          closing = false
          settingsPanelState = true
          spawnFadeIn()
        }
      } else {
        fadeClose()
      }
    }

    function spawnFadeIn() {
      spawning = false
      settingsBox.opacity = 0
      Qt.callLater(() => {
        spawning = true
        settingsBox.opacity = 1
      })
    }

    function fadeClose() {
      if (!settingsPanelState || closing) return
      spawning = false
      closing = true
      settingsBox.opacity = 0
      closeTimer.start()
    }

    Connections {
      target: root
      function onSettingsMenuEnabledChanged() { syncState() }
      function onFocusedScreenChanged() { syncState() }
    }

    Timer {
      id: closeTimer
      interval: Config.sleep.animationDuration
      onTriggered: {
        closing = false
        settingsPanelState = false
      }
    }

    implicitHeight: settingsColumn.implicitHeight + Config.ui.mainMargin * 4
    implicitWidth: settingsColumn.implicitWidth + Config.ui.mainMargin * 4
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      id: settingsBox
      anchors.fill: parent
      radius: Config.ui.fontSize
      clip: true
      color: theme.panelBg

      Behavior on opacity {
        enabled: spawning || closing
        NumberAnimation { duration: Config.sleep.animationDuration; easing.type: Easing.Linear }
      }

      ColumnLayout {
        id: settingsColumn
        anchors { top: parent.top; left: parent.left; }
        anchors.margins: Config.ui.mainMargin * 2
        spacing: Config.ui.mainMargin / 2

        Text {
          text: "Settings"
          color: theme.heading
          font.bold: true
          font.family: Config.ui.fontFamily
          font.pixelSize: Config.ui.fontSize + 2
        }

        RowLayout {
          spacing: Config.ui.mainMargin * 4
          //anchors { right: parent.right; left: parent.left }
          Layout.fillWidth: true

          Text {
            text: "Display Center Dot"
            color: theme.fg
            font.family: Config.ui.fontFamily
            font.pixelSize: Config.ui.fontSize - 4
            Layout.fillWidth: true
          }

          Switch {
            id: displayCenterSwitch
            checked: root.displayCenterDotEnabled
            onToggled: root.displayCenterDotEnabled = checked
            leftPadding: 0
            implicitWidth: Config.ui.fontSize * 2
            Layout.alignment: Qt.AlignVCenter

            indicator: Rectangle {
              x: 0
              y: displayCenterSwitch.topPadding + displayCenterSwitch.availableHeight / 2 - height / 2
              width: displayCenterSwitch.implicitWidth
              height: Config.ui.fontSize
              radius: height / 2
              color: displayCenterSwitch.checked ? theme.accent : theme.hoverStrong

              Rectangle {
                x: displayCenterSwitch.checked ? parent.width - width - Config.ui.mainMargin : Config.ui.mainMargin
                width: Config.ui.fontSize / 1.5
                height: Config.ui.fontSize / 1.5
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: theme.fg

                Behavior on x {
                  NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.Linear }
                }
              }
            }

            contentItem: Text {
              text: displayCenterSwitch.text
              font: displayCenterSwitch.font
              opacity: 0
            }
          }
        }
      }
    }
  }
}
