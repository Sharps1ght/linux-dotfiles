import Quickshell
import Quickshell.Wayland

PanelWindow {
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: keyboardFocus

    property var keyboardFocus: WlrKeyboardFocus.None
}
