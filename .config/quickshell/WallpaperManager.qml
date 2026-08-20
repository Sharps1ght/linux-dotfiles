import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "config.js" as Config

Scope {
  FileViewInternal {
    id: wallpaperConfig
    __path: Quickshell.env("HOME") + "/.config/quickshell/wallpaper.json"
    watchChanges: true

    onLoaded: {
      root.wallpaperDirs = adapter.dirs || []
    }

    JsonAdapter {
      id: adapter
      property var dirs: []
    }

    function addDir(path) {
      if (!path || adapter.dirs.includes(path)) return
      adapter.dirs = adapter.dirs.concat([path])
      wallpaperConfig.writeAdapter()
      root.wallpaperDirs = adapter.dirs
    }

    function removeDir(index) {
      var arr = adapter.dirs.slice()
      arr.splice(index, 1)
      adapter.dirs = arr
      wallpaperConfig.writeAdapter()
      root.wallpaperDirs = adapter.dirs
    }
  }

  Variants {
    model: Quickshell.screens

    OverlayPanel {
      id: wallpaperManagerPanel
      required property var modelData
      screen: modelData
      anchors { top: true }
      margins {
        top: root.barVisible ? Config.ui.barHeight + Config.ui.mainMargin * 2 : Config.ui.mainMargin
        left: Config.ui.mainMargin
      }
      visible: wallpaperManagerPanelState

      property bool wallpaperManagerPanelState: false
      property bool spawning: false
      property bool closing: false

      property var imageFiles: []
      property int currentIndex: -1
      property string currentImagePath: ""
      property bool dirListOpen: false

      function syncState() {
        const shouldShow = root.wallpaperManagerOpen && root.focusedScreen === modelData
        if (shouldShow) {
          if (!wallpaperManagerPanelState) {
            closeTimer.stop()
            closing = false
            wallpaperManagerPanelState = true
            spawnFadeIn()
          }
        } else {
          fadeClose()
        }
      }

      function spawnFadeIn() {
        spawning = false
        wallpaperManagerBox.opacity = 0
        Qt.callLater(() => {
          spawning = true
          wallpaperManagerBox.opacity = 1
        })
      }

      function fadeClose() {
        if (!wallpaperManagerPanelState || closing) return
        spawning = false
        closing = true
        wallpaperManagerBox.opacity = 0
        closeTimer.start()
      }

      function updateImageFiles() {
        var files = []
        for (var i = 0; i < folderModel.count; i++) {
          var name = folderModel.get(i, "fileName")
          var isDir = folderModel.get(i, "fileIsDir")
          if (!isDir) {
            var ext = name.split('.').pop().toLowerCase()
            if (["jpg", "jpeg", "png", "gif", "bmp", "webp", "svg"].includes(ext)) {
              files.push({
                name: name,
                path: folderModel.get(i, "filePath")
              })
            }
          }
        }
        imageFiles = files
        if (files.length > 0 && currentIndex < 0) {
          currentIndex = 0
          currentImagePath = files[0].path
        } else if (files.length === 0) {
          currentIndex = -1
          currentImagePath = ""
        } else if (currentIndex >= files.length) {
          currentIndex = files.length - 1
          currentImagePath = files[currentIndex].path
        }
      }

      function navigateTo(path) {
        if (path && path.length > 0) {
          folderModel.folder = "file://" + path
          root.wallpaperDir = path
        }
      }

      function updateComboModel() {
        comboModel.clear()

        for (var i = 0; i < root.wallpaperDirs.length; i++) {
          var dirPath = root.wallpaperDirs[i]
          var dirName = dirPath.split("/").pop() || dirPath
          comboModel.append({
            itemType: "saved",
            itemName: dirName,
            itemPath: dirPath,
            savedIndex: i
          })
        }

        var currentPath = folderModel.folder.toString().replace("file://", "")
        if (currentPath && root.wallpaperDirs.indexOf(currentPath) === -1) {
          var currentName = currentPath.split("/").pop() || currentPath
          comboModel.append({
            itemType: "unsaved",
            itemName: currentName,
            itemPath: currentPath,
            savedIndex: -1
          })
        }

        comboModel.append({ itemType: "separator", itemName: "---", itemPath: "", savedIndex: -1 })

        var parentFolder = folderModel.parentFolder
        if (parentFolder.toString() !== "" && parentFolder.toString() !== "file://") {
          var parentPath = parentFolder.toString().replace("file://", "")
          comboModel.append({
            itemType: "dir",
            itemName: "../",
            itemPath: parentPath,
            savedIndex: -1
          })
        }

        for (var j = 0; j < folderModel.count; j++) {
          var name = folderModel.get(j, "fileName")
          var isDir = folderModel.get(j, "fileIsDir")
          var filePath = folderModel.get(j, "filePath")

          if (isDir) {
            comboModel.append({
              itemType: "dir",
              itemName: name,
              itemPath: filePath,
              savedIndex: -1
            })
          } else {
            var ext = name.split('.').pop().toLowerCase()
            if (["jpg", "jpeg", "png", "gif", "bmp", "webp", "svg"].indexOf(ext) !== -1) {
              comboModel.append({
                itemType: "image",
                itemName: name,
                itemPath: filePath,
                savedIndex: -1
              })
            }
          }
        }
      }

      Connections {
        target: root
        function onWallpaperManagerOpenChanged() { syncState() }
        function onFocusedScreenChanged() { syncState() }
        function onWallpaperDirsChanged() { wallpaperManagerPanel.updateComboModel() }
      }

      Timer {
        id: closeTimer
        interval: Config.sleep.animationDuration
        onTriggered: {
          closing = false
          wallpaperManagerPanelState = false
        }
      }

      implicitHeight: wallpaperManagerColumn.implicitHeight + Config.ui.mainMargin * 4
      implicitWidth: wallpaperManagerColumn.implicitWidth + Config.ui.mainMargin * 4
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore

      Rectangle {
        id: wallpaperManagerBox
        anchors.fill: parent
        radius: Config.ui.fontSize
        clip: true
        color: theme.panelBg

        Behavior on opacity {
          enabled: spawning || closing
          NumberAnimation { duration: Config.sleep.animationDuration; easing.type: Easing.Linear }
        }

        FolderListModel {
          id: folderModel
          folder: root.wallpaperDir ? "file://" + root.wallpaperDir : ""
          nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp", "*.webp", "*.svg"]
          showDirs: true
          showDotAndDotDot: false
          sortField: FolderListModel.Name

          onStatusChanged: {
            if (status === FolderListModel.Ready) {
              wallpaperManagerPanel.updateImageFiles()
              wallpaperManagerPanel.updateComboModel()
            }
          }
        }

        ListModel { id: comboModel }

        ColumnLayout {
          id: wallpaperManagerColumn
          anchors { top: parent.top; left: parent.left; }
          anchors.margins: Config.ui.mainMargin * 2
          spacing: Config.ui.mainMargin * 2

          Text {
            text: "Wallpaper Manager"
            color: theme.heading
            font.bold: true
            font.family: Config.ui.fontFamily
            font.pixelSize: Config.ui.fontSize + 2
            Layout.alignment: Qt.AlignHCenter
          }

          RowLayout {
            spacing: Config.ui.mainMargin
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
              implicitWidth: Config.ui.fontSize * 2
              implicitHeight: Config.ui.fontSize * 2
              radius: Config.ui.fontSize
              color: prevButtonArea.containsMouse ? theme.hoverSubtle : "transparent"

              Text {
                anchors.centerIn: parent
                text: ""
                color: theme.fg
                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize
              }

              MouseArea {
                id: prevButtonArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                  if (wallpaperManagerPanel.imageFiles.length === 0) return
                  var len = wallpaperManagerPanel.imageFiles.length
                  wallpaperManagerPanel.currentIndex = (wallpaperManagerPanel.currentIndex - 1 + len) % len
                  wallpaperManagerPanel.currentImagePath = wallpaperManagerPanel.imageFiles[wallpaperManagerPanel.currentIndex].path
                }
              }
            }

            Rectangle {
              implicitWidth: 640
              implicitHeight: 360
              color: "transparent"
              radius: Config.ui.fontSize

              Image {
                anchors.fill: parent
                anchors.margins: 1
                source: wallpaperManagerPanel.currentImagePath ? "file://" + wallpaperManagerPanel.currentImagePath : ""
                fillMode: Image.PreserveAspectFit
                visible: wallpaperManagerPanel.currentImagePath !== ""
              }

              Text {
                anchors.centerIn: parent
                text: "No image selected"
                color: theme.muted
                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize - 4
                visible: wallpaperManagerPanel.currentImagePath === ""
              }
            }

            Rectangle {
              implicitWidth: Config.ui.fontSize * 2
              implicitHeight: Config.ui.fontSize * 2
              radius: Config.ui.fontSize
              color: nextButtonArea.containsMouse ? theme.hoverSubtle : "transparent"

              Text {
                anchors.centerIn: parent
                text: ""
                color: theme.fg
                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize
              }

              MouseArea {
                id: nextButtonArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                  if (wallpaperManagerPanel.imageFiles.length === 0) return
                  var len = wallpaperManagerPanel.imageFiles.length
                  wallpaperManagerPanel.currentIndex = (wallpaperManagerPanel.currentIndex + 1) % len
                  wallpaperManagerPanel.currentImagePath = wallpaperManagerPanel.imageFiles[wallpaperManagerPanel.currentIndex].path
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: Config.ui.fontSize + Config.ui.mainMargin * 4
            radius: Config.ui.fontSize
            color: wallpaperManagerPanel.dirListOpen ? theme.hoverSubtle : theme.panelBg

            Text {
              anchors { left: parent.left; leftMargin: Config.ui.mainMargin * 4; verticalCenter: parent.verticalCenter }
              text: {
                if (wallpaperManagerPanel.currentImagePath) {
                  var parts = wallpaperManagerPanel.currentImagePath.split("/")
                  return parts[parts.length - 1]
                }
                return "No image"
              }
              color: theme.fg
              font.family: Config.ui.fontFamily
              font.pixelSize: Config.ui.fontSize - 2
              elide: Text.ElideRight
              width: parent.width - dirToggleArrow.width - Config.ui.mainMargin * 4
            }

            MouseArea {
              id: dirToggleArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: wallpaperManagerPanel.dirListOpen = !wallpaperManagerPanel.dirListOpen
            }

            Rectangle {
              id: dirToggleArrow
              implicitWidth: Config.ui.fontSize * 1.5
              implicitHeight: Config.ui.fontSize * 1.5
              radius: Config.ui.fontSize
              color: (arrowHoverArea.containsMouse || dirToggleArea.containsMouse) ? theme.hoverSubtle : "transparent"

              anchors { right: parent.right; rightMargin: Config.ui.mainMargin - 2; verticalCenter: parent.verticalCenter }

              Text {
                anchors.centerIn: parent
                text: wallpaperManagerPanel.dirListOpen ? "" : ""
                color: theme.fg

                Behavior on color {
                  NumberAnimation { duration: Config.sleep.animationDuration * 5; easing.type: Easing.Linear}
                }

                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize
              }

              MouseArea {
                id: arrowHoverArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
              }
            }
          }

          RowLayout {
            visible: wallpaperManagerPanel.dirListOpen
            Layout.fillWidth: true
            spacing: Config.ui.mainMargin

            ListView {
              id: dirListView
              Layout.fillWidth: true
              Layout.fillHeight: true
              Layout.preferredHeight: Math.min(contentHeight, modelData.height / 2)
              model: comboModel
              clip: true
              spacing: Config.ui.mainMargin / 4

              ScrollBar.vertical: ScrollBar {
                id: dirScrollBar
                policy: dirListView.contentHeight > dirListView.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                contentItem: Rectangle {
                  implicitWidth: Config.ui.mainMargin * 2
                  radius: width / 2
                  color: dirScrollBar.pressed ? theme.hoverStrong : theme.hoverSubtle
                }
                background: Rectangle {
                  implicitWidth: Config.ui.mainMargin * 2
                  radius: width / 2
                  color: "transparent"
                }
              }

              delegate: Rectangle {
                width: dirListView.width - (dirScrollBar.visible ? Config.ui.mainMargin * 2 + Config.ui.mainMargin : 0)
                implicitHeight: Config.ui.fontSize + Config.ui.mainMargin * 2
                radius: Config.ui.fontSize / 2
                color: inlineRowMouseArea.containsMouse ? theme.hoverSubtle : "transparent"

                MouseArea {
                  id: inlineRowMouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    if (model.itemType === "dir" || model.itemType === "saved" || model.itemType === "unsaved") {
                      wallpaperManagerPanel.navigateTo(model.itemPath)
                    } else if (model.itemType === "image") {
                      var files = wallpaperManagerPanel.imageFiles
                      for (var i = 0; i < files.length; i++) {
                        if (files[i].path === model.itemPath) {
                          wallpaperManagerPanel.currentIndex = i
                          wallpaperManagerPanel.currentImagePath = model.itemPath
                          break
                        }
                      }
                    }
                  }
                }

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Config.ui.mainMargin
                  spacing: Config.ui.mainMargin

                  Rectangle {
                    implicitWidth: Config.ui.fontSize + Config.ui.mainMargin
                    implicitHeight: Config.ui.fontSize + Config.ui.mainMargin
                    radius: Config.ui.fontSize / 2
                    color: inlineActionMouseArea.containsMouse ? theme.hoverSubtle : "transparent"
                    visible: model.itemType === "saved" || model.itemType === "unsaved"

                    Text {
                      anchors.centerIn: parent
                      text: model.itemType === "saved" ? "\u2715" : "\u2733\uFE0F"
                      color: inlineActionMouseArea.containsMouse ? theme.fg : theme.muted
                      font.family: Config.ui.fontFamily
                      font.pixelSize: Config.ui.fontSize - 6
                    }

                    MouseArea {
                      id: inlineActionMouseArea
                      anchors.fill: parent
                      hoverEnabled: true
                      onClicked: {
                        if (model.itemType === "saved") {
                          wallpaperConfig.removeDir(model.savedIndex)
                        } else if (model.itemType === "unsaved") {
                          wallpaperConfig.addDir(model.itemPath)
                        }
                      }
                    }
                  }

                  Text {
                    text: {
                      if (model.itemType === "saved") return model.itemName
                      if (model.itemType === "unsaved") return model.itemName
                      if (model.itemType === "dir") return "\uD83D\uDCC1 " + model.itemName
                      if (model.itemType === "image") return "\uD83D\uDDBC\uFE0F " + model.itemName
                      if (model.itemType === "separator") return "---"
                      return model.itemName
                    }
                    color: theme.fg
                    font.family: Config.ui.fontFamily
                    font.pixelSize: Config.ui.fontSize - 4
                    elide: Text.ElideRight
                    Layout.fillWidth: true
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
