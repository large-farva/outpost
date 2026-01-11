/*
    SPDX-FileCopyrightText: 2014 Marco Martin <mart@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kirigami 2 as Kirigami

Rectangle {
    id: root
    color: "black"

    property int stage

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Image {
            id: logo
            readonly property real size: Kirigami.Units.gridUnit * 8

            anchors.centerIn: parent
            asynchronous: true
            source: "images/outpost_logo.svgz"

            sourceSize.width: size
            sourceSize.height: size
        }
    }

    onStageChanged: {
        if (stage == 2) {
            introAnimation.running = true;
        } else if (stage == 5) {
            introAnimation.target = content;
            introAnimation.from = 1;
            introAnimation.to = 0;
            introAnimation.running = true;
        }
    }

    OpacityAnimator {
        id: introAnimation
        running: false
        target: content
        from: 0
        to: 1
        duration: Kirigami.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }
}
