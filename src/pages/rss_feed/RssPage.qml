// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

import QtQml.XmlListModel

AppPage {
    id: page

    topPadding: Kirigami.Units.largeSpacing * 2

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("Announcements")
    footer: QQC2.ToolBar {
        contentItem: RowLayout {
            spacing: Kirigami.Units.mediumSpacing

            QQC2.Label {
                Layout.fillWidth: true
                Layout.maximumWidth: Kirigami.Units.gridUnit * 24
                text: page.width < Kirigami.Units.gridUnit * 48
                    ? i18nc("compact storage usage indicator", "Disk: %1", "%1%".arg(Math.floor(AppData.storageSpace.used * 100 / Math.max(1, AppData.storageSpace.total))))
                    : i18nc("progress bar displaying used storage space vs total available space", "System disk space used — %1", "%1%".arg(Math.floor(AppData.storageSpace.used * 100 / Math.max(1, AppData.storageSpace.total))))
                elide: Text.ElideRight
            }

            QQC2.ProgressBar {
                Layout.preferredWidth: Math.min(page.width * 0.3, Kirigami.Units.gridUnit * 24)
                Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                Layout.maximumWidth: Kirigami.Units.gridUnit * 24
                from: 0
                to: AppData.storageSpace.total
                value: AppData.storageSpace.used
            }
        }
    }

    GP.PageNavigation {
        targetScrollbar: page.scrollBar
        active: !globalDrawer.drawerOpen
    }

    FC.FormCard {
        Layout.fillWidth: true
        Layout.maximumWidth: Kirigami.Units.gridUnit * 56
        Layout.alignment: Qt.AlignHCenter
        visible: modelLoader.item?.status !== XmlListModel.Ready

        FC.FormPlaceholderMessageDelegate {
            id: nullMsg
            text: i18nc("@info:placeholder", "No changelogs have been provided.")
            visible: modelLoader.item?.status === XmlListModel.Null
        }

        FC.FormPlaceholderMessageDelegate {
            id: loadingMsg
            text: i18nc("@info:placeholder", "Loading changelog") + dots
            visible: modelLoader.item?.status === XmlListModel.Loading

            // loading dots
            property string dots: "."
            property int dotIndex: 0

            Timer {
                interval: 500
                running: true
                repeat: true
                onTriggered: {
                    parent.dotIndex = (parent.dotIndex % 3) + 1;
                    parent.dots = ".".repeat(parent.dotIndex);
                }
            }
        }

        FC.FormPlaceholderMessageDelegate {
            id: errorMsg
            text: i18nc("@info:placeholder", "Error loading changelogs:") + modelLoader.item?.errorString()
            visible: modelLoader.item?.status === XmlListModel.Error
        }

        FC.FormPlaceholderMessageDelegate {
            text: i18nc("@info:placeholder", "An error has occurred loading changelogs.")
            visible: !(nullMsg.visible || loadingMsg.visible || errorMsg.visible)
        }

        Item {
            Layout.fillHeight: true
        }
    }

    Repeater {
        id: repeater
        enabled: modelLoader.item?.status === XmlListModel.Ready
        model: modelLoader.item

        delegate: ColumnLayout {
            id: delegate
            required property int index
            required property string updated
            required property string link
            required property string title
            required property string content

            Layout.fillWidth: true
            Layout.maximumWidth: Kirigami.Units.gridUnit * 56
            Layout.alignment: Qt.AlignHCenter

            Item {
                implicitHeight: Kirigami.Units.mediumSpacing
                visible: delegate.index > 0
            }

            FCRssDelegate {
                updated: delegate.updated
                link: delegate.link
                title: delegate.title
                content: delegate.content
            }
        }
    }

    Loader {
        id: modelLoader
        source: "RssModel.qml"
    }
}
