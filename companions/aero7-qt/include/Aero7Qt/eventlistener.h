// SPDX-License-Identifier: MIT
#pragma once

#include <QEvent>
#include <QObject>

#include <functional>
#include <utility>

namespace Aero7 {

class EventListener final : public QObject
{
public:
    using Callback = std::function<void(QEvent *)>;

    EventListener(QObject *watched, QEvent::Type type, Callback callback)
        : QObject(watched)
        , m_type(type)
        , m_callback(std::move(callback))
    {
        if (watched) {
            watched->installEventFilter(this);
        }
    }

protected:
    bool eventFilter(QObject *watched, QEvent *event) override
    {
        if (event && event->type() == m_type && m_callback) {
            m_callback(event);
        }
        return QObject::eventFilter(watched, event);
    }

private:
    QEvent::Type m_type;
    Callback m_callback;
};

template<typename Event = QEvent, typename Callback>
EventListener *onEvent(QObject *watched, QEvent::Type type, Callback &&callback)
{
    if (!watched) {
        return nullptr;
    }
    return new EventListener(
        watched,
        type,
        [handler = std::forward<Callback>(callback)](QEvent *event) mutable {
            handler(static_cast<Event *>(event));
        });
}

} // namespace Aero7
