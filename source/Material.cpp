#include "Material.h"

Material::Material() {
	Diffuse_Gain          = 1;
	Diffuse_Roughness     = 0;
	Specular_Gain         = 0.5;
	Specular_Rougness     = 0.2;
	Specular_Anisotropy   = 0;
	Refraction_Gain       = 0;
	Reflection_Gain       = 0;
	Refraction_IOR        = 1.25;
	Reflection_IOR        = 1.25;
	Refraction_Roughness  = 0.1;
	Reflection_Roughness  = 0.1;
	Subsurface_Gain       = 0;
	Subsurface_Radius     = 0.1;
	Subsurface_IOR        = 1.3;
	Subsurface_Anisotropy = 0;
	Emmisive_Gain         = 0;
	Iridescent_Gain       = 0;
	Iridescent_Roughness  = 0.1;
	Clearcoat_Gain        = 0;
	Clearcoat_Roughness   = 0.1;
	Fuzz_Gain             = 0;
	Fuzz_Angle            = 10;
	Diffuse_Color         = dvec3(1, 1, 1);
	Specular_Face_Color   = dvec3(1, 1, 1);
	Specular_Edge_Color   = dvec3(1, 1, 1);
	Refractive_Color      = dvec3(1, 1, 1);
	Reflective_Color      = dvec3(1, 1, 1);
	Subsurface_Color      = dvec3(1, 1, 1);
	Emmisive_Color        = dvec3(1, 1, 1);
	Iridescent_Color_A    = dvec3(1, 1, 1);
	Iridescent_Color_B    = dvec3(1, 1, 1);
	Clearcoat_Color       = dvec3(1, 1, 1);
	Fuzz_Color            = dvec3(1, 1, 1);
}