import QtQuick

import "../config.js" as Config

Item {
  id: root
  required property string icon
  signal clicked()

  readonly property bool hovered: mouseArea.containsMouse

  implicitWidth: Config.ui.iconButtonSize
  implicitHeight: Config.ui.iconButtonSize

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: root.hovered ? theme.hoverSubtle : "transparent"
  }

  Text {
    anchors.centerIn: parent
    text: root.icon
    color: theme.fg
    font.family: Config.ui.fontFamily
    font.pixelSize: Config.ui.fontSize
    transformOrigin: Item.Center
    scale: root.hovered ? 1.08 : 1
    Behavior on scale {
      NumberAnimation { duration: Config.animation.short; easing.type: Easing.Linear }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    onReleased: root.clicked()
  }
}