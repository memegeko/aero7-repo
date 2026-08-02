// SPDX-License-Identifier: MIT
#pragma once

#include <QApplication>
#include <QColor>
#include <QPalette>
#include <QString>

namespace Aero7 {

inline QString applicationStyleSheet()
{
    return QStringLiteral(R"AERO7(
        QToolTip {
            color: #101010;
            background: #fffef2;
            border: 1px solid #707070;
            padding: 2px 4px;
        }
        QPushButton, QToolButton {
            color: #161616;
            border: 1px solid #707070;
            border-radius: 3px;
            padding: 3px 10px;
            min-height: 20px;
            background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                stop:0 #ffffff, stop:0.46 #f6f6f6,
                stop:0.48 #e5e5e5, stop:1 #d8d8d8);
        }
        QPushButton:hover, QToolButton:hover {
            border-color: #3c7fb1;
            background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                stop:0 #fafdff, stop:0.45 #e7f5ff,
                stop:0.47 #c7e9ff, stop:1 #b6def5);
        }
        QPushButton:pressed, QToolButton:pressed {
            border-color: #2c628b;
            background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                stop:0 #c6e5f8, stop:1 #e7f5fd);
        }
        QPushButton:disabled, QToolButton:disabled {
            color: #888888;
            border-color: #a8a8a8;
            background: #eeeeee;
        }
        QLineEdit, QComboBox, QSpinBox, QDoubleSpinBox {
            color: #111111;
            background: rgba(255, 255, 255, 235);
            border: 1px solid #7f9db9;
            border-radius: 2px;
            min-height: 21px;
            selection-color: #ffffff;
            selection-background-color: #2a66b1;
        }
        QLineEdit:hover, QComboBox:hover, QSpinBox:hover, QDoubleSpinBox:hover {
            border-color: #3c7fb1;
        }
        QProgressBar {
            color: #202020;
            background: #e6e6e6;
            border: 1px solid #8d8d8d;
            border-radius: 2px;
            text-align: center;
        }
        QProgressBar::chunk {
            background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                stop:0 #bcec75, stop:0.48 #78c934,
                stop:0.5 #43a91d, stop:1 #7fd54a);
        }
    )AERO7");
}

inline void applyApplicationStyle(QApplication *application)
{
    if (!application) {
        return;
    }
    QPalette palette = application->palette();
    palette.setColor(QPalette::Window, QColor(240, 240, 240));
    palette.setColor(QPalette::WindowText, QColor(0, 0, 0));
    palette.setColor(QPalette::Base, QColor(255, 255, 255));
    palette.setColor(QPalette::AlternateBase, QColor(247, 247, 247));
    palette.setColor(QPalette::ToolTipBase, QColor(255, 255, 225));
    palette.setColor(QPalette::ToolTipText, QColor(0, 0, 0));
    palette.setColor(QPalette::Text, QColor(0, 0, 0));
    palette.setColor(QPalette::Button, QColor(240, 240, 240));
    palette.setColor(QPalette::ButtonText, QColor(0, 0, 0));
    palette.setColor(QPalette::Highlight, QColor(51, 153, 255));
    palette.setColor(QPalette::HighlightedText, QColor(255, 255, 255));
    application->setPalette(palette);

    const QString marker = QStringLiteral("/* Aero7Qt */");
    if (application->styleSheet().contains(marker)) {
        return;
    }
    application->setStyleSheet(application->styleSheet() + marker + applicationStyleSheet());
}

} // namespace Aero7
