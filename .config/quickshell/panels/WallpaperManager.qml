import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Qt.labs.folderlistmodel
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.components

import "../config.js" as Config

Scope {
  FileViewInternal {
    id: wallpaperConfig
    __path: Quickshell.env("HOME") + "/.config/quickshell/wallpaper.json"
    watchChanges: true

    onLoaded: {
      root.wallpaperDirs = adapter.dirs || []
      if (adapter.lastDir) {
        root.wallpaperDir = adapter.lastDir
      }
      if (adapter.lastImage) {
        root.wallpaperLastImage = adapter.lastImage
      }
    }

    JsonAdapter {
      id: adapter
      property var dirs: []
      property string lastDir: ""
      property string lastImage: ""
    }

    function addDir(path) {
      if (!path || adapter.dirs.includes(path)) return
      adapter.dirs = adapter.dirs.concat([path])
      wallpaperConfig.writeAdapter()
      root.wallpaperDirs = adapter.dirs
    }

    function removeDir(index) {
      const arr = adapter.dirs.slice()
      arr.splice(index, 1)
      adapter.dirs = arr
      wallpaperConfig.writeAdapter()
      root.wallpaperDirs = adapter.dirs
    }
  }

  Process {
    id: awwwQueryProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const data = JSON.parse(text)
          const ns = data[""]
          const result = {}
          for (let i = 0; i < ns.length; i++) {
            result[ns[i].name] = ns[i].displaying.image || ""
          }
          root.awwwWallpapers = result
        } catch (e) {}
      }
    }
  }

  Process {
    id: awwwApplyProc
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
      visible: panelState

      panelBox: wallpaperManagerBox

      property string activeWallpaper: root.awwwWallpapers[modelData.name] || ""
      property string hoveredImagePath: ""
      property string pendingHoveredImage: ""

      property var imageFiles: []
      property int currentIndex: -1
      property string currentImagePath: ""
      property bool dirListOpen: false

      Timer {
        id: hoverDebounceTimer
        interval: Config.animation.normal
        onTriggered: wallpaperManagerPanel.hoveredImagePath = wallpaperManagerPanel.pendingHoveredImage
      }

      function syncState() {
        syncPanelState(root.wallpaperManagerOpen && root.focusedScreen === modelData)
      }

      function updateImageFiles() {
        const files = []
        for (let i = 0; i < folderModel.count; i++) {
          const name = folderModel.get(i, "fileName")
          const isDir = folderModel.get(i, "fileIsDir")
          if (!isDir) {
            const ext = name.split(".").pop().toLowerCase()
            if (Config.ui.imageExtensions.includes(ext)) {
              files.push({
                name: name,
                path: folderModel.get(i, "filePath")
              })
            }
          }
        }
        imageFiles = files
        if (files.length > 0) {
          if (root.wallpaperLastImage) {
            for (let k = 0; k < files.length; k++) {
              if (files[k].path === root.wallpaperLastImage) {
                currentIndex = k
                currentImagePath = files[k].path
                return
              }
            }
          }
          if (currentIndex < 0 || currentIndex >= files.length) {
            currentIndex = 0
            currentImagePath = files[0].path
          }
        } else if (files.length === 0) {
          currentIndex = -1
          currentImagePath = ""
        }
      }

      function navigateTo(path) {
        if (path && path.length > 0) {
          folderModel.folder = "file://" + path
          root.wallpaperDir = path
          adapter.lastDir = path
          wallpaperConfig.writeAdapter()
        }
      }

      function updateComboModel() {
        comboModel.clear()

        for (let i = 0; i < root.wallpaperDirs.length; i++) {
          const dirPath = root.wallpaperDirs[i]
          const dirName = dirPath.split("/").pop() || dirPath
          comboModel.append({
            itemType: "saved",
            itemName: dirName,
            itemPath: dirPath,
            savedIndex: i
          })
        }

        const currentPath = folderModel.folder.toString().replace("file://", "")
        if (currentPath && root.wallpaperDirs.indexOf(currentPath) === -1) {
          const currentName = currentPath.split("/").pop() || currentPath
          comboModel.append({
            itemType: "unsaved",
            itemName: currentName,
            itemPath: currentPath,
            savedIndex: -1
          })
        }

        comboModel.append({ itemType: "separator", itemName: "---", itemPath: "", savedIndex: -1 })

        const parentFolder = folderModel.parentFolder
        if (parentFolder.toString() !== "" && parentFolder.toString() !== "file://") {
          const parentPath = parentFolder.toString().replace("file://", "")
          comboModel.append({
            itemType: "dir",
            itemName: "../",
            itemPath: parentPath,
            savedIndex: -1
          })
        }

        for (let j = 0; j < folderModel.count; j++) {
          const name = folderModel.get(j, "fileName")
          const isDir = folderModel.get(j, "fileIsDir")
          const filePath = folderModel.get(j, "filePath")

          if (isDir) {
            comboModel.append({
              itemType: "dir",
              itemName: name,
              itemPath: filePath,
              savedIndex: -1
            })
          } else {
            const ext = name.split(".").pop().toLowerCase()
            if (Config.ui.imageExtensions.includes(ext)) {
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
        function onWallpaperManagerOpenChanged() {
          if (root.wallpaperManagerOpen) {
            awwwQueryProc.exec(["awww", "query", "--json"])
          }
          syncState()
        }
        function onFocusedScreenChanged() { syncState() }
        function onWallpaperDirsChanged() { wallpaperManagerPanel.updateComboModel() }
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
          NumberAnimation { duration: Config.animation.normal; easing.type: Easing.Linear }
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
                text: Config.icons.prev
                color: theme.fg
                scale: prevButtonArea.containsMouse ? 1.25 : 1

                Behavior on scale {
                  NumberAnimation { duration: Config.animation.short; easing.type: Easing.Linear }
                }

                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize
              }

              MouseArea {
                id: prevButtonArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                  if (wallpaperManagerPanel.imageFiles.length === 0) return
                  const len = wallpaperManagerPanel.imageFiles.length
                  wallpaperManagerPanel.currentIndex = (wallpaperManagerPanel.currentIndex - 1 + len) % len
                  wallpaperManagerPanel.currentImagePath = wallpaperManagerPanel.imageFiles[wallpaperManagerPanel.currentIndex].path
                  root.wallpaperLastImage = wallpaperManagerPanel.currentImagePath
                  adapter.lastImage = wallpaperManagerPanel.currentImagePath
                  wallpaperConfig.writeAdapter()
                }
              }
            }

            Rectangle {
              implicitWidth: Config.ui.wallpaperPreviewWidth
              implicitHeight: Config.ui.wallpaperPreviewHeight
              color: "transparent"
              radius: Config.ui.fontSize

              property string displayImage: wallpaperManagerPanel.hoveredImagePath || wallpaperManagerPanel.activeWallpaper

              Image {
                anchors.fill: parent
                anchors.margins: 1
                source: parent.displayImage ? "file://" + parent.displayImage : ""
                fillMode: Image.PreserveAspectFit
                visible: parent.displayImage !== ""
              }

              Text {
                anchors.centerIn: parent
                text: "No active wallpaper"
                color: theme.muted
                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize - 4
                visible: parent.displayImage === ""
              }
            }

            Rectangle {
              implicitWidth: Config.ui.fontSize * 2
              implicitHeight: Config.ui.fontSize * 2
              radius: Config.ui.fontSize
              color: nextButtonArea.containsMouse ? theme.hoverSubtle : "transparent"

              Text {
                anchors.centerIn: parent
                text: Config.icons.next
                color: theme.fg
                scale: nextButtonArea.containsMouse ? 1.25 : 1

                Behavior on scale {
                  NumberAnimation { duration: Config.animation.short; easing.type: Easing.Linear }
                }

                font.family: Config.ui.fontFamily
                font.pixelSize: Config.ui.fontSize
              }

              MouseArea {
                id: nextButtonArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                  if (wallpaperManagerPanel.imageFiles.length === 0) return
                  const len = wallpaperManagerPanel.imageFiles.length
                  wallpaperManagerPanel.currentIndex = (wallpaperManagerPanel.currentIndex + 1) % len
                  wallpaperManagerPanel.currentImagePath = wallpaperManagerPanel.imageFiles[wallpaperManagerPanel.currentIndex].path
                  root.wallpaperLastImage = wallpaperManagerPanel.currentImagePath
                  adapter.lastImage = wallpaperManagerPanel.currentImagePath
                  wallpaperConfig.writeAdapter()
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
                const img = wallpaperManagerPanel.hoveredImagePath || wallpaperManagerPanel.activeWallpaper
                if (img) {
                  const parts = img.split("/")
                  return parts[parts.length - 1]
                }
                return "No active wallpaper"
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
                text: wallpaperManagerPanel.dirListOpen ? Config.icons.chevronUp : Config.icons.chevronDown
                color: theme.fg
                scale: arrowHoverArea.containsMouse ? 1.25 : 1

                Behavior on scale {
                  NumberAnimation { duration: Config.animation.short; easing.type: Easing.Linear }
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
                  onEntered: {
                    if (model.itemType === "image") {
                      wallpaperManagerPanel.pendingHoveredImage = model.itemPath
                      hoverDebounceTimer.restart()
                    }
                  }
                  onReleased: {
                    if (model.itemType === "dir" || model.itemType === "saved" || model.itemType === "unsaved") {
                      wallpaperManagerPanel.navigateTo(model.itemPath)
                    } else if (model.itemType === "image") {
                      awwwApplyProc.exec(["awww", "img", "-o", wallpaperManagerPanel.modelData.name, model.itemPath])
                      root.awwwWallpapers[wallpaperManagerPanel.modelData.name] = model.itemPath
                      const files = wallpaperManagerPanel.imageFiles
                      for (let i = 0; i < files.length; i++) {
                        if (files[i].path === model.itemPath) {
                          wallpaperManagerPanel.currentIndex = i
                          wallpaperManagerPanel.currentImagePath = model.itemPath
                          break
                        }
                      }
                      root.wallpaperLastImage = model.itemPath
                      adapter.lastImage = model.itemPath
                      wallpaperConfig.writeAdapter()
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
                      text: model.itemType === "saved" ? Config.icons.bookmarkRemove : Config.icons.bookmarkAdd
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
                    text: model.itemType === "dir" ? Config.icons.folder : Config.icons.picture
                    visible: model.itemType === "dir" || model.itemType === "image"
                    color: theme.fg
                    font.family: Config.ui.fontFamily
                    font.pixelSize: Config.ui.fontSize - 4
                    Layout.alignment: Qt.AlignVCenter
                  }

                  Text {
                    text: model.itemName
                    color: theme.fg
                    font.family: Config.ui.fontFamily
                    font.pixelSize: Config.ui.fontSize - 4
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
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