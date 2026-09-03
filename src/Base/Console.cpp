// SPDX-License-Identifier: LGPL-2.1-or-later

#include "Base/Console.h"

#include <cstdio>

namespace
{
void writeToStderr(const std::string& message)
{
    std::fputs(message.c_str(), stderr);
}
}  // namespace

namespace Base
{

ConsoleSingleton::ConsoleSingleton()
    : logHandler(writeToStderr)
    , warningHandler(writeToStderr)
{}

ConsoleSingleton& ConsoleSingleton::instance()
{
    static ConsoleSingleton singleton;
    return singleton;
}

void ConsoleSingleton::setLogHandler(std::function<void(const std::string&)> handler)
{
    logHandler = std::move(handler);
}

void ConsoleSingleton::setWarningHandler(std::function<void(const std::string&)> handler)
{
    warningHandler = std::move(handler);
}

}  // namespace Base
