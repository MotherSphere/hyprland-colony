import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Mpris

ShellRoot {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Workspace actif
    readonly property int activeWsId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
    readonly property string activeTitle: Hyprland.focusedMonitor?.activeWorkspace?.focusedToplevel?.title ?? "Desktop"

    // Audio
    readonly property PwNode audioSink: Pipewire.defaultAudioSink
    readonly property real audioVolume: audioSink?.audio?.volume ?? 0
    readonly property bool audioMuted: !!audioSink?.audio?.muted

    function setVolume(vol) {
        if (audioSink?.ready && audioSink?.audio)
            audioSink.audio.volume = Math.max(0, Math.min(1, vol));
    }

    function toggleMute() {
        if (audioSink?.ready && audioSink?.audio)
            audioSink.audio.muted = !audioSink.audio.muted;
    }

    PwObjectTracker {
        objects: [root.audioSink]
    }

    // Notifications
    property list<var> activeNotifs: []

    NotificationServer {
        id: notifServer

        onNotification: notification => {
            const now = Date.now();
            const notif = {
                uid: now,
                id: notification.id,
                summary: notification.summary,
                body: notification.body,
                appName: notification.appName,
                appIcon: notification.appIcon,
                image: notification.image ?? "",
                urgency: notification.urgency,
                timestamp: now
            };
            root.activeNotifs = [notif, ...root.activeNotifs].slice(0, 5);
        }
    }

    // Nettoyage auto des notifs > 5s
    Timer {
        interval: 1000
        running: root.activeNotifs.length > 0
        repeat: true
        onTriggered: {
            const now = Date.now();
            const remaining = root.activeNotifs.filter(n => now - n.timestamp < 5000);
            if (remaining.length !== root.activeNotifs.length)
                root.activeNotifs = remaining;
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property ShellScreen modelData
            screen: modelData

            anchors.top: true
            anchors.left: true
            anchors.right: true

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "colony-bar"
            exclusiveZone: barHeight

            color: "#cc0d0d14"

            readonly property int barHeight: 44
            readonly property color accent: "#9b59b6"
            readonly property color accentLight: "#b57bee"
            readonly property color text1: "#cdd6f4"
            readonly property color text2: "#7f849c"
            readonly property color surface: "#1e1e2e"
            readonly property color surfaceLight: "#313244"

            implicitHeight: barHeight

            // Fermer les popups au clic ou hover sur la barre (hors boutons)
            MouseArea {
                anchors.fill: parent
                z: -1
                hoverEnabled: true
                onClicked: root.closeAllPopups()
                onPositionChanged: event => {
                    // Dashboard : hover au centre de la barre
                    const centerZone = event.x > parent.width * 0.3 && event.x < parent.width * 0.7;
                    if (centerZone && !root.dashboardVisible && !root.powerMenuVisible && !root.calendarVisible && !root.volumePopupVisible) {
                        root.dashboardVisible = true;
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                // ── Logo ──
                Item {
                    Layout.preferredWidth: 32
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: bar.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("exec rofi -show drun")
                    }
                }

                // ── Workspaces ──
                Rectangle {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: wsRow.implicitWidth + 12
                    Layout.alignment: Qt.AlignVCenter
                    radius: 1000
                    color: bar.surfaceLight

                    Row {
                        id: wsRow
                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: 5

                            Rectangle {
                                id: wsBtn
                                required property int index
                                readonly property int ws: index + 1
                                readonly property bool active: root.activeWsId === ws

                                width: active ? 28 : 20
                                height: active ? 28 : 20
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 1000
                                color: active ? bar.accent : "transparent"
                                border.width: active ? 0 : 1
                                border.color: bar.text2

                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: wsBtn.ws
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    color: wsBtn.active ? "#0d0d14" : bar.text2
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Hyprland.dispatch(`workspace ${wsBtn.ws}`)
                                }
                            }
                        }
                    }
                }

                // ── Active Window ──
                RowLayout {
                    Layout.fillHeight: true
                    spacing: 6

                    Text {
                        text: "󰣆"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: bar.accentLight
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: {
                            const title = root.activeTitle;
                            if (title === "Desktop") return title;
                            const parts = title.split(/\s+[\-\u2013\u2014]\s+/);
                            return parts.length > 1 ? parts[parts.length - 1].trim() : title;
                        }
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: bar.text2
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                        Layout.maximumWidth: 300
                    }
                }

                // ── Spacer ──
                Item { Layout.fillWidth: true }

                // ── Tray ──
                RowLayout {
                    Layout.fillHeight: true
                    spacing: 2

                    Repeater {
                        model: ScriptModel {
                            values: SystemTray.items.values
                        }

                        Item {
                            id: trayItem
                            required property SystemTrayItem modelData

                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                anchors.centerIn: parent
                                width: 18; height: 18
                                source: trayItem.modelData.icon
                                sourceSize.width: 18
                                sourceSize.height: 18
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: event => {
                                    root.closeNonTrayPopups();
                                    if (event.button === Qt.LeftButton) {
                                        root.trayMenuVisible = false;
                                        trayItem.modelData.activate();
                                    } else if (event.button === Qt.RightButton) {
                                        // Ouvrir le menu tray
                                        root.trayMenuTarget = trayItem.modelData;
                                        root.trayMenuX = trayItem.mapToItem(null, trayItem.width / 2, 0).x;
                                        root.trayMenuVisible = true;
                                    } else {
                                        trayItem.modelData.secondaryActivate();
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Volume ──
                Rectangle {
                    id: volBtn
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: volRow.implicitWidth + 16
                    Layout.alignment: Qt.AlignVCenter
                    radius: 1000
                    color: bar.surfaceLight

                    Row {
                        id: volRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                const vol = root.audioVolume;
                                const muted = root.audioMuted;
                                if (muted) return "󰖁";
                                if (vol > 0.66) return "󰕾";
                                if (vol > 0.33) return "󰖀";
                                return "󰕿";
                            }
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            color: bar.text1
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round((root.audioVolume) * 100) + "%"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: bar.text1
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onWheel: event => {
                            if (event.angleDelta.y > 0)
                                root.setVolume(root.audioVolume + 0.05);
                            else
                                root.setVolume(root.audioVolume - 0.05);
                        }
                        onClicked: {
                            const wasOpen = root.volumePopupVisible;
                            root.closeAllPopups();
                            root.volumeX = volBtn.mapToItem(null, volBtn.width / 2, 0).x;
                            root.volumePopupVisible = !wasOpen;
                        }
                    }
                }

                // ── Horloge ──
                Rectangle {
                    id: clockBtn
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: clockRow.implicitWidth + 20
                    Layout.alignment: Qt.AlignVCenter
                    radius: 1000
                    color: bar.surfaceLight

                    Row {
                        id: clockRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰃭"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: bar.accentLight
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Qt.formatDateTime(clock.date, "ddd d")
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: bar.text2
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1; height: 16
                            color: bar.text2; opacity: 0.3
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Qt.formatDateTime(clock.date, "hh:mm")
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.bold: true
                            color: bar.text1
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const wasOpen = root.calendarVisible;
                            root.closeAllPopups();
                            root.clockX = clockBtn.mapToItem(null, clockBtn.width / 2, 0).x;
                            root.calendarVisible = !wasOpen;
                        }
                    }
                }

                // ── Power ──
                Item {
                    Layout.preferredWidth: 32
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: "⏻"
                        font.pixelSize: 16
                        color: root.powerMenuVisible ? bar.accent : bar.text2

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const wasOpen = root.powerMenuVisible;
                            root.closeAllPopups();
                            root.powerMenuVisible = !wasOpen;
                            // Power menu reste en bas à droite
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════
    //          POWER MENU (fenêtre séparée)
    // ═══════════════════════════════════
    property bool powerMenuVisible: false
    property bool calendarVisible: false
    property bool volumePopupVisible: false
    property bool trayMenuVisible: false
    property bool dashboardVisible: false
    property var trayMenuTarget: null
    property real trayMenuX: 0
    property real clockX: 0
    property real volumeX: 0
    property real powerX: 0

    // Météo
    property string weatherTemp: "--"
    property string weatherDesc: "..."
    property string weatherCity: "Namur"
    property string weatherIcon: "☁"
    property string weatherHumidity: "--"
    property string weatherWind: "--"

    // Système
    property real cpuUsage: 0
    property real ramUsage: 0
    property real ramTotal: 0
    property real ramUsed: 0
    property string uptime: "--"

    // Fetch météo au démarrage
    Process {
        id: weatherProc
        command: ["curl", "-s", "wttr.in/Namur?format=%t|%C|%h|%w"]
        running: true
        onExited: (code, status) => {
            if (code === 0 && weatherProc.stdout) {
                const parts = weatherProc.stdout.split("|");
                if (parts.length >= 4) {
                    root.weatherTemp = parts[0].trim();
                    root.weatherDesc = parts[1].trim();
                    root.weatherHumidity = parts[2].trim();
                    root.weatherWind = parts[3].trim();
                    // Icône simple
                    const desc = parts[1].toLowerCase();
                    if (desc.includes("sun") || desc.includes("clear")) root.weatherIcon = "☀️";
                    else if (desc.includes("cloud")) root.weatherIcon = "☁️";
                    else if (desc.includes("rain") || desc.includes("drizzle")) root.weatherIcon = "🌧️";
                    else if (desc.includes("snow")) root.weatherIcon = "❄️";
                    else if (desc.includes("thunder") || desc.includes("storm")) root.weatherIcon = "⛈️";
                    else if (desc.includes("fog") || desc.includes("mist")) root.weatherIcon = "🌫️";
                    else root.weatherIcon = "🌤️";
                }
            }
        }
    }

    // Refresh météo toutes les 30min
    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }

    // Système : CPU + RAM + uptime
    Process {
        id: sysProc
        command: ["bash", "-c", "echo $(grep 'cpu ' /proc/stat | awk '{u=$2+$4; t=$2+$4+$5; printf \"%.0f\", u*100/t}')|$(free -m | awk '/Mem:/{printf \"%d|%d\", $3, $2}')|$(uptime -p | sed 's/up //')"]
        running: true
        onExited: (code, status) => {
            if (code === 0 && sysProc.stdout) {
                const parts = sysProc.stdout.trim().split("|");
                if (parts.length >= 4) {
                    root.cpuUsage = parseInt(parts[0]) / 100;
                    root.ramUsed = parseInt(parts[1]);
                    root.ramTotal = parseInt(parts[2]);
                    root.ramUsage = root.ramUsed / root.ramTotal;
                    root.uptime = parts[3].trim();
                }
            }
        }
    }

    // Refresh système toutes les 5s
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: sysProc.running = true
    }

    function closeAllPopups() {
        powerMenuVisible = false;
        calendarVisible = false;
        volumePopupVisible = false;
        trayMenuVisible = false;
        dashboardVisible = false;
    }

    function closeNonTrayPopups() {
        powerMenuVisible = false;
        calendarVisible = false;
        volumePopupVisible = false;
    }

    component PowerButton: Rectangle {
        id: pwrBtn
        property string icon
        property string label
        property color iconColor: "#cdd6f4"
        property var command: []

        width: 80; height: 80
        radius: 20
        color: pwrMa.containsMouse ? "#449b59b6" : "#22ffffff"
        scale: pwrMa.containsMouse ? 1.05 : 1.0

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: pwrBtn.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 26
                color: pwrBtn.iconColor
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: pwrBtn.label
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                color: "#7f849c"
            }
        }

        MouseArea {
            id: pwrMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Quickshell.execDetached(pwrBtn.command);
                root.powerMenuVisible = false;
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: powerMenu

            required property ShellScreen modelData
            screen: modelData

            anchors.right: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "colony-power-menu"
            WlrLayershell.margins.right: 12

            // Fermer quand la souris quitte le popup


            WlrLayershell.margins.top: (modelData.height - implicitHeight) / 2
            anchors.top: true

            color: "transparent"
            visible: root.powerMenuVisible


            implicitWidth: powerCol.width + 32
            implicitHeight: root.powerMenuVisible ? powerCol.height + 32 : 0

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutQuart
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: powerCol.height + 32
                radius: 24
                color: "#e01e1e2e"
                border.width: 1
                border.color: "#229b59b6"

                Column {
                    id: powerCol
                    anchors.centerIn: parent
                    spacing: 10

                    PowerButton {
                        icon: "󰍃"
                        label: "Logout"
                        command: ["loginctl", "terminate-user", ""]
                    }

                    PowerButton {
                        icon: "󰑐"
                        label: "Reboot"
                        command: ["systemctl", "reboot"]
                    }

                    PowerButton {
                        icon: "⏻"
                        label: "Éteindre"
                        iconColor: "#f38ba8"
                        command: ["systemctl", "poweroff"]
                    }

                    PowerButton {
                        icon: "󰒲"
                        label: "Veille"
                        command: ["systemctl", "suspend"]
                    }
                }
            }

            // Fermer le menu si on clique en dehors
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: root.powerMenuVisible = false
            }
        }
    }

    // ═══════════════════════════════════
    //          CALENDRIER POPUP
    // ═══════════════════════════════════
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: calendarPopup

            required property ShellScreen modelData
            screen: modelData

            anchors.top: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "colony-calendar"
            WlrLayershell.margins.top: 6
            WlrLayershell.margins.right: 50
            anchors.right: true



            color: "transparent"
            visible: root.calendarVisible


            implicitWidth: 280
            implicitHeight: root.calendarVisible ? calContent.height + 32 : 0


            Behavior on implicitHeight {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
            }

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: calContent.height + 32
                radius: 24
                color: "#e01e1e2e"
                border.width: 1
                border.color: "#229b59b6"

                Column {
                    id: calContent
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    spacing: 12

                    // Heure grande
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "hh:mm")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 48
                        font.bold: true
                        color: "#b57bee"
                    }

                    // Date complète
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "dddd d MMMM yyyy")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: "#7f849c"
                    }

                    // Séparateur
                    Rectangle {
                        width: 240
                        height: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#33ffffff"
                    }

                    // Grille calendrier
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2

                        // En-tête jours
                        Row {
                            spacing: 0
                            Repeater {
                                model: ["Lu", "Ma", "Me", "Je", "Ve", "Sa", "Di"]
                                Text {
                                    required property string modelData
                                    width: 34; height: 28
                                    text: modelData
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#9b59b6"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        // Jours du mois
                        Repeater {
                            id: weekRepeater
                            model: 6 // max 6 semaines

                            Row {
                                id: weekRow
                                required property int index
                                spacing: 0

                                readonly property int weekIdx: index
                                readonly property var monthStart: {
                                    const d = new Date(clock.date);
                                    d.setDate(1);
                                    return d;
                                }
                                // Lundi = 0 dans notre grille
                                readonly property int startDay: (monthStart.getDay() + 6) % 7
                                readonly property int daysInMonth: new Date(clock.date.getFullYear(), clock.date.getMonth() + 1, 0).getDate()

                                visible: {
                                    const firstDayOfWeek = weekIdx * 7 - startDay + 1;
                                    return firstDayOfWeek <= daysInMonth;
                                }

                                Repeater {
                                    model: 7

                                    Rectangle {
                                        required property int index
                                        readonly property int dayNum: weekRow.weekIdx * 7 + index - weekRow.startDay + 1
                                        readonly property bool isCurrentMonth: dayNum >= 1 && dayNum <= weekRow.daysInMonth
                                        readonly property bool isToday: isCurrentMonth && dayNum === clock.date.getDate()

                                        width: 34; height: 30
                                        radius: 1000
                                        color: isToday ? "#9b59b6" : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: parent.isCurrentMonth ? parent.dayNum : ""
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 12
                                            color: parent.isToday ? "#0d0d14" : "#cdd6f4"
                                            font.bold: parent.isToday
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: root.calendarVisible = false
            }
        }
    }

    // ═══════════════════════════════════
    //          VOLUME POPUP
    // ═══════════════════════════════════
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: volumePopup

            required property ShellScreen modelData
            screen: modelData

            anchors.top: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "colony-volume"
            WlrLayershell.margins.top: 6
            WlrLayershell.margins.right: 140
            anchors.right: true



            color: "transparent"
            visible: root.volumePopupVisible


            implicitWidth: 260
            implicitHeight: root.volumePopupVisible ? volContent.height + 32 : 0


            Behavior on implicitHeight {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
            }

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: volContent.height + 32
                radius: 24
                color: "#e01e1e2e"
                border.width: 1
                border.color: "#229b59b6"

                Column {
                    id: volContent
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    width: 228
                    spacing: 16

                    // Titre + icône
                    Row {
                        spacing: 10

                        Text {
                            text: {
                                if (root.audioMuted) return "󰖁";
                                return "󰕾";
                            }
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            color: "#b57bee"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Volume"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            font.bold: true
                            color: "#cdd6f4"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item { width: 1; height: 1 } // spacer

                        Text {
                            text: Math.round((root.audioVolume) * 100) + "%"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#9b59b6"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Slider volume
                    Item {
                        width: parent.width
                        height: 32

                        // Track background
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 8
                            radius: 4
                            color: "#33ffffff"

                            // Track fill
                            Rectangle {
                                width: parent.width * (root.audioVolume)
                                height: parent.height
                                radius: 4
                                color: "#9b59b6"

                                Behavior on width { NumberAnimation { duration: 100 } }
                            }
                        }

                        // Handle
                        Rectangle {
                            x: parent.width * (root.audioVolume) - 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16
                            radius: 8
                            color: "#b57bee"

                            Behavior on x { NumberAnimation { duration: 100 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onPressed: event => {
                                root.setVolume(event.x / width);
                            }
                            onPositionChanged: event => {
                                if (pressed)
                                    root.setVolume(event.x / width);
                            }
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // Bouton mute
                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: 12
                        color: muteMa.containsMouse ? "#339b59b6" : "#22ffffff"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: (root.audioMuted) ? "🔈 Unmute" : "🔇 Mute"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: "#cdd6f4"
                        }

                        MouseArea {
                            id: muteMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.toggleMute();
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: root.volumePopupVisible = false
            }
        }
    }

    // ═══════════════════════════════════
    //          NOTIFICATIONS
    // ═══════════════════════════════════
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: notifWindow

            required property ShellScreen modelData
            screen: modelData

            anchors.top: true
            anchors.right: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "colony-notifications"
            WlrLayershell.margins.top: 6
            WlrLayershell.margins.right: 12

            color: "transparent"
            visible: root.activeNotifs.length > 0

            implicitWidth: 340
            implicitHeight: notifCol.implicitHeight + 4

            Column {
                id: notifCol
                anchors.top: parent.top
                anchors.right: parent.right
                width: 340
                spacing: 4

                Repeater {
                    model: root.activeNotifs

                    Rectangle {
                        id: notifCard
                        required property var modelData
                        required property int index

                        width: 340
                        height: notifInner.implicitHeight + 24
                        radius: 16
                        color: "#e01e1e2e"
                        border.width: 1
                        border.color: modelData.urgency === 2 ? "#44f38ba8" : "#229b59b6"

                        // Animation d'entrée
                        x: 0
                        opacity: 1
                        Component.onCompleted: {
                            x = 0;
                            opacity = 1;
                        }

                        // Swipe pour fermer
                        MouseArea {
                            anchors.fill: parent
                            property real startX: 0

                            onPressed: event => startX = event.x
                            onPositionChanged: event => {
                                if (pressed) {
                                    const diff = event.x - startX;
                                    if (diff > 0) notifCard.x = diff;
                                }
                            }
                            onReleased: {
                                if (notifCard.x > 100) {
                                    // Dismiss
                                    root.activeNotifs = root.activeNotifs.filter((_, i) => i !== notifCard.index);
                                } else {
                                    notifCard.x = 0;
                                }
                            }
                        }

                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

                        Row {
                            id: notifInner
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 10

                            // Icône / Avatar
                            Rectangle {
                                width: 40; height: 40
                                radius: notifCard.modelData.image.length > 0 ? 20 : 12
                                color: notifCard.modelData.urgency === 2 ? "#33f38ba8" : "#339b59b6"
                                anchors.verticalCenter: parent.verticalCenter
                                clip: true

                                // Avatar (image de la notif, ex: photo de profil Discord)
                                Image {
                                    anchors.fill: parent
                                    source: notifCard.modelData.image
                                    visible: notifCard.modelData.image.length > 0
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: 40
                                    sourceSize.height: 40
                                }

                                // Icône app (si pas d'image)
                                Image {
                                    anchors.centerIn: parent
                                    width: 24; height: 24
                                    source: notifCard.modelData.appIcon ? Quickshell.iconPath(notifCard.modelData.appIcon) : ""
                                    visible: notifCard.modelData.image.length === 0 && notifCard.modelData.appIcon.length > 0
                                    sourceSize.width: 24
                                    sourceSize.height: 24
                                }

                                // Fallback emoji
                                Text {
                                    anchors.centerIn: parent
                                    text: notifCard.modelData.urgency === 2 ? "⚠" : "🔔"
                                    font.pixelSize: 18
                                    visible: notifCard.modelData.image.length === 0 && notifCard.modelData.appIcon.length === 0
                                }
                            }

                            // Contenu
                            Column {
                                width: parent.width - 62
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                // App name
                                Text {
                                    text: notifCard.modelData.appName || "Notification"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    color: "#9b59b6"
                                    font.bold: true
                                }

                                // Titre
                                Text {
                                    text: notifCard.modelData.summary || ""
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: "#cdd6f4"
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                // Body
                                Text {
                                    text: notifCard.modelData.body || ""
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    color: "#7f849c"
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    visible: text.length > 0
                                }
                            }

                            // Bouton fermer
                            Text {
                                text: "✕"
                                font.pixelSize: 14
                                color: "#7f849c"
                                anchors.top: parent.top

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.activeNotifs = root.activeNotifs.filter((_, i) => i !== notifCard.index);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ═══════════════════════════════════
    //          TRAY MENU POPUP
    // ═══════════════════════════════════
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: trayMenuWindow

            required property ShellScreen modelData
            screen: modelData

            anchors.top: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "colony-tray-menu"
            WlrLayershell.margins.top: 6
            WlrLayershell.margins.left: Math.max(0, root.trayMenuX - 100)
            anchors.left: true

            color: "transparent"
            visible: root.trayMenuVisible && root.trayMenuTarget !== null


            implicitWidth: 220
            implicitHeight: root.trayMenuVisible ? trayMenuCol.implicitHeight + 20 : 0


            Behavior on implicitHeight {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuart }
            }



            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: trayMenuCol.implicitHeight + 20
                radius: 16
                color: "#e01e1e2e"
                border.width: 1
                border.color: "#229b59b6"

                Column {
                    id: trayMenuCol
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    width: 200
                    spacing: 2

                    // Titre du tray item
                    Text {
                        text: root.trayMenuTarget?.title ?? ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#9b59b6"
                        width: parent.width
                        elide: Text.ElideRight
                        bottomPadding: 4
                    }

                    Rectangle {
                        width: parent.width; height: 1
                        color: "#22ffffff"
                    }

                    // Entrées du menu
                    Repeater {
                        model: {
                            if (!root.trayMenuTarget?.menu) return [];
                            const opener = trayMenuOpener;
                            return opener.children ?? [];
                        }

                        Rectangle {
                            required property var modelData
                            width: 200; height: modelData.isSeparator ? 1 : 36
                            radius: 10
                            color: modelData.isSeparator ? "#22ffffff" : trayEntryMa.containsMouse ? "#339b59b6" : "transparent"
                            visible: true

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                text: modelData.text ?? ""
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: modelData.enabled !== false ? "#cdd6f4" : "#585b70"
                                visible: !modelData.isSeparator
                            }

                            MouseArea {
                                id: trayEntryMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: modelData.isSeparator ? undefined : Qt.PointingHandCursor
                                enabled: !modelData.isSeparator && modelData.enabled !== false
                                onClicked: {
                                    modelData.triggered();
                                    root.trayMenuVisible = false;
                                }
                            }
                        }
                    }
                }
            }

            QsMenuOpener {
                id: trayMenuOpener
                menu: root.trayMenuTarget?.menu ?? null
            }
        }
    }

    // ═══════════════════════════════════
    //          DASHBOARD (4 onglets)
    // ═══════════════════════════════════
    property int dashTab: 0 // 0=Dashboard, 1=Media, 2=Performance, 3=Weather

    // Media (MPRIS natif)
    readonly property MprisPlayer activePlayer: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string mediaTitle: activePlayer?.trackTitle ?? "Aucune musique"
    readonly property string mediaArtist: activePlayer?.trackArtist ?? ""
    readonly property string mediaAlbum: activePlayer?.trackAlbum ?? ""
    readonly property string mediaArtUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool mediaPlaying: activePlayer?.isPlaying ?? false
    readonly property real mediaLength: activePlayer?.length ?? 0
    readonly property real mediaPosition: activePlayer?.position ?? 0

    function mediaLengthStr(secs) {
        if (secs <= 0) return "0:00";
        const m = Math.floor(secs / 60);
        const s = Math.floor(secs % 60).toString().padStart(2, "0");
        return m + ":" + s;
    }

    // Refresh position
    Timer {
        interval: 1000
        running: root.mediaPlaying
        repeat: true
        onTriggered: { if (root.activePlayer) root.activePlayer.positionChanged() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dashWindow

            required property ShellScreen modelData
            screen: modelData

            anchors.top: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "colony-dashboard"
            WlrLayershell.margins.top: 6
            exclusiveZone: 0

            color: "transparent"
            visible: root.dashboardVisible


            implicitWidth: 700
            implicitHeight: root.dashboardVisible ? 340 : 0


            Behavior on implicitHeight {
                NumberAnimation { duration: 400; easing.type: Easing.OutQuart }
            }



            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: 700; height: 340
                radius: 24
                color: "#e01e1e2e"
                border.width: 1
                border.color: "#229b59b6"

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // ── ONGLETS ──
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4

                        Repeater {
                            model: ["Dashboard", "Media", "Performance", "Météo"]

                            Rectangle {
                                required property string modelData
                                required property int index

                                width: tabText.implicitWidth + 24
                                height: 30
                                radius: 1000
                                color: root.dashTab === index ? "#9b59b6" : tabMa.containsMouse ? "#339b59b6" : "#22ffffff"

                                Behavior on color { ColorAnimation { duration: 200 } }

                                Text {
                                    id: tabText
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    font.bold: root.dashTab === index
                                    color: root.dashTab === index ? "#0d0d14" : "#cdd6f4"
                                }

                                MouseArea {
                                    id: tabMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.dashTab = index
                                }
                            }
                        }
                    }

                    // ── CONTENU ──
                    Item {
                        width: parent.width
                        height: parent.height - 46

                        // === TAB 0 : DASHBOARD ===
                        Row {
                            anchors.fill: parent
                            spacing: 12
                            visible: root.dashTab === 0

                            // Météo mini
                            Rectangle {
                                width: (parent.width - 24) / 3; height: parent.height
                                radius: 20; color: "#22ffffff"
                                Column {
                                    anchors.centerIn: parent; spacing: 8
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.weatherIcon; font.pixelSize: 40 }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.weatherTemp; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 28; font.bold: true; color: "#cdd6f4" }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.weatherDesc; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; color: "#7f849c" }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.weatherCity; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: "#9b59b6"; font.bold: true }
                                }
                            }

                            // Horloge + calendrier
                            Rectangle {
                                width: (parent.width - 24) / 3; height: parent.height
                                radius: 20; color: "#22ffffff"
                                Column {
                                    anchors.centerIn: parent; spacing: 4
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(clock.date, "hh:mm"); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 36; font.bold: true; color: "#b57bee" }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(clock.date, "dddd d MMMM"); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: "#7f849c" }
                                    Item { width: 1; height: 4 }
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter; spacing: 0
                                        Repeater { model: ["L","M","M","J","V","S","D"]
                                            Text { required property string modelData; width: 26; height: 16; text: modelData; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.bold: true; color: "#9b59b6"; horizontalAlignment: Text.AlignHCenter }
                                        }
                                    }
                                    Repeater {
                                        model: 6
                                        Row {
                                            required property int index; readonly property int wi: index
                                            readonly property var ms: { const d = new Date(clock.date); d.setDate(1); return d; }
                                            readonly property int sd: (ms.getDay() + 6) % 7
                                            readonly property int dm: new Date(clock.date.getFullYear(), clock.date.getMonth() + 1, 0).getDate()
                                            visible: wi * 7 - sd + 1 <= dm; anchors.horizontalCenter: parent.horizontalCenter; spacing: 0
                                            Repeater { model: 7
                                                Rectangle {
                                                    required property int index; readonly property int dn: parent.wi * 7 + index - parent.sd + 1
                                                    readonly property bool ok: dn >= 1 && dn <= parent.dm; readonly property bool td: ok && dn === clock.date.getDate()
                                                    width: 26; height: 16; radius: 8; color: td ? "#9b59b6" : "transparent"
                                                    Text { anchors.centerIn: parent; text: parent.ok ? parent.dn : ""; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; color: parent.td ? "#0d0d14" : "#cdd6f4"; font.bold: parent.td }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Système mini
                            Rectangle {
                                width: (parent.width - 24) / 3; height: parent.height
                                radius: 20; color: "#22ffffff"
                                Column {
                                    anchors.centerIn: parent; spacing: 14; width: 160
                                    Column { width: 160; spacing: 4
                                        Row { width: parent.width; Text { text: "CPU"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: "#cdd6f4" }
                                        Item { width: 80; height: 1 }
                                        Text { text: Math.round(root.cpuUsage * 100) + "%"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: "#9b59b6"; font.bold: true } }
                                        Rectangle { width: 160; height: 6; radius: 3; color: "#33ffffff"; Rectangle { width: parent.width * root.cpuUsage; height: 6; radius: 3; color: root.cpuUsage > 0.8 ? "#f38ba8" : "#9b59b6"; Behavior on width { NumberAnimation { duration: 500 } } } }
                                    }
                                    Column { width: 160; spacing: 4
                                        Row { width: parent.width; Text { text: "RAM"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: "#cdd6f4" }
                                        Item { width: 60; height: 1 }
                                        Text { text: Math.round(root.ramUsed/1024*10)/10 + "/" + Math.round(root.ramTotal/1024) + "G"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; color: "#9b59b6"; font.bold: true } }
                                        Rectangle { width: 160; height: 6; radius: 3; color: "#33ffffff"; Rectangle { width: parent.width * root.ramUsage; height: 6; radius: 3; color: root.ramUsage > 0.8 ? "#f38ba8" : "#b57bee"; Behavior on width { NumberAnimation { duration: 500 } } } }
                                    }
                                    Row { spacing: 6; Text { text: "⏱"; font.pixelSize: 14 }
                                        Text { text: root.uptime; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: "#7f849c" } }
                                }
                            }
                        }

                        // === TAB 1 : MEDIA ===
                        Row {
                            anchors.fill: parent
                            spacing: 16
                            visible: root.dashTab === 1

                            // Cover art
                            Rectangle {
                                width: parent.height
                                height: parent.height
                                radius: 20
                                color: "#339b59b6"
                                clip: true

                                Text {
                                    anchors.centerIn: parent
                                    text: "🎵"
                                    font.pixelSize: 48
                                    visible: !coverImg.visible
                                }

                                Image {
                                    id: coverImg
                                    anchors.fill: parent
                                    source: root.mediaArtUrl
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                    asynchronous: true
                                    sourceSize.width: parent.width
                                    sourceSize.height: parent.height
                                }
                            }

                            // Détails + contrôles
                            Column {
                                width: parent.width - parent.height - 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                // Titre
                                Text {
                                    text: root.mediaTitle
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#cdd6f4"
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                // Artiste
                                Text {
                                    text: root.mediaArtist
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: "#9b59b6"
                                    visible: text.length > 0
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                // Album
                                Text {
                                    text: root.mediaAlbum
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    color: "#7f849c"
                                    visible: text.length > 0
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                // Barre de progression
                                Item {
                                    width: parent.width
                                    height: 20
                                    visible: root.mediaLength > 0

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        height: 4
                                        radius: 2
                                        color: "#33ffffff"

                                        Rectangle {
                                            width: root.mediaLength > 0 ? parent.width * (root.mediaPosition / root.mediaLength) : 0
                                            height: parent.height
                                            radius: 2
                                            color: "#9b59b6"
                                            Behavior on width { NumberAnimation { duration: 1000 } }
                                        }
                                    }
                                }

                                // Temps
                                Row {
                                    width: parent.width
                                    visible: root.mediaLength > 0

                                    Text {
                                        text: root.mediaLengthStr(root.mediaPosition)
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: "#7f849c"
                                    }
                                    Item { width: parent.width - 80; height: 1 }
                                    Text {
                                        text: root.mediaLengthStr(root.mediaLength)
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        color: "#7f849c"
                                    }
                                }

                                // Contrôles
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 16

                                    Rectangle {
                                        width: 40; height: 40; radius: 20
                                        color: prevMa.containsMouse ? "#339b59b6" : "#22ffffff"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text { anchors.centerIn: parent; text: "⏮"; font.pixelSize: 18; color: "#cdd6f4" }
                                        MouseArea {
                                            id: prevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { if (root.activePlayer) root.activePlayer.previous() }
                                        }
                                    }

                                    Rectangle {
                                        width: 52; height: 52; radius: 26
                                        color: playMa.containsMouse ? "#9b59b6" : "#b57bee"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text { anchors.centerIn: parent; text: root.mediaPlaying ? "⏸" : "▶"; font.pixelSize: 22; color: "#0d0d14" }
                                        MouseArea {
                                            id: playMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { if (root.activePlayer) root.activePlayer.togglePlaying() }
                                        }
                                    }

                                    Rectangle {
                                        width: 40; height: 40; radius: 20
                                        color: nextMa.containsMouse ? "#339b59b6" : "#22ffffff"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text { anchors.centerIn: parent; text: "⏭"; font.pixelSize: 18; color: "#cdd6f4" }
                                        MouseArea {
                                            id: nextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { if (root.activePlayer) root.activePlayer.next() }
                                        }
                                    }
                                }

                                // Nom du player
                                Text {
                                    text: root.activePlayer?.identity ?? ""
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    color: "#585b70"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // === TAB 2 : PERFORMANCE ===
                        Row {
                            anchors.fill: parent
                            spacing: 12
                            visible: root.dashTab === 2

                            // CPU détaillé
                            Rectangle {
                                width: (parent.width - 12) / 2; height: parent.height
                                radius: 20; color: "#22ffffff"
                                Column {
                                    anchors.centerIn: parent; spacing: 10; width: parent.width - 40
                                    Text { text: "CPU"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; font.bold: true; color: "#b57bee" }
                                    Text { text: Math.round(root.cpuUsage * 100) + "%"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 48; font.bold: true; color: "#cdd6f4" }
                                    Rectangle { width: parent.width; height: 10; radius: 5; color: "#33ffffff"; Rectangle { width: parent.width * root.cpuUsage; height: 10; radius: 5; color: root.cpuUsage > 0.8 ? "#f38ba8" : "#9b59b6"; Behavior on width { NumberAnimation { duration: 500 } } } }
                                }
                            }

                            // RAM détaillé
                            Rectangle {
                                width: (parent.width - 12) / 2; height: parent.height
                                radius: 20; color: "#22ffffff"
                                Column {
                                    anchors.centerIn: parent; spacing: 10; width: parent.width - 40
                                    Text { text: "RAM"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; font.bold: true; color: "#b57bee" }
                                    Text { text: Math.round(root.ramUsed / 1024 * 10) / 10 + " GB"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 48; font.bold: true; color: "#cdd6f4" }
                                    Rectangle { width: parent.width; height: 10; radius: 5; color: "#33ffffff"; Rectangle { width: parent.width * root.ramUsage; height: 10; radius: 5; color: root.ramUsage > 0.8 ? "#f38ba8" : "#b57bee"; Behavior on width { NumberAnimation { duration: 500 } } } }
                                    Text { text: Math.round(root.ramUsed/1024*10)/10 + " / " + Math.round(root.ramTotal/1024) + " GB utilisés"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: "#7f849c" }
                                    Row { spacing: 6; Text { text: "Uptime :"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: "#7f849c" }
                                        Text { text: root.uptime; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; color: "#9b59b6"; font.bold: true } }
                                }
                            }
                        }

                        // === TAB 3 : MÉTÉO ===
                        Rectangle {
                            anchors.fill: parent
                            radius: 20; color: "#22ffffff"
                            visible: root.dashTab === 3

                            Row {
                                anchors.centerIn: parent; spacing: 40

                                // Gauche : icône + temp
                                Column {
                                    spacing: 8
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.weatherIcon; font.pixelSize: 64 }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.weatherTemp; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 48; font.bold: true; color: "#cdd6f4" }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.weatherDesc; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: "#7f849c" }
                                }

                                // Droite : détails
                                Column {
                                    spacing: 16; anchors.verticalCenter: parent.verticalCenter
                                    Text { text: root.weatherCity; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; font.bold: true; color: "#9b59b6" }
                                    Row { spacing: 8; Text { text: "💧"; font.pixelSize: 16 }
                                        Text { text: "Humidité : " + root.weatherHumidity; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#cdd6f4" } }
                                    Row { spacing: 8; Text { text: "🌬️"; font.pixelSize: 16 }
                                        Text { text: "Vent : " + root.weatherWind; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#cdd6f4" } }
                                    Row { spacing: 8; Text { text: "📅"; font.pixelSize: 16 }
                                        Text { text: Qt.formatDateTime(clock.date, "dddd d MMMM yyyy"); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#cdd6f4" } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
