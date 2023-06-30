#pragma once

#include <iostream>

namespace blackhole
{
#define PLUGIN_PREFIX "BLACK_HOLE      "

#define PLUGIN_ERROR(message) std::cerr << "E [" << PLUGIN_PREFIX << "] " << message << std::endl;
#define PLUGIN_WARN(message) std::cerr << "W [" << PLUGIN_PREFIX << "] " << message << std::endl;
#define PLUGIN_INFO(message) std::cout << "I [" << PLUGIN_PREFIX << "] " << message << std::endl;
#define PLUGIN_REGISTER_ENDPOINT(__msg)         \
    std::cerr << "I [" << PLUGIN_PREFIX << "] " \
              << "Registering end-point '" << __msg << "'" << std::endl;
#define PLUGIN_REGISTER_RENDERER(__msg)         \
    std::cerr << "I [" << PLUGIN_PREFIX << "] " \
              << "Registering renderer '" << __msg << "'" << std::endl;
#define PLUGIN_REGISTER_LOADER(__msg)           \
    std::cerr << "I [" << PLUGIN_PREFIX << "] " \
              << "Registering loader '" << __msg << "'" << std::endl;
#define PLUGIN_REGISTER_CAMERA(__msg)           \
    std::cerr << "I [" << PLUGIN_PREFIX << "] " \
              << "Registering camera '" << __msg << "'" << std::endl;
#ifdef NDEBUG
#define PLUGIN_DEBUG(message) ;
#else
#define PLUGIN_DEBUG(message) std::cout << "D [" << PLUGIN_PREFIX << "] " << message << std::endl;
#endif
#define PLUGIN_TIMER(__time, __msg) std::cout << "T [" << PLUGIN_PREFIX << "] [" << __time << "] " << __msg << std::endl;

#define PLUGIN_THROW(message)              \
    {                                      \
        PLUGIN_ERROR(message);             \
        throw std::runtime_error(message); \
    }
} // namespace blackhole
