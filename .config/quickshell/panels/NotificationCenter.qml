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
    anchors { top: true; right: true }
    margins {
      top: root.barVisible ? Config.ui.barHeight + Config.ui.mainMargin * 2 : Config.ui.mainMargin
      right: Config.ui.mainMargin
    }
    visible: panelState

    panelBox: centerBox

    function syncState() {
      syncPanelState(root.centerOpen && root.focusedScreen === modelData)
    }

    Connections {
      target: root
      function onCenterOpenChanged() { syncState() }
      function onFocusedScreenChanged() { syncState() }
    }

    implicitWidth: Config.ui.notificationIconSize + Config.ui.barHeight * 8 + Config.ui.mainMargin * 4

    property real targetHeight: centerColumn.implicitHeight + Config.ui.mainMargin * 4
    property real animatedHeight: targetHeight

    onTargetHeightChanged: animatedHeight = targetHeight

    Behavior on animatedHeight {
      NumberAnimation { duration: Config.animation.normal; easing.type: Easing.InOutCubic }
    }

    implicitHeight: animatedHeight
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      id: centerBox
      anchors.fill: parent
      radius: Config.ui.fontSize
      clip: true
      color: theme.panelBg

      Behavior on opacity {
        enabled: spawning || closing
        NumberAnimation { duration: Config.animation.normal; easing.type: Easing.InOutCubic }
      }

      Column {
        id: centerColumn
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors.margins: Config.ui.mainMargin * 2
        height: centerColumn.implicitHeight
        spacing: Config.ui.mainMargin / 2

        RowLayout {
          width: parent.width

          Text {
            Layout.fillWidth: true
            text: "Notifications"
            color: theme.heading
            font.family: Config.ui.fontFamily
            font.pixelSize: Config.ui.fontSize + 2
            font.bold: true
          }

          Text {
            text: Config.icons.close
            visible: history.count > 0
            color: xMouseArea.containsMouse ? theme.fg : theme.error
            font.family: Config.ui.fontFamily
            font.pixelSize: Config.ui.fontSize + 2
            style: xMouseArea.containsMouse ? Text.Outline : Text.Normal
            styleColor: theme.textOutline
            MouseArea {
              id: xMouseArea
              anchors.fill: parent
              hoverEnabled: true
              onReleased: history.clear()
            }
          }
        }
        Repeater {
          model: history
          delegate: Rectangle {
            id: card
            required property var modelData
            width: centerColumn.width
            implicitHeight: delegateLayout.implicitHeight + Config.ui.mainMargin * 3
            radius: Config.ui.fontSize
            clip: true
            transformOrigin: Item.Center
            color: historyCardMouse.containsMouse ? theme.hoverStrong : theme.muted

            property bool dismissing: false
            property bool positionReady: false

            Behavior on scale {
              NumberAnimation { duration: Config.animation.normal; easing.type: Easing.InOutCubic }
            }
            Behavior on opacity {
              NumberAnimation { duration: Config.animation.normal; easing.type: Easing.InOutCubic }
            }
            Behavior on y {
              enabled: card.positionReady
              NumberAnimation { duration: Config.animation.normal; easing.type: Easing.InOutCubic }
            }

            Component.onCompleted: Qt.callLater(() => card.positionReady = true)

            Timer {
              id: dismissTimer
              interval: Config.animation.normal
              onTriggered: root.removeFromHistory(card.modelData.id)
            }

            function animateDismiss() {
              if (card.dismissing) return
              card.dismissing = true
              card.scale = 0
              card.opacity = 0
              dismissTimer.start()
            }

            Connections {
              target: root
              function onDismissNotification(id) {
                if (id === card.modelData.id) card.animateDismiss()
              }
            }

            RowLayout {
              id: delegateLayout
              anchors { left: parent.left; right: parent.right; top: parent.top }
              anchors.margins: Config.ui.mainMargin * 2
              spacing: Config.ui.mainMargin / 2

              Image {
                Layout.preferredHeight: Config.ui.notificationIconSize
                Layout.preferredWidth: Config.ui.notificationIconSize
                Layout.alignment: Qt.AlignCenter
                fillMode: Image.PreserveAspectFit
                visible: source.toString() !== ""
                source: modelData.image || modelData.appIcon || ""
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: Config.ui.mainMargin / 4

                Text {
                  Layout.fillWidth: true
                  text: modelData.summary
                  color: theme.heading
                  font.bold: true
                  wrapMode: Text.WordWrap
                  font.family: Config.ui.fontFamily
                  font.pixelSize: Config.ui.fontSize
                }

                Text {
                  Layout.fillWidth: true
                  visible: text !== ""
                  text: modelData.body
                  color: theme.fg
                  font.family: Config.ui.fontFamily
                  font.pixelSize: Config.ui.fontSize - 4
                  wrapMode: Text.WordWrap
                }

                Text {
                  text: (modelData.appName ? modelData.appName + " • " : "") + modelData.time
                  color: theme.fg
                  font.family: Config.ui.fontFamily
                  font.pixelSize: Config.ui.fontSize - 8
                }
                MouseArea {
                  id: historyCardMouse
                  anchors.fill: parent
                  hoverEnabled: true
                }
              }
              Text {
                text: Config.icons.close
                Layout.alignment: Qt.AlignTop
                color: centerDismissMouse.containsMouse ? theme.fg : theme.error
                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize + 2
                MouseArea {
                  id: centerDismissMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  onReleased: root.dismissCenterEntry(modelData.id)
                }
              }
            }
          }
        }
      }
    }
  }
}