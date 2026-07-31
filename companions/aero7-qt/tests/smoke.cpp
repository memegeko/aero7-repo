// SPDX-License-Identifier: MIT
#include <Aero7Qt/eventlistener.h>
#include <Aero7Qt/glassframe.h>
#include <Aero7Qt/navigationbuttons.h>
#include <Aero7Qt/properties.h>
#include <Aero7Qt/stylesheet.h>

#include <QApplication>
#include <QEvent>
#include <QMainWindow>
#include <QWidget>

int main(int argc, char **argv)
{
    QApplication application(argc, argv);
    Aero7::applyApplicationStyle(&application);

    QMainWindow window;
    QWidget content;
    QWidget header;
    Aero7::NavigationButtons buttons(&header);
    Aero7::applyGlassFrame(&window, &content, &header, nullptr);
    Aero7::setProperty(&window, "aero7Smoke", true);

    bool eventSeen = false;
    Aero7::onEvent(&window, QEvent::User, [&eventSeen](QEvent *) { eventSeen = true; });
    QEvent event(QEvent::User);
    QApplication::sendEvent(&window, &event);

    return application.styleSheet().contains(QStringLiteral("Aero7Qt"))
            && Aero7::property(&window, "aero7Smoke", false)
            && buttons.back() && buttons.forward() && eventSeen
        ? 0
        : 1;
}
