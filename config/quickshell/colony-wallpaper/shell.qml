import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ShellRoot {
    id: root
    
    // Configuration
    property string wallpaperDir: "/home/mothersphere/.config/wallpapers"
    property var wallpapers: []
    property int currentIndex: 0
    property bool pickerVisible: false
    
    // Zone de trigger en bas de l'écran
    PanelWindow {
        id: triggerZone
        
        screen: Quickshell.screens[0]
        anchors {
            bottom: true
            left: true
            right: true
        }
        
        implicitHeight: 20
        color: "transparent"
        
        exclusiveZone: 0
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            
            // Zone centrale seulement (400px au centre)
            property bool inCenterZone: {
                let centerX = width / 2
                let zoneWidth = 400
                return mouseX >= centerX - zoneWidth/2 && mouseX <= centerX + zoneWidth/2
            }
            
            onContainsMouseChanged: {
                if (containsMouse && inCenterZone) {
                    root.pickerVisible = true
                }
            }
        }
    }
    
    // Le picker de wallpaper
    PanelWindow {
        id: pickerWindow
        
        visible: root.pickerVisible
        
        screen: Quickshell.screens[0]
        
        // Position centrée manuellement
        anchors.bottom: true
        margins.bottom: 30
        
        // Centrer horizontalement : (largeur écran - largeur widget) / 2
        margins.left: (Quickshell.screens[0].width - 500) / 2
        
        implicitWidth: 500
        implicitHeight: 160
        
        color: "transparent"
        exclusiveZone: 0
        
        // Fermer quand la souris quitte la FENÊTRE (pas les enfants)
        // On utilise un HoverHandler à la place
        HoverHandler {
            id: pickerHover
            onHoveredChanged: {
                if (!hovered) {
                    hideTimer.start()
                } else {
                    hideTimer.stop()
                }
            }
        }
        
        Timer {
            id: hideTimer
            interval: 400
            onTriggered: root.pickerVisible = false
        }
        
        // Contenu du picker - Style glassmorphism moderne
        Rectangle {
            id: pickerBg
            anchors.fill: parent
            anchors.margins: 8
            
            color: "#cc0a0a12"
            radius: 20
            border.color: Qt.rgba(155/255, 89/255, 182/255, 0.4)
            border.width: 1
            
            // Effet de glow subtil
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: 21
                color: "transparent"
                border.color: Qt.rgba(181/255, 123/255, 238/255, 0.15)
                border.width: 2
                z: -1
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 16
                
                // Preview à GAUCHE - carré/rectangle
                Rectangle {
                    Layout.preferredWidth: 180
                    Layout.fillHeight: true
                    
                    color: "#1a1a2e"
                    radius: 12
                    border.color: Qt.rgba(155/255, 89/255, 182/255, 0.5)
                    border.width: 2
                    
                    clip: true
                    
                    Image {
                        id: previewImage
                        anchors.fill: parent
                        anchors.margins: 3
                        source: root.wallpapers.length > 0 ? "file://" + root.wallpapers[root.currentIndex] : ""
                        fillMode: Image.PreserveAspectCrop
                    }
                    
                    // Nom en overlay
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 24
                        color: "#cc0a0a12"
                        
                        Text {
                            anchors.centerIn: parent
                            text: root.wallpapers.length > 0 ? root.wallpapers[root.currentIndex].split('/').pop().replace('.png', '') : "Aucun"
                            color: "#cdd6f4"
                            font.pixelSize: 10
                            elide: Text.ElideMiddle
                        }
                    }
                }
                
                // Contrôles à DROITE - centrés verticalement
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 10
                    
                    // Titre
                    Text {
                        text: "Wallpapers"
                        color: "#b57bee"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    // Flèches horizontales
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16
                        
                        // Flèche gauche
                        Rectangle {
                            width: 44
                            height: 44
                            radius: 22
                            color: navLeftMouse.containsMouse ? Qt.rgba(155/255, 89/255, 182/255, 0.4) : Qt.rgba(255, 255, 255, 0.08)
                            border.color: navLeftMouse.containsMouse ? "#b57bee" : Qt.rgba(255, 255, 255, 0.15)
                            border.width: 1
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "❮"
                                color: navLeftMouse.containsMouse ? "#fff" : "#b57bee"
                                font.pixelSize: 16
                                font.bold: true
                            }
                            
                            MouseArea {
                                id: navLeftMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.wallpapers.length > 0) {
                                        root.currentIndex = (root.currentIndex - 1 + root.wallpapers.length) % root.wallpapers.length
                                        applyWallpaper()
                                    }
                                }
                            }
                        }
                        
                        // Compteur
                        Text {
                            text: root.wallpapers.length > 0 ? (root.currentIndex + 1) + "/" + root.wallpapers.length : "-"
                            color: "#7f849c"
                            font.pixelSize: 13
                        }
                        
                        // Flèche droite
                        Rectangle {
                            width: 44
                            height: 44
                            radius: 22
                            color: navRightMouse.containsMouse ? Qt.rgba(155/255, 89/255, 182/255, 0.4) : Qt.rgba(255, 255, 255, 0.08)
                            border.color: navRightMouse.containsMouse ? "#b57bee" : Qt.rgba(255, 255, 255, 0.15)
                            border.width: 1
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "❯"
                                color: navRightMouse.containsMouse ? "#fff" : "#b57bee"
                                font.pixelSize: 16
                                font.bold: true
                            }
                            
                            MouseArea {
                                id: navRightMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.wallpapers.length > 0) {
                                        root.currentIndex = (root.currentIndex + 1) % root.wallpapers.length
                                        applyWallpaper()
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
        }
        
        // Animation d'entrée
        Behavior on visible {
            enabled: true
            PropertyAnimation {
                target: pickerWindow
                property: "opacity"
                from: 0
                to: 1
                duration: 200
            }
        }
    }
    
    // Charger les wallpapers au démarrage
    Process {
        id: listProcess
        command: ["bash", "-c", "ls -1 " + root.wallpaperDir + "/*.png 2>/dev/null"]
        running: true
        
        stdout: SplitParser {
            onRead: data => {
                if (data.trim()) {
                    root.wallpapers = root.wallpapers.concat([data.trim()])
                }
            }
        }
    }
    
    // Appliquer le wallpaper
    function applyWallpaper() {
        if (wallpapers.length > 0) {
            applyProcess.command = ["awww", "img", wallpapers[currentIndex], "--transition-type", "wipe", "--transition-duration", "1"]
            applyProcess.running = true
        }
    }
    
    Process {
        id: applyProcess
        running: false
    }
}
