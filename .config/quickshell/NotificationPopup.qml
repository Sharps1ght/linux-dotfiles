import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

import "config.js" as Config

OverlayPanel {
  screen: root.focusedScreen
  visible: server.trackedNotifications.values.length > 0
  anchors { top: true; right: true }
  margins {
    top: root.barVisible ? Config.ui.barHeight + Config.ui.mainMargin * 2 : Config.ui.mainMargin
    right: Config.ui.mainMargin
  }

  implicitWidth: Config.ui.notificationIconSize + Config.ui.barHeight * 8 + Config.ui.mainMargin * 4
  implicitHeight: column.implicitHeight + Config.ui.mainMargin * 2
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore

  ColumnLayout {
    id: column
    width: parent.width
    spacing: Config.ui.mainMargin / 2

    Repeater {
      model: server.trackedNotifications
      delegate: Rectangle {
        id: card
        radius: Config.ui.fontSize
        clip: true
        required property var modelData
        scale: 0
        opacity: 0
        transformOrigin: Item.Center

        Behavior on scale {
          NumberAnimation { duration: Config.sleep.animationDuration; easing.type: Easing.InOutCubic }
        }
        Behavior on opacity {
          NumberAnimation { duration: Config.sleep.animationDuration; easing.type: Easing.InOutCubic }
        }

        Component.onCompleted: {
          scale = 1
          opacity = 1
        }

        property bool dismissing: false

        Timer {
          id: dismissTimer
          interval: Config.sleep.animationDuration
          onTriggered: card.modelData.dismiss()
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

        Layout.fillWidth: true
        implicitHeight: layout.implicitHeight + Config.ui.mainMargin * 2
        implicitWidth: Config.ui.notificationIconSize + Config.ui.mainMargin * 4
        color: cardMouseArea.containsMouse ? theme.hoverStrong : theme.panelBg

        Timer {
          running: card.modelData.urgency !== NotificationUrgency.Critical
          interval: Config.sleep.notificationTimeout
          onTriggered: card.animateDismiss()
        }

        border.width: modelData.urgency === NotificationUrgency.Critical ? 2 : 0
        border.color: modelData.urgency === NotificationUrgency.Critical ? theme.error : "transparent"

        RowLayout {
          id: layout
          anchors { left: parent.left; right: parent.right; top: parent.top }
          anchors.margins: Config.ui.mainMargin
          spacing: Config.ui.mainMargin

          Image {
            id: notificationIcon
            Layout.preferredHeight: Config.ui.notificationIconSize
            Layout.preferredWidth: Config.ui.notificationIconSize
            Layout.alignment: Qt.AlignCenter
            fillMode: Image.PreserveAspectFit
            visible: source.toString() !== ""
            source: card.modelData.image || card.modelData.appIcon || ""
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.ui.mainMargin

            Text {
              id: notificationTitle
              Layout.fillWidth: true
              text: card.modelData.summary
              color: theme.heading
              font.family: Config.ui.fontFamily
              font.pixelSize: Config.ui.fontSize
              font.bold: true
              wrapMode: Text.WordWrap
            }

            Text {
              Layout.fillWidth: true
              visible: text !== ""
              text: card.modelData.body
              color: theme.fg
              font.family: Config.ui.fontFamily
              font.pixelSize: Config.ui.fontSize - 4
              wrapMode: Text.WordWrap
            }
          }
        }

        MouseArea {
          id: cardMouseArea
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.RightButton
          onReleased: {
            if (card.modelData.urgency !== NotificationUrgency.Critical)
              root.dismissNotification(card.modelData.id)
            else
              card.animateDismiss()
          } 
        }
      }
    }
  }
}
