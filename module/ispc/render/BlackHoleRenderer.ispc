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

#include "BlackHoleRenderer.ih"

// https://www.shadertoy.com/view/tsBXW3


inline float mix(float x, float y, float a)
{
    return x * (1.f - a) + y * a;
}

inline vec3f mix(vec3f x, vec3f y, float a)
{
    return x * (1.f - a) + y * a;
}

inline vec3f mix(vec3f x, vec3f y, vec3f a)
{
    return x * (1.f - a) + y * a;
}

inline vec3f mod(vec3f v, int m)
{
    return make_vec3f(v.x - m * floor(v.x / m), v.y - m * floor(v.y / m),
                      v.z - m * floor(v.z / m));
}

inline float mod(float v, float u)
{
    return v - u * floor(v / u);
}

inline float hash(float x)
{
    return frac(sin(x)*152754.742);
}

inline float hash(const vec2f& x)
{
    return hash(x.x + hash(x.y));
}

inline float value(const vec2f& p, float f) //value noise
{
    float bl = hash(floor(p*f + make_vec2f(0.,0.)));
    float br = hash(floor(p*f + make_vec2f(1.,0.)));
    float tl = hash(floor(p*f + make_vec2f(0.,1.)));
    float tr = hash(floor(p*f + make_vec2f(1.,1.)));
    
    vec2f fr = frac(p*f);    
    fr = (3. - 2.*fr)*fr*fr;	
    float b = mix(bl, br, fr.x);	
    float t = mix(tl, tr, fr.x);
    return  mix(b,t, fr.y);
}

vec4f skyboxMapping(const uniform BlackHoleRenderer* uniform self,
                    const varying Ray& ray)
{
    varying vec4f result = make_vec4f(self->bgMaterial->Kd);

    const varying float radius = 1e6;
    if (!valid(self->bgMaterial->map_Kd))
        return result;

    // solve the equation sphere-ray to find the intersections
    const varying float a = 2.f * dot(ray.dir, ray.dir);
    const varying float b = 2.f * dot(ray.org, ray.dir);
    const varying float c = dot(ray.org, ray.org) - radius * radius;
    const varying float d = b * b - 2.f * a * c;

    if (d <= 0.f || a == 0.f)
        return result;

    const varying float r = sqrt(d);
    const varying float t1 = (-b - r) / a;
    const varying float t2 = (-b + r) / a;

    const varying float epsilon = 0.00001f;
    if (t1 <= epsilon && t2 <= epsilon)
        return result; // both intersections are behind the ray origin

    varying float t = 0.f;
    if (t1 <= epsilon)
        t = t2;
    else if (t2 <= epsilon)
        t = t1;
    else
        t = (t1 < t2) ? t1 : t2;

    if (t < epsilon || t > ray.t)
        return result; // Too close to intersection

    const varying vec3f intersection = normalize(ray.org + t * ray.dir);

    // Only st needs to be set to sample from Texture2D
    varying DifferentialGeometry dg;
    dg.st =
        make_vec2f(((atan2(-intersection.x, intersection.z) / PI) + 1.f) * .5f,
                   (asin(intersection.y) / PI) + .5f);

    return get4f(self->bgMaterial->map_Kd.map, dg);
}

