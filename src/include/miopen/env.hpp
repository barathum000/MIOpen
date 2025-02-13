/*******************************************************************************
 *
 * MIT License
 *
 * Copyright (c) 2017 Advanced Micro Devices, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 *******************************************************************************/
#ifndef GUARD_MIOPEN_ENV_HPP
#define GUARD_MIOPEN_ENV_HPP

#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

namespace miopen {

/// \todo Rework: Case-insensitive string compare, ODR, (?) move to .cpp

// Declare a cached environment variable
#define MIOPEN_DECLARE_ENV_VAR(x)                 \
    struct x                                      \
    {                                             \
        static const char* value() { return #x; } \
    };

/*
 * Returns false if a feature-controlling environment variable is defined
 * and set to something which disables a feature.
 */
inline bool IsEnvvarValueDisabled(const char* name)
{
    // NOLINTNEXTLINE (concurrency-mt-unsafe)
    const auto value_env_p = std::getenv(name);
    if(value_env_p == nullptr)
        return false;
    else
    {
        std::string value_env_str = value_env_p;
        for(auto& c : value_env_str)
        {
            if(std::isalpha(c) != 0)
            {
                c = std::tolower(static_cast<unsigned char>(c));
            }
        }
        return (std::strcmp(value_env_str.c_str(), "disable") == 0 ||
                std::strcmp(value_env_str.c_str(), "disabled") == 0 ||
                std::strcmp(value_env_str.c_str(), "0") == 0 ||
                std::strcmp(value_env_str.c_str(), "no") == 0 ||
                std::strcmp(value_env_str.c_str(), "off") == 0 ||
                std::strcmp(value_env_str.c_str(), "false") == 0);
    }
}

inline bool IsEnvvarValueEnabled(const char* name)
{
    // NOLINTNEXTLINE (concurrency-mt-unsafe)
    const auto value_env_p = std::getenv(name);
    if(value_env_p == nullptr)
        return false;
    else
    {
        std::string value_env_str = value_env_p;
        for(auto& c : value_env_str)
        {
            if(std::isalpha(c) != 0)
            {
                c = std::tolower(static_cast<unsigned char>(c));
            }
        }
        return (std::strcmp(value_env_str.c_str(), "enable") == 0 ||
                std::strcmp(value_env_str.c_str(), "enabled") == 0 ||
                std::strcmp(value_env_str.c_str(), "1") == 0 ||
                std::strcmp(value_env_str.c_str(), "yes") == 0 ||
                std::strcmp(value_env_str.c_str(), "on") == 0 ||
                std::strcmp(value_env_str.c_str(), "true") == 0);
    }
}

// Return 0 if env is enabled else convert environment var to an int.
// Supports hexadecimal with leading 0x or decimal
inline uint64_t EnvvarValue(const char* name, uint64_t fallback = 0)
{
    // NOLINTNEXTLINE (concurrency-mt-unsafe)
    const auto value_env_p = std::getenv(name);
    if(value_env_p == nullptr)
    {
        return fallback;
    }
    else
    {
        return strtoull(value_env_p, nullptr, 0);
    }
}

inline std::vector<std::string> GetEnv(const char* name)
{
    // NOLINTNEXTLINE (concurrency-mt-unsafe)
    const auto p = std::getenv(name);
    if(p == nullptr)
        return {};
    else
        return {{p}};
}

template <class T>
inline const char* GetStringEnv(T)
{
    static const std::vector<std::string> result = GetEnv(T::value());
    if(result.empty())
        return nullptr;
    else
        return result.front().c_str();
}

template <class T>
inline bool IsEnabled(T)
{
    static const bool result = miopen::IsEnvvarValueEnabled(T::value());
    return result;
}

template <class T>
inline bool IsDisabled(T)
{
    static const bool result = miopen::IsEnvvarValueDisabled(T::value());
    return result;
}

template <class T>
inline uint64_t Value(T, uint64_t fallback = 0)
{
    static const auto result = miopen::EnvvarValue(T::value(), fallback);
    return result;
}
} // namespace miopen

#endif
