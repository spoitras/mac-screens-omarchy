import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import "Model.js" as Model

Panel {
  id: root
  moduleName: "syl.mac-screens"
  ipcTarget: "syl.mac-screens"

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color hoverFill: bar ? Style.hoverFillFor(bar.foreground, Color.accent) : "transparent"

  property var macs: []
  property bool scanning: false

  function refresh() {
    if (browseProc.running) return
    scanning = true
    browseProc.running = true
  }

  function connectTo(mac) {
    if (!mac || !mac.address) return
    Quickshell.execDetached(["remmina", "-c", "vnc://" + mac.address + ":" + mac.port])
    root.close()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) refresh()

  // _rfb._tcp is the mDNS service type macOS Screen Sharing advertises.
  // Resolving here (rather than connecting by the .local hostname) is what
  // avoids the mDNS-resolution timeout seen when Remmina resolves it itself.
  Process {
    id: browseProc
    command: ["avahi-browse", "-r", "-p", "-t", "_rfb._tcp"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.macs = Model.parseBrowseOutput(text)
        root.scanning = false
      }
    }
  }

  Timer {
    interval: 15000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "Mac Screens"
    onPressed: root.toggle()
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(10)

        PanelSectionHeader {
          text: "MAC SCREENS"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        Text {
          textFormat: Text.PlainText
          visible: root.macs.length === 0
          width: parent.width
          text: root.scanning ? "Scanning…" : "No Macs found advertising Screen Sharing."
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        Column {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.macs
            MacRow {
              required property var modelData
              width: parent.width
              mac: modelData
            }
          }
        }
      }
    }
  }

  component MacRow: CursorSurface {
    id: row
    property var mac: null
    property bool hovered: false

    hasCursor: hovered
    foreground: root.foreground
    fill: root.hoverFill
    implicitHeight: rowContent.implicitHeight + Style.spacing.rowPaddingX

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: row.hovered = true
      onExited: row.hovered = false
      onClicked: root.connectTo(row.mac)
    }

    RowLayout {
      id: rowContent
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(8)

      Text {
        textFormat: Text.PlainText
        text: ""
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: row.mac ? row.mac.name : ""
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: row.mac ? row.mac.address + ":" + row.mac.port : ""
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }
}