vec4f raymarchDisk(const uniform BlackHoleRenderer* uniform self, const vec3f& dir, const vec3f& zeroPos, const float timestamp)
{
    //return vec4(1.,1.,1.,0.); //no disk
    
	vec3f position = zeroPos;      
    float lengthPos = length(make_vec3f(position.x, position.z, 0.f));
    float dist = min(1., lengthPos*(1./self->blackHoleSize) *0.5) * self->blackHoleSize * 0.4 *(1./self->diskTextureLayers) /( abs(dir.y) );

    position = position + dist * self->diskTextureLayers * dir * 0.5;     

    vec3f deltaPos = make_vec3f(0.f);
    deltaPos.x = -zeroPos.z * 0.01 + zeroPos.x;
    deltaPos.y = zeroPos. x * 0.01 + zeroPos.z;
    deltaPos = normalize(deltaPos - make_vec3f(zeroPos.x, zeroPos.z, 0.f));
    
    float parallel = dot(make_vec3f(dir.x, dir.z, 0.f), deltaPos);
    parallel = parallel / sqrt(lengthPos);
    parallel = parallel * 0.5;
    float redShift = parallel + 0.3;
    redShift = redShift * redShift;

    redShift = clamp(redShift, 0., 1.);
    
    float disMix = clamp((lengthPos - self->blackHoleSize * 2.)*(1./self->blackHoleSize)*0.24, 0., 1.);
    vec3f insideCol =  mix(make_vec3f(1.0,0.8,0.0), make_vec3f(0.5,0.13,0.02) * 0.2, disMix);
    
    insideCol = insideCol * mix(make_vec3f(0.4, 0.2, 0.1), make_vec3f(1.6, 2.4, 4.0), redShift);
	insideCol = insideCol * 1.25;
    redShift += 0.12;
    redShift *= redShift;

    vec4f o = make_vec4f(0.);

    for(float i = 0. ; i < self->diskTextureLayers; i++)
    {                      
        position = position - dist * dir ;  

        float intensity =clamp( 1. - abs((i - 0.8) * (1./self->diskTextureLayers) * 2.), 0., 1.); 
        float lengthPos = length(make_vec3f(position.x, position.z, 0.f));
        float distMult = 1.;

        distMult *= clamp((lengthPos -  self->blackHoleSize * 0.75) * (1./self->blackHoleSize) * 1.5, 0., 1.);        
        distMult *= clamp(( self->blackHoleSize * 10. -lengthPos) * (1./self->blackHoleSize) * 0.20, 0., 1.);
        distMult *= distMult;

        float u = lengthPos + timestamp * self->blackHoleSize * 0.3 + intensity * self->blackHoleSize * 0.2;

        vec2f xy ;
        float rot = mod( timestamp * self->diskRotationSpeed, 8192. );
        xy.x = -position.z * sin(rot) + position.x * cos(rot);
        xy.y = position.x * sin(rot) + position.z * cos(rot);

        float x = abs( xy.x/(xy.y));         
		float angle = 0.02 * atan(x);
  
        const float f = 70.;
        float noise = value( make_vec2f( angle, u * (1./self->blackHoleSize) * 0.05), f);
        noise = noise*0.66 + 0.33*value( make_vec2f( angle, u * (1./self->blackHoleSize) * 0.05), f*2.);     

        float extraWidth =  noise * 1. * (1. -  clamp(i * (1./self->diskTextureLayers)*2. - 1., 0., 1.));

        float alpha = clamp(noise*(intensity + extraWidth)*( (1./self->blackHoleSize) * 10.  + 0.01 ) *  dist * distMult , 0., 1.);

        vec3f col = 2. * mix( make_vec3f(0.3, 0.2, 0.15) * insideCol, insideCol, min( 1., intensity * 2.));

        const vec3f t = col * alpha + make_vec3f(o) * (1. - alpha);
        o = make_vec4f(clamp(t, make_vec3f(0.), make_vec3f(1.)), o.w * (1. - alpha) + alpha);

        lengthPos *= (1./self->blackHoleSize);
   
        o = o + make_vec4f(make_vec3f(redShift*(intensity*1. + 0.5) * (1./self->diskTextureLayers) * 100. * distMult/(lengthPos*lengthPos)), 0.f);
    }  
 
    o = make_vec4f(clamp(make_vec3f(o) - 0.005, make_vec3f(0.), make_vec3f(1.)), o.w);
    return o ;
}

inline void composite(const varying vec4f& src, varying vec4f& dst,
                      const varying float alphaCorrection)
{
    const float alpha =
        1.f - pow(1.f - min(src.w, 1.f - 1.f / 256.f), alphaCorrection);
    const float a = alpha * (1.f - dst.w);
    dst.x = dst.x + src.x * a;
    dst.y = dst.y + src.y * a;
    dst.z = dst.z + src.z * a;
    dst.w += (alpha * (1.f - dst.w));
}

