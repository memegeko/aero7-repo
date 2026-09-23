// SPDX-License-Identifier: MIT
// QA-only preload probe. Never installed or loaded by the desktop package.
#include <QApplication>
#include <QDebug>
#include <QMainWindow>
#include <QMenuBar>
#include <QMenu>
#include <QTimer>
#include <QToolBar>
#include <QToolButton>

static void checkLayout()
{
    QMainWindow *window = nullptr;
    for (QWidget *candidate : QApplication::topLevelWidgets()) {
        if (candidate->inherits("kpMainWindow")) {
            window = qobject_cast<QMainWindow *>(candidate);
            break;
        }
    }
    if (!window) {
        qCritical("AERO7_LAYOUT_FAIL: no Paint window");
        QCoreApplication::exit(1);
        return;
    }
    QWidget *ribbon = nullptr;
    for (QWidget *candidate : window->findChildren<QWidget *>()) {
        if (candidate->inherits("SARibbonBar")) {
            ribbon = candidate;
            break;
        }
    }
    auto *mainToolbar = window->findChild<QToolBar *>(QStringLiteral("mainToolBar"));
    QToolButton *fileButton = nullptr;
    for (auto *candidate : window->findChildren<QToolButton *>()) {
        if (candidate->inherits("SARibbonApplicationButton")) fileButton = candidate;
    }
    if (!fileButton || fileButton->text().isEmpty() || !fileButton->menu()
        || fileButton->menu()->actions().isEmpty()) {
        qCritical("AERO7_LAYOUT_FAIL: File menu button is not discoverable");
        QCoreApplication::exit(1);
        return;
    }
    const bool expectedRibbon = qEnvironmentVariable("AERO7_QA_EXPECT_RIBBON") != "0";
    auto valid = [&](bool enabled) {
        return ribbon && mainToolbar && ribbon->isVisible() == enabled
            && window->menuBar()->isVisible() == !enabled
            && mainToolbar->isVisible() == !enabled;
    };
    if (!valid(expectedRibbon)) {
        qCritical() << "AERO7_LAYOUT_FAIL: startup" << expectedRibbon
                    << "ribbon" << (ribbon && ribbon->isVisible())
                    << "menu" << window->menuBar()->isVisible()
                    << "toolbar" << (mainToolbar && mainToolbar->isVisible());
        QCoreApplication::exit(1);
        return;
    }
    // Exercise the real slot in both directions, not a mock visibility helper.
    for (bool enabled : {!expectedRibbon, expectedRibbon}) {
        if (!QMetaObject::invokeMethod(window, "slotShowRibbonToggled",
                                      Qt::DirectConnection, Q_ARG(bool, enabled))
            || !valid(enabled)) {
            qCritical("AERO7_LAYOUT_FAIL: mode transition");
            QCoreApplication::exit(1);
            return;
        }
    }
    qInfo("AERO7_LAYOUT_PASS: initial mode and both transitions");
    window->close(); // Normal blank-document close also exercises teardown.
}

static void startProbe()
{
    QTimer::singleShot(1000, qApp, checkLayout);
    QTimer::singleShot(10000, qApp, [] {
        qCritical("AERO7_LAYOUT_FAIL: application did not close normally");
        QCoreApplication::exit(1);
    });
}
Q_COREAPP_STARTUP_FUNCTION(startProbe)
