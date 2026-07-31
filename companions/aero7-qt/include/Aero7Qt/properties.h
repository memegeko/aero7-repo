// SPDX-License-Identifier: MIT
#pragma once

#include <QObject>
#include <QVariant>

namespace Aero7 {

template<typename Value>
void setProperty(QObject *object, const char *name, const Value &value)
{
    if (object) {
        object->setProperty(name, QVariant::fromValue(value));
    }
}

template<typename Value>
Value property(const QObject *object, const char *name, const Value &fallback = Value{})
{
    if (!object) {
        return fallback;
    }
    const QVariant value = object->property(name);
    return value.isValid() && value.canConvert<Value>() ? value.value<Value>() : fallback;
}

template<typename Sender, typename Signal>
QMetaObject::Connection bindProperty(
    Sender *source,
    const char *sourceName,
    QObject *target,
    const char *targetName,
    Signal signal,
    bool syncNow = false)
{
    const auto copyValue = [source, sourceName, target, targetName] {
        if (source && target) {
            target->setProperty(targetName, source->property(sourceName));
        }
    };
    const QMetaObject::Connection connection = QObject::connect(source, signal, target, copyValue);
    if (syncNow) {
        copyValue();
    }
    return connection;
}

} // namespace Aero7
