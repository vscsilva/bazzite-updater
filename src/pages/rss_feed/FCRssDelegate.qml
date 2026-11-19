// SPDX-FileCopyrightText: 2026 Robert French <frenchrobertm@outlook.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FC

import io.github.rfrench3.bazzite_updater

FormCardCollapsible {
    id: delegate
    required property string updated
    required property string link
    required property string title
    required property string content

    topComponent: Item {
        Layout.fillWidth: true
        implicitHeight: articleHeader.implicitHeight + Kirigami.Units.largeSpacing * 2
        implicitWidth: articleHeader.implicitWidth

        RowLayout {
            id: articleHeader
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.rightMargin: Kirigami.Units.largeSpacing
            anchors.topMargin: Kirigami.Units.largeSpacing
            anchors.bottomMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 3
                    text: delegate.title
                    wrapMode: Text.WordWrap
                }

                QQC2.Label {
                    text: delegate.formatRssDate(delegate.updated)
                    opacity: 0.7
                }
            }

            QQC2.ToolButton {
                text: i18n("Open")
                icon.name: "internet-web-browser-symbolic"
                display: QQC2.AbstractButton.IconOnly
                Accessible.name: i18n("Open link")
                onClicked: Qt.openUrlExternally(delegate.link)
            }
        }
    }

    buttonText: expanded ? i18n("Read less") : i18n("Read more")

    FC.AbstractFormDelegate {
        id: abstractDelegate

        clip: true

        // stops controllers/tabbing from selecting this item
        focusPolicy: Qt.NoFocus

        // disable hover/click feedback
        background: Item {
            visible: false
        }

        contentItem: ColumnLayout {
            Text {
                id: contentText

                visible: abstractDelegate.visible

                // Without the messy regex, most images tend to grow far beyond the bounds of the formcard.
                // 516 is the precalculated exact max width images have in formcards that aren't width-constrained.
                text: delegate.content.replace(/<img\b([^>]*)\s*\/?>/gi, function (imgTag: string): string {
                    // Extract current width and height values
                    const widthMatch = imgTag.match(/\bwidth\s*=\s*["'](\d+)["']/i);
                    const heightMatch = imgTag.match(/\bheight\s*=\s*["'](\d+)["']/i);

                    if (widthMatch) {
                        const origWidth = parseInt(widthMatch[1], 10);

                        if (origWidth > 516) {
                            // Replace width with capped max value
                            imgTag = imgTag.replace(/\bwidth\s*=\s*["']\d+["']/i, 'width="516"');

                            if (heightMatch) {
                                const origHeight = parseInt(heightMatch[1], 10);
                                // Calculate proportional height
                                const newHeight = Math.round((origHeight * 516) / origWidth);
                                imgTag = imgTag.replace(/\bheight\s*=\s*["']\d+["']/i, 'height="' + newHeight + '"');
                            }
                        }
                    }

                    return imgTag;
                })

                textFormat: Text.RichText

                color: palette.text

                Layout.fillWidth: true
                wrapMode: Text.Wrap

                onLinkActivated: url => Qt.openUrlExternally(url)

                HoverHandler {
                    cursorShape: contentText.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }

    function formatRssDate(dateString: string): string {
        const date = new Date(dateString);
        if (isNaN(date.getTime())) {
            return dateString;
        }

        const now = new Date();
        const locale = Qt.locale();

        const dateFormat = (date.getFullYear() === now.getFullYear()) ? "d MMMM" : "d MMMM yyyy";
        const absoluteDate = locale.toString(date, dateFormat);

        const diff = Math.floor((now - date) / 1000);
        const MIN = 60, HOUR = 3600, DAY = 86400, MONTH = DAY * 30, YEAR = DAY * 365;

        let relative;
        if (diff < 0) {
            relative = i18nc("elapsed time", "in the future");
        } else if (diff < MIN) {
            relative = i18nc("elapsed time", "just now");
        } else if (diff < HOUR) {
            relative = i18ncp("elapsed time", "%1 minute ago", "%1 minutes ago", Math.floor(diff / MIN));
        } else if (diff < DAY) {
            relative = i18ncp("elapsed time", "%1 hour ago", "%1 hours ago", Math.floor(diff / HOUR));
        } else if (diff < MONTH) {
            relative = i18ncp("elapsed time", "%1 day ago", "%1 days ago", Math.floor(diff / DAY));
        } else if (diff < YEAR) {
            relative = i18ncp("elapsed time", "%1 month ago", "%1 months ago", Math.floor(diff / MONTH));
        } else {
            relative = i18ncp("elapsed time", "%1 year ago", "%1 years ago", Math.floor(diff / YEAR));
        }

        return i18nc("absolute date followed by relative time, e.g. 5 March (2 days ago)", "%1 (%2)", absoluteDate, relative);
    }
}
