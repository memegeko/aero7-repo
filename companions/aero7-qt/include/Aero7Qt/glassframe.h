// SPDX-License-Identifier: MIT
#pragma once

#include <QMainWindow>
#include <QWidget>

namespace Aero7 {

inline void applyGlassFrame(QMainWindow *window,
                            QWidget *content = nullptr,
                            QWidget *header = nullptr,
                            QWidget *footer = nullptr)
{
    if (!window) {
        return;
    }

    window->setProperty("aero7GlassFrame", true);
    window->setAttribute(Qt::WA_TranslucentBackground, true);

    const QString glass = QStringLiteral(
        "background: qlineargradient(x1:0,y1:0,x2:0,y2:1,"
        "stop:0 rgba(232,247,255,218), stop:0.45 rgba(155,205,238,204),"
        "stop:1 rgba(83,145,192,218));"
        "border: 1px solid rgba(255,255,255,185);");
    const QString inset = QStringLiteral(
        "background: rgba(252,252,252,248);"
        "border: 1px solid #5b7185;");

    if (header) {
        header->setProperty("aero7GlassRegion", true);
        header->setStyleSheet(glass + header->styleSheet());
    }
    if (footer) {
        footer->setProperty("aero7GlassRegion", true);
        footer->setStyleSheet(glass + footer->styleSheet());
    }
    if (content) {
        content->setProperty("aero7InsetContent", true);
        content->setStyleSheet(inset + content->styleSheet());
    }
}

} // namespace Aero7
