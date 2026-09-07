import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import qs.components

import "../config.js" as Config

Scope {
  Variants {
    model: Quickshell.screens

    OverlayPanel {
      id: barPanel
      required property var modelData
      screen: modelData
      visible: bar.panelShown

      anchors { left: true; top: true; right: true }
      margins { left: Config.ui.mainMargin; top: Config.ui.mainMargin; right: Config.ui.mainMargin }
      implicitHeight: Config.ui.barHeight
      color: "transparent"

      exclusionMode: ExclusionMode.Ignore

      PanelWindow {
        id: displayCenter
        screen: barPanel.modelData
        visible: barPanel.modelData.name === Config.ui.centerDotScreen && root.displayCenterDotEnabled
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        margins {
          top: barPanel.modelData.height / 2 - Config.ui.centerDotSize / 2
          left: barPanel.modelData.width / 2 - Config.ui.centerDotSize / 2
        }
        implicitWidth: Config.ui.centerDotSize
        implicitHeight: Config.ui.centerDotSize
        Rectangle {
          anchors.fill: parent
          color: Config.ui.centerDotColor
          radius: Config.ui.centerDotSize / 2
        }
      }

      Rectangle {
        anchors.fill: parent
        radius: Config.ui.barHeight / 2
        color: theme.panelBg

        opacity: root.barVisible ? 1 : 0
        Behavior on opacity {
          NumberAnimation { duration: Config.animation.short; easing.type: Easing.Linear }
        }

        RowLayout {
          anchors.fill: parent

          Item {
            id: leftZone
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
              anchors { left: parent.left; verticalCenter: parent.verticalCenter }
              anchors.leftMargin: Config.ui.mainMargin
              spacing: Config.ui.mainMargin / 2

              BarIconButton {
                icon: Config.icons.volume
                onClicked: {
                  root.volumeOpen = !root.volumeOpen
                  root.centerOpen = false
                }
              }

              BarIconButton {
                icon: Config.icons.settings
                onClicked: root.settingsMenuEnabled = !root.settingsMenuEnabled
              }

              BarIconButton {
                icon: Config.icons.wallpaper
                onClicked: root.wallpaperManagerOpen = !root.wallpaperManagerOpen
              }
            }
          }

          Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: clockText.implicitWidth + Config.ui.mainMargin * 4
            implicitHeight: clockText.implicitHeight + Config.ui.mainMargin

            Rectangle {
              anchors.fill: parent
              radius: height / 2
              color: clockMouseArea.containsMouse ? theme.hoverSubtle : "transparent"

              Text {
                anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                id: clockText
                text: root.barTime
                color: theme.fg
                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize
                transformOrigin: Item.Center
                scale: clockMouseArea.containsMouse ? 1.08 : 1
                Behavior on scale {
                  NumberAnimation { duration: Config.animation.short; easing.type: Easing.Linear }
                }
                style: clockMouseArea.containsMouse ? Text.Outline : Text.Normal
                styleColor: theme.textOutline

                MouseArea {
                  id: clockMouseArea
                  anchors.fill: parent
                  hoverEnabled: true

                  onReleased: {
                    root.calendarOpen = !root.calendarOpen
                    if (root.calendarOpen) {
                      calendarCloseTimer.stop()
                      root.calendarCloseLock = true
                    }
                  }

                  onEntered: {
                    calendarCloseTimer.stop()
                    root.calendarCloseLock = false
                  }

                  onExited: {
                    if (!root.calendarCloseLock) calendarCloseTimer.start()
                  }
                }
              }
            }
          }

          Item {
            id: rightZone
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
              anchors { right: parent.right; verticalCenter: parent.verticalCenter }
              anchors.rightMargin: Config.ui.mainMargin
              spacing: Config.ui.mainMargin / 2

              BarIconButton {
                icon: Config.icons.video
                onClicked: {
                  root.videoScreen = modelData
                  root.videoOpen = !root.videoOpen
                  root.centerOpen = false
                  root.volumeOpen = false
                }
              }

              BarIconButton {
                icon: Config.icons.bell
                onClicked: {
                  root.centerOpen = !root.centerOpen
                  root.volumeOpen = false
                }
              }
            }
          }
        }
      }
    }
  }
}