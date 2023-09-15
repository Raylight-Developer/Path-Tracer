#pragma once

#include "Include.h"

struct Material {
	double
		Diffuse_Gain,
		Diffuse_Roughness,

		Specular_Gain,
		Specular_Rougness,
		Specular_Anisotropy,

		Refraction_Gain,
		Reflection_Gain,
		Refraction_IOR,
		Reflection_IOR,
		Refraction_Roughness,
		Reflection_Roughness,

		Subsurface_Gain,
		Subsurface_Radius,
		Subsurface_IOR,
		Subsurface_Anisotropy,

		Emissive_Gain,

		Iridescent_Gain,
		Iridescent_Roughness,

		Clearcoat_Gain,
		Clearcoat_Roughness,

		Fuzz_Gain,
		Fuzz_Angle;

	dvec3
		Diffuse_Color,

		Specular_Face_Color,
		Specular_Edge_Color,

		Refractive_Color,
		Reflective_Color,

		Subsurface_Color,

		Emissive_Color,

		Iridescent_Color_A,
		Iridescent_Color_B,

		Clearcoat_Color,

		Fuzz_Color;

	Material();
};