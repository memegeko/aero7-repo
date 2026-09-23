// SPDX-License-Identifier: MIT
// QA-only probe: non-empty documents, retained preferences and unsaved changes.
#include <aero7commondialog.h>
#include <QApplication>
#include <QClipboard>
#include <QDebug>
#include <QDialog>
#include <QFileInfo>
#include <QImage>
#include <QPointer>
#include <QPushButton>
#include <QTimer>

static bool failed = false;
static void fail(const char *message)
{
    failed = true;
    qCritical("AERO7_DOCUMENT_WORKFLOW_FAIL: %s", message);
    QCoreApplication::exit(1);
}

static QList<QWidget *> windows()
{
    QList<QWidget *> result;
    for (QWidget *widget : QApplication::topLevelWidgets())
        if (widget->inherits("kpMainWindow") && widget->isVisible()) result.append(widget);
    return result;
}

static void runProbe()
{
    const QString scenario = qEnvironmentVariable("AERO7_QA_WORKFLOW");
    const QString start = qEnvironmentVariable("AERO7_QA_START_IMAGE");
    const QString target = qEnvironmentVariable("AERO7_QA_TARGET_IMAGE");
    auto initial = windows();
    if (initial.size() != 1) return fail("Expected one initial document window");
    QPointer<QWidget> original(initial.first());
    if (!original->windowTitle().contains(QFileInfo(start).fileName()))
        return fail("Initial non-empty image did not load");
    const QImage originalPixels(start);
    if (scenario.startsWith("unsaved-")) {
        QImage pasted(32, 32, QImage::Format_RGB32);
        pasted.fill(Qt::green);
        QApplication::clipboard()->setImage(pasted);
        if (!QMetaObject::invokeMethod(original, "slotPaste", Qt::DirectConnection))
            return fail("Could not invoke actual Paste action");
        if (!original->isWindowModified()) return fail("Paste did not create unsaved changes");
    }
    bool sawConfirmation = false;
    QTimer::singleShot(250, qApp, [&] {
        auto *dialog = qobject_cast<Aero7CommonDialog *>(QApplication::activeModalWidget());
        if (!dialog) return fail("Open did not use the native dialog");
        if (scenario.startsWith("unsaved-")) {
            QTimer::singleShot(250, qApp, [&] {
                auto *confirmation = qobject_cast<QDialog *>(QApplication::activeModalWidget());
                if (!confirmation || qobject_cast<Aero7CommonDialog *>(confirmation))
                    return fail("Missing unsaved-document confirmation");
                const QString choice = scenario == "unsaved-cancel" ? "Cancel"
                    : scenario == "unsaved-save" ? "Save" : "Discard";
                for (auto *button : confirmation->findChildren<QPushButton *>()) {
                    if (QString(button->text()).remove('&') == choice) {
                        sawConfirmation = true;
                        button->click();
                        return;
                    }
                }
                fail("Expected confirmation action not found");
            });
        }
        dialog->setSuggestedFileName(target);
        QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
    });
    if (!QMetaObject::invokeMethod(original, "slotOpen", Qt::DirectConnection))
        return fail("Could not invoke actual Open action");
    if (failed) return;
    const auto remaining = windows();
    if (scenario == "separate-window") {
        if (remaining.size() != 2 || !original || !original->windowTitle().contains(QFileInfo(start).fileName()))
            return fail("Explicit separate-window preference was not retained");
        QWidget *opened = remaining.first() == original ? remaining.last() : remaining.first();
        if (!opened->windowTitle().contains(QFileInfo(target).fileName()))
            return fail("Second document path was not adopted");
        original->close();
        if (!opened->isVisible()) return fail("Closing one window closed another document");
        opened->close();
    } else {
        if (remaining.size() != 1 || remaining.first() != original)
            return fail("Open unexpectedly created a second window");
        const bool cancelled = scenario == "unsaved-cancel";
        const QString expected = cancelled ? start : target;
        if (!original->windowTitle().contains(QFileInfo(expected).fileName()))
            return fail("Wrong document after Open or cancellation");
        if (scenario.startsWith("unsaved-") && !sawConfirmation)
            return fail("Unsaved changes were not confirmed");
        if (cancelled) {
            if (!original->isWindowModified()) return fail("Cancel lost the unsaved state");
            // Explicitly discard only this isolated fixture during test cleanup.
            QTimer::singleShot(150, qApp, [] {
                if (auto *dialog = QApplication::activeModalWidget())
                    for (auto *button : dialog->findChildren<QPushButton *>())
                        if (QString(button->text()).remove('&') == "Discard") { button->click(); return; }
                fail("Cleanup confirmation missing");
            });
        }
        const bool changed = QImage(start) != originalPixels;
        if (changed != (scenario == "unsaved-save"))
            return fail("Save/discard/cancel changed the wrong on-disk image");
        original->close();
    }
    if (!failed) qInfo().noquote() << "AERO7_DOCUMENT_WORKFLOW_PASS:" << scenario;
}

static void startProbe()
{
    QImage first(400, 300, QImage::Format_RGB32);
    first.fill(Qt::red);
    QImage second(320, 240, QImage::Format_RGB32);
    second.fill(Qt::blue);
    if (!first.save(qEnvironmentVariable("AERO7_QA_START_IMAGE"))
        || !second.save(qEnvironmentVariable("AERO7_QA_TARGET_IMAGE")))
        qFatal("Could not create isolated image fixtures");
    QTimer::singleShot(1000, qApp, runProbe);
    QTimer::singleShot(12000, qApp, [] { fail("Timed out or did not close normally"); });
}
Q_COREAPP_STARTUP_FUNCTION(startProbe)
