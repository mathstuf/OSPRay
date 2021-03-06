// ======================================================================== //
// Copyright 2009-2016 Intel Corporation                                    //
//                                                                          //
// Licensed under the Apache License, Version 2.0 (the "License");          //
// you may not use this file except in compliance with the License.         //
// You may obtain a copy of the License at                                  //
//                                                                          //
//     http://www.apache.org/licenses/LICENSE-2.0                           //
//                                                                          //
// Unless required by applicable law or agreed to in writing, software      //
// distributed under the License is distributed on an "AS IS" BASIS,        //
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. //
// See the License for the specific language governing permissions and      //
// limitations under the License.                                           //
// ======================================================================== //

#include "Material.ih"
#include "../bsdfs/Lambert.ih"
#include "../bsdfs/DielectricLayer.ih"
#include "../bsdfs/MicrofacetDielectricLayer.ih"

struct Plastic
{
  PathTraceMaterial super;
  vec3f pigmentColor;
  float eta;
  float roughness;
  float thickness;
};

///////////////////////////////////////////////////////////////////////////////
// Implementation

const varying BSDF* uniform Plastic_getBSDF(const uniform PathTraceMaterial* uniform super,
                                            uniform ShadingContext* uniform ctx,
                                            const DifferentialGeometry& dg,
                                            const Ray& ray,
                                            const Medium& currentMedium)
{
  const uniform Plastic* uniform self = (const uniform Plastic* uniform)super;

  varying LinearSpace3f* uniform shadingFrame = LinearSpace3f_create(ctx, frame(dg.Ns));
  varying BSDF* uniform bsdf = Lambert_create(ctx, shadingFrame, self->pigmentColor);

  if (self->roughness == 0.0f)
    bsdf = DielectricLayer_create(ctx, shadingFrame, bsdf, self->eta, make_vec3f(1.0f), 1.0f);
  else
    bsdf = MicrofacetDielectricLayer_create(ctx, shadingFrame, bsdf, self->eta, make_vec3f(1.0f), 1.0f, self->roughness);

  return bsdf;
}

void Plastic_Constructor(uniform Plastic* uniform self,
                         const uniform vec3f& pigmentColor,
                         uniform float ior,
                         uniform float roughness,
                         uniform float thickness)
{
  PathTraceMaterial_Constructor(&self->super, Plastic_getBSDF, NULL, NULL);
  self->pigmentColor = pigmentColor;
  self->eta = rcp(ior);
  self->roughness = roughness;
  self->thickness = thickness;
}

///////////////////////////////////////////////////////////////////////////////
// External API

export void* uniform PathTracer_Plastic_create(const uniform vec3f& pigmentColor,
                                               uniform float ior,
                                               uniform float roughness,
                                               uniform float thickness)
{
  uniform Plastic* uniform self = uniform new uniform Plastic;
  Plastic_Constructor(self, pigmentColor, ior, roughness, thickness);
  return self;
}
