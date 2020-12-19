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

#include "BlackHoleRenderer.h"

// ospray
#include <ospray/SDK/lights/Light.h>

// ispc exports
#include "BlackHoleRenderer_ispc.h"

using namespace ospray;

namespace blackhole
{
void BlackHoleRenderer::commit()
{
    Renderer::commit();

    _bgMaterial = (brayns::obj::BlackHoleMaterial *)getParamObject("bgMaterial", nullptr);

    _lightData = (ospray::Data *)getParamData("lights");
    _lightArray.clear();

    if (_lightData)
        for (size_t i = 0; i < _lightData->size(); ++i)
            _lightArray.push_back(((ospray::Light **)_lightData->data)[i]->getIE());

    _lightPtr = _lightArray.empty() ? nullptr : &_lightArray[0];

    _exposure = getParam1f("exposure", 1.f);
    _timestamp = getParam1f("timestamp", 0.f);
    _grid = getParam("grid", false);

    _nbDisks = getParam1i("nbDisks", 20);
    _diskRotationSpeed = getParam1f("diskRotationSpeed", 3.f);
    _diskTextureLayers = getParam1i("diskTextureLayers", 12);
    _blackHoleSize = getParam1f("blackHoleSize", 0.3f);
    // Renderer
    ispc::BlackHoleRenderer_set(getIE(), (_bgMaterial ? _bgMaterial->getIE() : nullptr), _timestamp, spp, _lightPtr, _lightArray.size(),
                                _exposure, _nbDisks, _grid, _diskRotationSpeed, _diskTextureLayers, _blackHoleSize);
}

BlackHoleRenderer::BlackHoleRenderer()
{
    ispcEquivalent = ispc::BlackHoleRenderer_create(this);
}

OSP_REGISTER_RENDERER(BlackHoleRenderer, black_hole_renderer);
} // namespace blackhole