inline vec3f BlackHoleRenderer_shadeRay(
    const uniform BlackHoleRenderer* uniform self,
    varying ScreenSample& sample)
{
    vec4f colOut = make_vec4f(0.f);
    vec4f outCol = make_vec4f(0.f);
    vec4f glow = make_vec4f(0.);
    vec4f col = make_vec4f(0.); 

    if (sample.sampleID.z == 0)
    {
        sample.alpha = 0.f;
        sample.z = inf;
    }

    vec3f pos = sample.ray.org;
    vec3f dir = sample.ray.dir;

    for(int disks = 0; disks < self->nbDisks; disks++) //steps
    {
        for (int h = 0; h < 6; h++) //reduces tests for exit conditions (to minimise branching)
        {
            float dotpos = dot(pos,pos);
            float invDist = sqrt(1. / dotpos); //1/distance to BH
            float centDist = dotpos * invDist; 	//distance to BH
            float stepDist = 0.92 * abs(pos.y /(dir.y));  //conservative distance to disk (y==0)   
            float farLimit = centDist * 0.5; //limit step size far from to BH
            float closeLimit = centDist*0.1 + 0.05*centDist*centDist*(1./self->blackHoleSize); //limit step size closse to BH
            stepDist = min(stepDist, min(farLimit, closeLimit));
            
            float invDistSqr = invDist * invDist;
            float bendForce = stepDist * invDistSqr * self->blackHoleSize * 0.625;  //bending force
            dir =  normalize(dir - (bendForce * invDist )*pos);  //bend ray towards BH
            pos = pos + stepDist * dir; 
            
            glow = glow + make_vec4f(1.2,1.1,1, 1.0) *(0.01*stepDist * invDistSqr * invDistSqr *clamp( centDist*(2.) - 1.2,0.,1.)); //adds fairly cheap glow
        }

        float dist2 = length(pos);

        if(dist2 < self->blackHoleSize * 0.1) //ray sucked in to BH
        {
            outCol =  make_vec4f(make_vec3f(col) * col.w + make_vec3f(glow) * (1. - col.w), 1.) ;
            break;
        }

        else if(dist2 > self->blackHoleSize * 1000.) //ray escaped BH
        {   
            vec4f bg;
            if(self->grid)
            {
                bg = make_vec4f(
                    (int)((pos.x + 1000.f) * 0.01f) % 2 == 0 ? 1.f : 0.5f,
                    (int)((pos.y + 1000.f) * 0.01f) % 2 == 0 ? 1.f : 0.5f,
                    (int)((pos.z + 1000.f) * 0.01f) % 2 == 0 ? 1.f : 0.f, 0.5f);
            }
            else
            {
                Ray envRay = sample.ray;

                envRay.org = pos;
                envRay.dir = dir;
                bg = skyboxMapping(self, envRay);
            }
            outCol = make_vec4f(make_vec3f(col) * col.w + make_vec3f(bg) * (1. - col.w) + make_vec3f(glow) * (1. - col.w), 1.);       
            break;
        }

        else if (abs(pos.y) <= self->blackHoleSize * 0.002 ) //ray hit accretion disk
        {                             
            vec4f diskCol = raymarchDisk(self, dir, pos, self->timestamp);   //render disk
            pos.y = 0.;
            pos = pos + abs(self->blackHoleSize * 0.001 / dir.y) * dir;
            col = make_vec4f(make_vec3f(diskCol) * (1. - col.w) + make_vec3f(col), col.w + diskCol.w * (1. - col.w));
        }	
    }

    //if the ray never escaped or got sucked in
    if(outCol.x == 100.)
        outCol = make_vec4f(make_vec3f(col) + make_vec3f(glow) * (col.w +  glow.w) , 1.);

    return clamp(make_vec3f(outCol * self->exposure), make_vec3f(0.f), make_vec3f(1.f));
}

void BlackHoleRenderer_renderSample(uniform Renderer* uniform _self,
                                        void* uniform perFrameData,
                                        varying ScreenSample& sample)
{
    uniform BlackHoleRenderer* uniform self =
        (uniform BlackHoleRenderer * uniform) _self;
    sample.ray.time = 0.f;
    sample.rgb = BlackHoleRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform BlackHoleRenderer_create(void* uniform cppE)
{
    uniform BlackHoleRenderer* uniform self =
        uniform new uniform BlackHoleRenderer;
    Renderer_Constructor(&self->super, cppE);
    self->super.renderSample = BlackHoleRenderer_renderSample;
    return self;
}

export void BlackHoleRenderer_set(
    void* uniform _self, void* uniform bgMaterial, 
    const uniform float timestamp, const uniform int spp,
    void** uniform lights, const uniform int32 numLights,
    const uniform float exposure, const uniform int nbDisks,
    const uniform bool grid, const uniform float diskRotationSpeed,
    const uniform uint32 diskTextureLayers, const uniform float blackHoleSize)
{
    uniform BlackHoleRenderer* uniform self =
        (uniform BlackHoleRenderer * uniform) _self;

    self->bgMaterial = (uniform BlackHoleMaterial * uniform) bgMaterial;

    // OSPRay
    self->super.spp = spp;
    self->timestamp = timestamp;

    self->lights = (const uniform Light* uniform* uniform)lights;
    self->numLights = numLights;

    self->exposure = exposure;
    self->nbDisks = nbDisks;
    self->grid = grid;
    self->diskRotationSpeed = diskRotationSpeed;
    self->diskTextureLayers = diskTextureLayers;
    self->blackHoleSize = blackHoleSize;
}
