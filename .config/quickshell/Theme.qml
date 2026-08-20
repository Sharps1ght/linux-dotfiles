import QtQuick

QtObject {
    readonly property string currentTheme: "mocha"

    readonly property var themes: ({
        "tokyo": {
            bg: "#1a1b26",
            bgAlt: "#16161e",
            fg: "#a9b1d6",
            fgBright: "#c0caf5",
            muted: "#565f89",
            surface: "#24283b",
            accent: "#7dcfff",
            blue: "#7aa2f7",
            purple: "#bb9af7",
            red: "#f7768e",
            yellow: "#e0af68",
            green: "#9ece6a",
            orange: "#ff9e64",
            panelBg: "#1a1b26",
        },
        "mocha": {
            bg: "#1e1e2e",
            bgAlt: "#181825",
            fg: "#cdd6f4",
            fgBright: "#cdd6f4",
            muted: "#6c7086",
            surface: "#313244",
            accent: "#89dceb",
            blue: "#89b4fa",
            purple: "#cba6f7",
            red: "#f38ba8",
            yellow: "#f9e2af",
            green: "#a6e3a1",
            orange: "#fab387",
            panelBg: "#1e1e2e",
        }
    })

    readonly property var t: themes[currentTheme] || themes["tokyo"]

    readonly property color panelBg: t.panelBg
    readonly property color bg: t.bg
    readonly property color surface: t.surface
    readonly property color fg: t.fg
    readonly property color fgBright: t.fgBright
    readonly property color muted: t.muted
    readonly property color accent: t.accent
    readonly property color heading: t.accent
    readonly property color blue: t.blue
    readonly property color red: t.red
    readonly property color green: t.green
    readonly property color yellow: t.yellow
    readonly property color orange: t.orange
    readonly property color purple: t.purple
    readonly property color todayBg: t.blue
    readonly property color todayFg: t.bg
    readonly property color error: t.red

    readonly property color hoverSubtle: "#40ffffff"
    readonly property color hoverStrong: "#80ffffff"
    readonly property color textOutline: "#80151515"
    readonly property color textOutlineLight: "#88151515"
}
