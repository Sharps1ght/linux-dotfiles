import QtQuick
import QtQuick.Controls

import "../config.js" as Config

Slider {
  id: control

  property string trackColor: theme.hoverStrong
  property string fillColor: theme.accent
  property string handleColor: theme.fg
  property real trackHeight: 6
  property real handleSize: 14

  background: Rectangle {
    x: control.leftPadding
    y: control.topPadding + control.availableHeight / 2 - height / 2
    width: control.availableWidth
    height: control.trackHeight
    radius: height / 2
    color: control.trackColor

    Rectangle {
      width: control.visualPosition * parent.width
      height: parent.height
      radius: height / 2
      color: control.fillColor
    }
  }

  handle: Rectangle {
    x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
    y: control.topPadding + control.availableHeight / 2 - height / 2
    width: control.handleSize
    height: control.handleSize
    radius: width / 2
    color: control.handleColor
  }
}