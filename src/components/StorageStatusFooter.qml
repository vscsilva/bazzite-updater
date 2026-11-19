// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    implicitHeight: Kirigami.Units.gridUnit * 3

    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Kirigami.Theme.disabledTextColor
        }
    }

    RowLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.largeSpacing * 2, Kirigami.Units.gridUnit * 48)
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.preferredWidth: Math.min(implicitWidth, parent.width * 0.55)
            Layout.minimumWidth: 0
            text: i18nc("progress bar displaying used storage space vs total available space", "System disk space used — %1", "%1%".arg(Math.floor(AppData.storageSpace.used * 100 / Math.max(1, AppData.storageSpace.total))))
            elide: Text.ElideRight
        }

        QQC2.ProgressBar {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.35
            Layout.minimumWidth: Kirigami.Units.gridUnit * 4
            Layout.maximumWidth: Math.min(parent.width * 0.45, Kirigami.Units.gridUnit * 24)
            from: 0
            to: AppData.storageSpace.total
            value: AppData.storageSpace.used
        }
    }
}
