/* Copyright (c) 2020, EPFL/Blue Brain Project
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@epfl.ch>
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 3.0 as published
 * by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "BlackHolePlugin.h"

#include <plugin/common/Logs.h>

#include <brayns/common/ActionInterface.h>
#include <brayns/engineapi/Engine.h>
#include <brayns/parameters/ParametersManager.h>
#include <brayns/pluginapi/Plugin.h>

namespace blackhole
{
using namespace brayns;

const std::string PLUGIN_VERSION = "0.1.0";
const std::string PLUGIN_API_PREFIX = "bh_";

#define CATCH_STD_EXCEPTION()                  \
    catch (const std::runtime_error &e)        \
    {                                          \
        response.status = false;               \
        response.contents = e.what();          \
        PLUGIN_ERROR << e.what() << std::endl; \
    }

void _addBlackHoleRenderer(brayns::Engine &engine)
{
    PLUGIN_INFO << "Registering 'black_hole_renderer' renderer" << std::endl;
    brayns::PropertyMap properties;
    properties.setProperty({"exposure", 1., 1., 10., {"Exposure"}});
    properties.setProperty({"nbDisks", 20, 2, 128, {"Number of disks"}});
    properties.setProperty({"grid", false, {"Display grid"}});
    properties.setProperty({"timestamp", 0., 0., 8192., {"Timestamp"}});
    properties.setProperty({"diskRotationSpeed", 3., 1., 10., {"Disk rotation speed"}});
    properties.setProperty({"diskTextureLayers", 12, 2, 100, {"Disk texture layers"}});
    properties.setProperty({"blackHoleSize", 0.3, 0.1, 10., {"Black hole size"}});
    engine.addRendererType("black_hole_renderer", properties);
}

BlackHolePlugin::BlackHolePlugin()
    : ExtensionPlugin()
{
}

void BlackHolePlugin::init()
{
    auto actionInterface = _api->getActionInterface();
    auto &engine = _api->getEngine();

    if (actionInterface)
    {
        std::string entryPoint = PLUGIN_API_PREFIX + "version";
        PLUGIN_INFO << "Registering '" + entryPoint + "' endpoint" << std::endl;
        actionInterface->registerRequest<Response>(entryPoint, [&]() { return _version(); });
    }

    _addBlackHoleRenderer(engine);
    _api->getParametersManager().getRenderingParameters().setCurrentRenderer("black_hole_renderer");
}

Response BlackHolePlugin::_version() const
{
    Response response;
    response.contents = PLUGIN_VERSION;
    return response;
}

extern "C" ExtensionPlugin *brayns_plugin_create(int argc, char **argv)
{
    PLUGIN_INFO << std::endl;
    PLUGIN_INFO << "_|_|_|    _|                      _|            _|    _|            _|            " << std::endl;
    PLUGIN_INFO << "_|    _|  _|    _|_|_|    _|_|_|  _|  _|        _|    _|    _|_|    _|    _|_|    " << std::endl;
    PLUGIN_INFO << "_|_|_|    _|  _|    _|  _|        _|_|          _|_|_|_|  _|    _|  _|  _|_|_|_|  " << std::endl;
    PLUGIN_INFO << "_|    _|  _|  _|    _|  _|        _|  _|        _|    _|  _|    _|  _|  _|        " << std::endl;
    PLUGIN_INFO << "_|_|_|    _|    _|_|_|    _|_|_|  _|    _|      _|    _|    _|_|    _|    _|_|_|  " << std::endl;
    PLUGIN_INFO << std::endl;
    PLUGIN_INFO << "Initializing Black Hole plug-in (version " << PLUGIN_VERSION << ")" << std::endl;
    PLUGIN_INFO << std::endl;

    return new BlackHolePlugin();
}

} // namespace blackhole
