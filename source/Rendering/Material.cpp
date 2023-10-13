#include "Rendering/Material.h"

Material::Material() {
	Transmission          = 0;
	Index_Of_Refraction   = 1.25;
	Refraction_Roughness  = 0.1;
	Reflection_Roughness  = 0.5;
	Reflection_Anisotropy = 0;
	Reflection_Rotation   = 0;
	Subsurface_Radius     = 0.1;
	Subsurface_IOR        = 1.3;
	Subsurface_Anisotropy = 0;
	Emissive_Strength     = 0;
	Iridescent            = 0;
	Iridescent_Roughness  = 0.25;
	Clearcoat_Roughness   = 0;
	Fuzz_Angle            = 10;
	Alpha                 = 1;

	Diffuse_Color         = dvec3( 1  , 1  , 1  );
	Reflective_Color      = dvec3( 1  , 1  , 1  );
	Refractive_Color      = dvec3( 1  , 1  , 1  );
	Subsurface_Color      = dvec3( 1  , 0  , 0  );
	Emissive_Color        = dvec3( 1  , 1  , 1  );
	Iridescent_Color_A    = dvec3( 1  , 0  , 0  );
	Iridescent_Color_B    = dvec3( 0  , 0  , 1  );
	Clearcoat_Color       = dvec3( 1  , 1  , 1  );
	Fuzz_Color            = dvec3( 0  , 1  , 0  );
}