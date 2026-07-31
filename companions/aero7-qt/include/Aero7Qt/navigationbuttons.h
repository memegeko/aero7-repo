// SPDX-License-Identifier: MIT
#pragma once

#include <QHBoxLayout>
#include <QMenu>
#include <QPushButton>
#include <QStyle>
#include <QToolButton>
#include <QWidget>

namespace Aero7 {

class NavigationButtons final : public QWidget
{
public:
    explicit NavigationButtons(QWidget *parent = nullptr)
        : QWidget(parent)
        , m_back(new QPushButton(this))
        , m_forward(new QPushButton(this))
        , m_menu(new QToolButton(this))
    {
        auto *layout = new QHBoxLayout(this);
        layout->setContentsMargins(0, 0, 0, 0);
        layout->setSpacing(1);

        m_back->setObjectName(QStringLiteral("aero7BackButton"));
        m_forward->setObjectName(QStringLiteral("aero7ForwardButton"));
        m_back->setIcon(style()->standardIcon(QStyle::SP_ArrowBack));
        m_forward->setIcon(style()->standardIcon(QStyle::SP_ArrowForward));
        m_back->setToolTip(tr("Back"));
        m_forward->setToolTip(tr("Forward"));
        m_menu->setObjectName(QStringLiteral("aero7HistoryButton"));
        m_menu->setArrowType(Qt::DownArrow);
        m_menu->setPopupMode(QToolButton::InstantPopup);
        m_menu->setToolTip(tr("Recent locations"));
        m_back->setFixedSize(30, 25);
        m_forward->setFixedSize(27, 25);
        m_menu->setFixedSize(18, 25);

        const QString buttonStyle = QStringLiteral(
            "QPushButton { padding: 0; border-radius: 12px; }"
            "QPushButton#aero7ForwardButton { border-top-left-radius: 4px; border-bottom-left-radius: 4px; }");
        m_back->setStyleSheet(buttonStyle);
        m_forward->setStyleSheet(buttonStyle);

        layout->addWidget(m_back);
        layout->addWidget(m_forward);
        layout->addWidget(m_menu);
    }

    QPushButton *back() const { return m_back; }
    QPushButton *forward() const { return m_forward; }
    QToolButton *menuButton() const { return m_menu; }
    void setMenu(QMenu *menu) { m_menu->setMenu(menu); }

private:
    QPushButton *m_back;
    QPushButton *m_forward;
    QToolButton *m_menu;
};

} // namespace Aero7
