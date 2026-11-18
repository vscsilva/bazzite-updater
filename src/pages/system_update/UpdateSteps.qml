// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import io.github.rfrench3.bazzite_updater

ColumnLayout {
    id: root

    Layout.fillWidth: true

    Repeater {
        model: SystemUpdateBackend.updateStepsModel

        delegate: RowLayout {
            id: del
            required property string module
            required property int progress_current
            required property int progress_total
            required property int exit_status

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(root.width, Kirigami.Units.gridUnit * 24)
            spacing: Kirigami.Units.largeSpacing

            Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                horizontalAlignment: Text.AlignLeft
                text: {
                    switch (del.module.toLowerCase()) {
                    case "system":
                        return i18n("System");
                    case "brew":
                        return i18n("Brew");
                    case "flatpak":
                        return i18n("Flatpak");
                    default:
                        return del.module.charAt(0).toUpperCase() + del.module.slice(1);
                    }
                }
            }

            ProgressBar {
                Layout.fillWidth: visible
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                visible: del.exit_status === -1
                indeterminate: del.progress_current === -1
                value: del.progress_current
                to: del.progress_total

                Behavior on value {
                    NumberAnimation {
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Label {
                visible: del.exit_status !== -1
                text: del.exit_status === 0 ? i18n("Completed") : i18n("Failed")
                opacity: 0.75
            }

            Loader {
                sourceComponent: {
                    if (del.exit_status === -1)
                        return busyComponent;
                    if (del.exit_status === 0)
                        return checkmarkComponent;
                    return errorComponent;
                }

                Component {
                    id: busyComponent
                    BusyIndicator {
                        id: busyIndicator
                    }
                }

                Component {
                    id: checkmarkComponent
                    Kirigami.Icon {
                        source: "checkmark-symbolic"
                    }
                }

                Component {
                    id: errorComponent
                    Kirigami.Icon {
                        source: "error-symbolic"
                    }
                }
            }

            // Smooth fade-in animation
            opacity: 0
            Component.onCompleted: {
                opacity = 1;
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
