#include <QApplication>
#include <QCoreApplication>
#include <QMenu>
#include <QWidgetAction>
#include <SARibbonColorToolButton.h>

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    // Match Aero7's application stylesheet and a ribbon-owned color menu.
    app.setStyleSheet("QToolButton { color: #161616; border: 1px solid #707070; }");
    for (int i = 0; i < 20; ++i) {
        auto *parent = new QWidget;
        auto *button = new SARibbonColorToolButton(parent);
        button->setupStandardColorMenu();
        parent->show();
        QCoreApplication::processEvents();
        delete parent;
        QCoreApplication::processEvents();
    }
    return 0;
}
