// SPDX-License-Identifier: LGPL-2.1-or-later

/*
 * Standalone replacement for FreeCAD's Base::Console.
 *
 * The upstream Base::Console (FreeCAD's Base/Console.h/.cpp) pulls in Qt and
 * FreeCAD's Python bindings, which this project doesn't otherwise depend on.
 * planegcs only ever calls Base::Console().log(...) and .warning(...), so
 * this shim implements just those two entry points, with output going to
 * stderr by default and redirectable via setLogHandler()/setWarningHandler().
 *
 * update.sh installs this file in place of FreeCAD's real Console.h on every
 * sync; see console-shim/README.md.
 */

#ifndef BASE_CONSOLE_H
#define BASE_CONSOLE_H

#include <functional>
#include <string>
#include <utility>

#include <fmt/printf.h>

namespace Base
{

class ConsoleSingleton
{
public:
    static ConsoleSingleton& instance();

    ConsoleSingleton(const ConsoleSingleton&) = delete;
    ConsoleSingleton(ConsoleSingleton&&) = delete;
    ConsoleSingleton& operator=(const ConsoleSingleton&) = delete;
    ConsoleSingleton& operator=(ConsoleSingleton&&) = delete;

    template<typename... Args>
    void log(const char* format, Args&&... args)
    {
        logHandler(fmt::sprintf(format, std::forward<Args>(args)...));
    }

    template<typename... Args>
    void warning(const char* format, Args&&... args)
    {
        warningHandler(fmt::sprintf(format, std::forward<Args>(args)...));
    }

    void setLogHandler(std::function<void(const std::string&)> handler);
    void setWarningHandler(std::function<void(const std::string&)> handler);

private:
    ConsoleSingleton();

    std::function<void(const std::string&)> logHandler;
    std::function<void(const std::string&)> warningHandler;
};

inline ConsoleSingleton& Console()
{
    return ConsoleSingleton::instance();
}

}  // namespace Base

#endif  // BASE_CONSOLE_H
