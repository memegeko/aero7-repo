// SPDX-License-Identifier: MIT
// QA-only preload probe of real Paint actions. Never installed in the package.
#include <aero7commondialog.h>
#include <QApplication>
#include <QComboBox>
#include <QDebug>
#include <QDialog>
#include <QFileInfo>
#include <QImageReader>
#include <QPointer>
#include <QPushButton>
#include <QSpinBox>
#include <QTimer>

static bool failed = false;
static void fail(const char *message)
{
    failed = true;
    qCritical("AERO7_NATIVE_DIALOG_FAIL: %s", message);
    QCoreApplication::exit(1);
}

static QWidget *paintWindow()
{
    for (QWidget *widget : QApplication::topLevelWidgets())
        if (widget->inherits("kpMainWindow")) return widget;
    return nullptr;
}

static void inspectDialog()
{
    auto *dialog = qobject_cast<Aero7CommonDialog *>(QApplication::activeModalWidget());
    if (!dialog) return fail("Paint did not open the native common dialog");
    const QString scenario = qEnvironmentVariable("AERO7_QA_DIALOG_SCENARIO");
    const QString path = qEnvironmentVariable("AERO7_QA_DIALOG_IMAGE");
    if (scenario == "open") {
        dialog->setSuggestedFileName(path);
        if (!QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection))
            fail("Open acceptance failed");
        return;
    }
    QWidget *options = nullptr;
    for (QWidget *widget : dialog->findChildren<QWidget *>())
        if (widget->inherits("kpDocumentSaveOptionsWidget")) options = widget;
    if (!options || !options->isVisible()) return fail("Save options absent or hidden");
    auto *types = dialog->findChild<QComboBox *>("fileType");
    auto *depth = options->findChild<QComboBox *>();
    auto *quality = options->findChild<QSpinBox *>();
    auto *preview = options->findChild<QPushButton *>();
    if (!types || !depth || !quality || !preview) return fail("Missing format or save-option controls");
    QString png, jpeg;
    for (int i = 0; i < types->count(); ++i) {
        if (types->itemText(i).contains("*.png")) png = types->itemText(i);
        if (types->itemText(i).contains("*.jpg")) jpeg = types->itemText(i);
    }
    if (png.isEmpty() || jpeg.isEmpty()) return fail("PNG/JPEG formats unavailable");
    dialog->selectNameFilter(jpeg);
    if (!quality->isVisible() || depth->isVisible()) return fail("JPEG format did not select quality controls");
    quality->setValue(73);
    preview->click();
    bool previewVisible = false;
    for (QWidget *widget : QApplication::topLevelWidgets())
        if (widget->inherits("kpDocumentSaveOptionsPreviewDialog") && widget->isVisible()) previewVisible = true;
    if (!previewVisible) return fail("Real image preview failed to open");
    preview->click();
    dialog->selectNameFilter(png);
    if (!depth->isVisible() || quality->isVisible()) return fail("PNG format did not restore colour-depth controls");
    dialog->selectNameFilter(jpeg);
    if (quality->value() != 73) return fail("Quality lost on format change");
    dialog->selectNameFilter(png);

    if (scenario == "remote-cancel") {
        QPushButton *network = nullptr;
        for (auto *button : dialog->findChildren<QPushButton *>())
            if (QString(button->text()).remove('&').startsWith("Network location")) network = button;
        if (!network) return fail("Explicit KIO route missing");
        QPointer<QWidget> originalOptions(options);
        QTimer::singleShot(300, qApp, [originalOptions]() {
            auto *remote = qobject_cast<QDialog *>(QApplication::activeModalWidget());
            if (!remote || !remote->inherits("KFileCustomDialog") || !originalOptions
                || !remote->isAncestorOf(originalOptions) || !originalOptions->isVisible())
                return fail("Remote route did not preserve the actual options widget");
            remote->reject();
        });
        network->click();
    } else if (scenario == "cancel") {
        dialog->reject();
    } else if (scenario == "save") {
        dialog->setSuggestedFileName(path);
        if (!QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection))
            fail("Save acceptance failed");
    } else {
        fail("Unknown QA scenario");
    }
}

static void runProbe()
{
    QWidget *window = paintWindow();
    if (!window) return fail("No Paint window");
    QTimer::singleShot(300, qApp, inspectDialog);
    const QString scenario = qEnvironmentVariable("AERO7_QA_DIALOG_SCENARIO");
    const char *action = scenario == "open" ? "slotOpen" : "slotSaveAs";
    if (!QMetaObject::invokeMethod(window, action, Qt::DirectConnection))
        return fail("Real Paint action could not be invoked");
    if (failed) return;
    const QString path = qEnvironmentVariable("AERO7_QA_DIALOG_IMAGE");
    if (scenario == "save" || scenario == "open") {
        QImageReader reader(path);
        if (!reader.canRead() || reader.format() != "png" || reader.read().isNull())
            return fail("Output was not an actual readable PNG image");
        if (!window->windowTitle().contains(QFileInfo(path).fileName()))
            return fail("Paint did not adopt the selected document path");
    } else if (QFileInfo::exists(path)) {
        return fail("Cancellation wrote a file");
    }
    qInfo().noquote() << "AERO7_NATIVE_DIALOG_PASS:" << scenario;
    window->close();
}

static void startProbe()
{
    QTimer::singleShot(1000, qApp, runProbe);
    QTimer::singleShot(12000, qApp, [] { fail("Timed out or did not close normally"); });
}
Q_COREAPP_STARTUP_FUNCTION(startProbe)
