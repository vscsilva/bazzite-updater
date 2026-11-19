// SPDX-FileCopyrightText: 2025-2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater
import io.github.rfrench3.controllable as GP

Kirigami.ScrollablePage {
    id: page

    title: GP.Labels.east + GP.Labels.spacer_large + i18n("System Update")

    property alias consoleDrawerOpen: consoleDrawer.drawerOpen
    property string lastCheckedText: Qt.locale().toString(new Date(), Locale.ShortFormat)
    property bool updateStatusRefreshed: false


    function toggleConsoleDrawer(open: bool): void {
        if (open && !consoleDrawer.drawerOpen) {
            for (let i = 0; i < 5; ++i) {
                hidePassiveNotification();
            }
        }
        consoleDrawer.drawerOpen = open;
    }

    function handleInput(buttonId: int, button_down: bool): void {
        if (button_down == false)
            return;

        switch (buttonId) {
        case 0: // A
            updateButton.animateClick();
            return;
        }

        if (consoleDrawer.drawerOpen) {
            consoleDrawer.handleInput(buttonId, button_down);
            return;
        }

        switch (buttonId) {
        case 3: // Y
            toggleConsoleDrawer(!consoleDrawer.drawerOpen);
            break;
        }
    }

    actions: []

    Kirigami.Action {
        id: updateAction
        text: i18n("Start update") + GP.Labels.spacer + GP.Labels.south
        shortcut: "Return"
        enabled: AppState.allowCommands && !SystemUpdateBackend.blockUpdate && (AppConfig.ini.Commands?.systemUpdateCommand || "")

        onTriggered: {
            sessionStorage.mainText = i18n("System Updating");

            showPassiveNotification(i18n("Update Started"), Kirigami.short);
            SystemUpdateBackend.runUpdate(callback => {
                if (callback != 0) {
                    if (consoleDrawer.drawerOpen) {
                        showPassiveNotification(i18n("Update Failed."), Kirigami.short);
                    } else {
                        showPassiveNotification(i18n("Update Failed. Check console for more details."), Kirigami.long, i18n("Open console") + GP.Labels.spacer + GP.Labels.north, () => {
                            toggleConsoleDrawer(true);
                        });
                    }
                    sessionStorage.mainText = "";
                    return;
                }

                showPassiveNotification(i18n("Update Succeeded!"), Kirigami.short);
                sessionStorage.updateCompleted = true;
                sessionStorage.mainText = i18n("System Updated!");

                AppData.reloadOstree(() => {
                    page.lastCheckedText = Qt.locale().toString(new Date(), Locale.ShortFormat);
                    page.updateStatusRefreshed = true;
                    if (!AppData.ostree.onLatestDeployment())
                        AppDialogManager.show(rebootAfterUpdateDialog);
                    else
                        showPassiveNotification(i18n("No reboot necessary."), Kirigami.short);
                });
            }, errorMessage => {
                errorDialog.subtitle = errorMessage;
                AppDialogManager.show(errorDialog);
            });
        }
    }

    titleDelegate: RowLayout {
        width: page.width
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading {
            Layout.fillWidth: true
            text: page.title
            level: 2
            elide: Text.ElideRight
        }

        QQC2.Switch {
            text: i18n("Show Console")
            checked: consoleDrawer.drawerOpen
            onToggled: toggleConsoleDrawer(checked)
        }
    }

    AppDialog {
        id: rebootAfterUpdateDialog
        titleStart: i18n("Update Complete")
        standardButtons: Kirigami.Dialog.NoButton
        subtitle: i18n("Restart now to apply the system update, or exit and restart later.")

        customFooterActions: [
            Kirigami.Action {
                id: restartNowAction
                text: i18n("Restart Now")
                icon.name: "system-shutdown-symbolic"
                onTriggered: {
                    rebootAfterUpdateDialog.accept();
                    AppState.rebootSystem(callback => {
                        console.log("Reboot callback: " + callback);
                    });
                }
            },
            Kirigami.Action {
                id: exitAfterUpdateAction
                text: i18n("Exit")
                icon.name: "application-exit-symbolic"
                onTriggered: {
                    rebootAfterUpdateDialog.accept();
                    Qt.quit();
                }
            }
        ]

        function handleInput(buttonId, button_down) {
            if (!button_down)
                return;
            switch (buttonId) {
            case 0: // A
                restartNowAction.trigger();
                break;
            case 1: // B
                exitAfterUpdateAction.trigger();
                break;
            }
        }
    }

    AppDialog {
        id: errorDialog
        titleStart: i18n("Update Error")
        standardButtons: Kirigami.Dialog.NoButton
        subtitle: i18n("This will reboot the system.")

        customFooterActions: [
            Kirigami.Action {
                id: errorDialogConfirm
                text: i18n("Ok") + GP.Labels.spacer + GP.Labels.south
                onTriggered: errorDialog.accept()
            }
        ]

        function handleInput(buttonId, button_down) {
            if (!button_down)
                return;
            switch (buttonId) {
            case 0: // A
                errorDialogConfirm.triggered();
                break;
            case 1: // B
                errorDialog.reject();
                break;
            }
        }
    }

    ColumnLayout {
        id: pageContents
        width: Math.min(page.availableWidth - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 48)
        spacing: Kirigami.Units.gridUnit

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.largeSpacing

            Item {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 5.5
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5.5

                Image {
                    anchors.fill: parent
                    source: (AppData.aboutDataOs.programLogo) ? "file:/" + AppData.aboutDataOs.programLogo : "qrc:/fallbackLogo"
                    sourceSize: Qt.size(width, height)
                    antialiasing: true
                }
            }

            Kirigami.Heading {
                text: sessionStorage.mainText || i18n("System Update")
                level: 1
            }
        }

        FC.FormCard {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: Kirigami.Units.iconSizes.large
                        source: AppState.updateRunning ? "system-software-update-symbolic" : (SystemUpdateBackend.blockUpdate ? "dialog-error-symbolic" : "checkmark-symbolic")
                        color: AppState.updateRunning ? Kirigami.Theme.highlightColor : Kirigami.Theme.positiveTextColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Heading {
                            Layout.fillWidth: true
                            level: 3
                            text: AppState.updateRunning ? i18n("Updating your system") : (SystemUpdateBackend.blockUpdate ? i18n("Update requires attention") : i18n("Your system is up to date"))
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: AppState.updateRunning ? i18n("Your system image and applications are being updated.") : (SystemUpdateBackend.blockUpdate ? i18n("Resolve the reported issue before trying again.") : i18n("Your system image and applications are up to date."))
                            opacity: 0.8
                        }
                    }
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.largeSpacing
                    Layout.rightMargin: Kirigami.Units.largeSpacing
                    Layout.topMargin: Kirigami.Units.mediumSpacing
                    Layout.bottomMargin: Kirigami.Units.mediumSpacing
                    text: i18n("Last checked: %1", page.lastCheckedText)
                    opacity: 0.7
                }
            }
        }

        Kirigami.Heading {
            Layout.topMargin: Kirigami.Units.smallSpacing
            text: i18n("Update Actions")
            level: 2
        }

        FC.FormCard {
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: pageContents.width * 0.52
                    spacing: Kirigami.Units.mediumSpacing

                    QQC2.Button {
                        id: updateButton
                        Layout.fillWidth: true
                        text: AppState.updateRunning ? i18n("Updating System…") : i18n("Update System")
                        icon.name: AppState.updateRunning ? "system-software-update-symbolic" : "download-symbolic"
                        enabled: updateAction.enabled
                        highlighted: true
                        onClicked: updateAction.trigger()
                    }

                    QQC2.Button {
                        Layout.fillWidth: true
                        text: i18n("Refresh Status")
                        icon.name: "view-refresh-symbolic"
                        enabled: !AppState.commandRunning && !page.updateStatusRefreshed
                        onClicked: {
                            AppData.reloadOstree(() => {
                                page.lastCheckedText = Qt.locale().toString(new Date(), Locale.ShortFormat);
                                page.updateStatusRefreshed = true;
                                showPassiveNotification(i18n("System update status refreshed."), Kirigami.short);
                            });
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Label {
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                        text: i18n("Included components:")
                        font.weight: Font.Medium
                    }

                    Repeater {
                        model: [i18n("Bazzite OS"), i18n("Flatpak Packages"), i18n("Gaming components")]

                        delegate: RowLayout {
                            required property string modelData
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                source: "checkmark-symbolic"
                                color: Kirigami.Theme.positiveTextColor
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: modelData
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            FormDelegateSeparatorFixed {
                visible: errorUpdateNotFound.visible
            }

            FC.FormTextDelegate {
                id: errorUpdateNotFound
                visible: !(AppConfig.ini.Commands?.systemUpdateCommand || "")
                enabled: visible
                text: i18n("The System Update command is not defined.")
                description: i18n("Make sure the config file (/etc/bazzite-updater/config.ini) is present.")
            }
        }

        Item {
            id: centeredStepsHost
            Layout.fillWidth: true
            implicitHeight: stepsContent.implicitHeight
            visible: AppState.updateRunning || AppState.commandSucceeded || SystemUpdateBackend.blockUpdate

            UpdateSteps {
                id: stepsContent
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(centeredStepsHost.width * 0.72, Kirigami.Units.gridUnit * 34)
            }
        }
    }

    ConsoleDrawer {
        id: consoleDrawer
        drawerOpen: false
        model: SystemUpdateBackend.consoleModel

        readonly property ostreeDeployment __img: AppData.ostree.deployments.find(img => img.isCurrent)
        readonly property int __layeredCount: __img.layeredPackages?.length || 0

        includeAtStart: {
            const list = ["Bazzite Updater %1".arg(ApplicationVersion)];

            if (RebaseModel.currentImage.name && RebaseModel.currentImage.currentTag)
                list.push(`${RebaseModel.currentImage.name}:${RebaseModel.currentImage.currentTag}`);

            if (OtherUtilsBackend.currentImage.version)
                list.push(OtherUtilsBackend.currentImage.version);

            if (__layeredCount !== 0)
                list.push(i18np("%1 Layered package", "%1 Layered packages", __layeredCount));

            return list.join('\n');
        }

        Item {
            Layout.fillHeight: true
        }

        QQC2.Label {
            text: consoleDrawer.includeAtStart
            color: systemPalette.placeholderText
        }

        SystemPalette {
            id: systemPalette
            colorGroup: SystemPalette.Active
        }
    }
}
