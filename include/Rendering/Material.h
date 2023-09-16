#pragma once

#include "Include.h"

struct Material {
	double Transmission;
	double Index_Of_Refraction;
	double Refraction_Roughness;
	double Reflection_Roughness;
	double Reflection_Anisotropy;
	double Reflection_Rotation;
	double Subsurface_Radius;
	double Subsurface_IOR;
	double Subsurface_Anisotropy;
	double Emissive_Strength;
	double Iridescent;
	double Iridescent_Roughness;
	double Clearcoat_Roughness;
	double Fuzz_Angle;
	double Alpha;

	dvec3 Diffuse_Color;
	dvec3 Reflective_Color;
	dvec3 Refractive_Color;
	dvec3 Subsurface_Color;
	dvec3 Emissive_Color;
	dvec3 Iridescent_Color_A;
	dvec3 Iridescent_Color_B;
	dvec3 Clearcoat_Color;
	dvec3 Fuzz_Color;

	Material();
};