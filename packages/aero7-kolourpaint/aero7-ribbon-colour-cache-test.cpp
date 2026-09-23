// SPDX-License-Identifier: MIT
#include <QApplication>
#include <QDebug>
#include <QImage>
#include <QStyleOptionToolButton>
#include <SARibbonColorToolButton.h>

class ColourButton : public SARibbonColorToolButton
{
public:
    QImage iconPixels()
    {
        QStyleOptionToolButton option;
        initStyleOption(&option);
        return createIconPixmap(option, QSize(32, 32)).toImage();
    }
};

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    ColourButton button;
    button.setColorStyle(SARibbonColorToolButton::ColorFillToIcon);
    // Do not move the pointer or dispatch QAction events between changes:
    // palette selections update the icon directly while hover stays unchanged.
    for (const QColor colour : {QColor(Qt::black), QColor(Qt::red),
                               QColor(Qt::green), QColor(Qt::blue)}) {
        button.setColor(colour);
        const QImage first = button.iconPixels();
        const QImage cached = button.iconPixels();
        if (first.isNull() || first != cached
            || first.pixelColor(first.width() / 2, first.height() / 2) != colour) {
            qCritical() << "AERO7_COLOUR_CACHE_FAIL:" << colour
                        << "was not rendered after direct icon change";
            return 1;
        }
    }
    qInfo("AERO7_COLOUR_CACHE_PASSED: direct colour changes and cache reuse");
    return 0;
}
