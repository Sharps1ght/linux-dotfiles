import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "config.js" as Config

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
        visible: barPanel.modelData.name === "DP-1" && root.displayCenterDotEnabled
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        margins {
          top: barPanel.modelData.height / 2 - 2
          left: barPanel.modelData.width / 2 - 2
        }
        implicitWidth: 4
        implicitHeight: 4
        Rectangle {
          id: displayCenterDot
          anchors.fill: parent
          color: "#88aaaaaa"
          radius: 2
        }
      }

      Rectangle {
        anchors.fill: parent
        radius: Config.ui.barHeight - Config.ui.mainMargin
        color: theme.panelBg

        opacity: root.barVisible ? 1 : 0
        Behavior on opacity {
          NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.Linear }
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

              Item {
                implicitWidth: Config.ui.barHeight - Config.ui.mainMargin
                implicitHeight: Config.ui.barHeight - Config.ui.mainMargin

                Rectangle {
                  anchors.fill: parent
                  radius: Config.ui.barHeight / 2
                  color: volumeMouseArea.containsMouse ? theme.hoverSubtle : "transparent"
                  Text {

                    id: volumeIcon
                    anchors.centerIn: parent
                    text: "󰕾"
                    color: theme.fg
                    font.family: Config.ui.fontFamily
                    font.pixelSize: Config.ui.fontSize
                    transformOrigin: Item.Center
                    scale: volumeMouseArea.containsMouse ? 1.08 : 1
                    Behavior on scale {
                      NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.Linear }
                    }
                    MouseArea {
                      id: volumeMouseArea
                      anchors.fill: parent
                      hoverEnabled: true
                      onReleased: {
                        root.volumeOpen = !root.volumeOpen
                        root.centerOpen = false
                      }
                    }
                  }
                }
              }

              Item {
                implicitWidth: Config.ui.barHeight - Config.ui.mainMargin
                implicitHeight: Config.ui.barHeight - Config.ui.mainMargin

                Rectangle {
                  anchors.fill: parent
                  radius: Config.ui.barHeight / 2
                  color: settingsMouseArea.containsMouse ? theme.hoverSubtle : "transparent"
                  Text {
                    anchors.centerIn: parent
                    text: "\uF013"
                    color: theme.fg
                    font.family: Config.ui.fontFamily
                    font.pixelSize: Config.ui.fontSize
                    transformOrigin: Item.Center
                    scale: settingsMouseArea.containsMouse ? 1.08 : 1
                    Behavior on scale {
                      NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.Linear }
                    }
                    MouseArea {
                      id: settingsMouseArea
                      anchors.fill: parent
                      hoverEnabled: true
                      onReleased: root.settingsMenuEnabled = !root.settingsMenuEnabled
                    }
                  }
                }
              }
              Item {
                implicitWidth: Config.ui.barHeight - Config.ui.mainMargin
                implicitHeight: Config.ui.barHeight - Config.ui.mainMargin

                Rectangle {
                  anchors.fill: parent
                  radius: Config.ui.barHeight / 2
                  color: wallpaperMouseArea.containsMouse ? theme.hoverSubtle : "transparent"
                  Text {
                    anchors.centerIn: parent
                    text: "󰸉"
                    color: theme.fg
                    font.family: Config.ui.fontFamily
                    font.pixelSize: Config.ui.fontSize
                    transformOrigin: Item.Center
                    scale: wallpaperMouseArea.containsMouse ? 1.08 : 1
                    Behavior on scale {
                      NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.Linear }
                    }
                    MouseArea {
                      id: wallpaperMouseArea
                      anchors.fill: parent
                      hoverEnabled: true
                      onReleased: root.wallpaperManagerOpen = !root.wallpaperManagerOpen
                    }
                  }
                }
              }
            }
          }

          Item {
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
            implicitWidth: clockText.implicitWidth + Config.ui.mainMargin * 4
            implicitHeight: clockText.implicitHeight + Config.ui.mainMargin

            Rectangle {
              anchors.fill: parent
              radius: Config.ui.barHeight / 2
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
                  NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.Linear }
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

              Item {
                implicitWidth: Config.ui.barHeight - Config.ui.mainMargin
                implicitHeight: Config.ui.barHeight - Config.ui.mainMargin

                Rectangle {
                  anchors.fill: parent
                  radius: Config.ui.barHeight / 2
                  color: videoMouseArea.containsMouse ? theme.hoverSubtle : "transparent"

                  Text {
                    id: videoIcon
                    anchors.centerIn: parent
                    text: "\uF03D"
                    color: theme.fg
                    font.family: Config.ui.fontFamily
                    font.pixelSize: Config.ui.fontSize
                    transformOrigin: Item.Center
                    scale: videoMouseArea.containsMouse ? 1.08 : 1
                    Behavior on scale {
                      NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.Linear }
                    }

                    MouseArea {
                      id: videoMouseArea
                      anchors.fill: parent
                      hoverEnabled: true
                      onReleased: {
                        root.videoScreen = modelData
                        root.videoOpen = !root.videoOpen
                        root.centerOpen = false
                        root.volumeOpen = false
                      }
                    }
                  }
                }
              }

              Item {
                implicitWidth: Config.ui.barHeight - Config.ui.mainMargin
                implicitHeight: Config.ui.barHeight - Config.ui.mainMargin

                Rectangle {
                  anchors.fill: parent
                  radius: height
                  color: bellMouseArea.containsMouse ? theme.hoverSubtle : "transparent"

                  Text {
                    id: bellIcon
                    anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                    text: ""
                    color: theme.fg
                    font.family: Config.ui.fontFamily
                    font.pixelSize: Config.ui.fontSize
                    transformOrigin: Item.Center
                    scale: bellMouseArea.containsMouse ? 1.08 : 1
                    Behavior on scale {
                      NumberAnimation { duration: Config.sleep.animationDurationShort; easing.type: Easing.Linear }
                    }

                    MouseArea {
                      id: bellMouseArea
                      anchors.fill: parent
                      hoverEnabled: true
                      onReleased: {
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
    }
  }
}
