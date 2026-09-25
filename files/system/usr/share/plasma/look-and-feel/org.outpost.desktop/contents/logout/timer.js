/*
    SPDX-FileCopyrightText: 2018 David Edmundson <davidedmundson@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

.pragma library

// Shared key state lets a keypress in any view cancel every logout timer.

var callbacks = [];

function addCancelAutoTriggerCallback(callback) {
    callbacks.push(callback);
}

function cancelAutoTrigger() {
    callbacks.forEach(function (c) {
        if (!c) {
            return;
        }
        c();
    });
}

