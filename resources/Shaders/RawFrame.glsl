#version 460 core

uniform float iTime;
uniform uint  iFrame;
uniform vec2  iResolution;
uniform uint  iRenderMode;
uniform bool  iBidirectional;

uniform float iCameraFocalLength;
uniform float iCameraSensorWidth;
uniform vec3  iCameraPos;
uniform vec3  iCameraFront;
uniform vec3  iCameraUp;
uniform bool  iCameraChange;

uniform sampler2D iLastFrame;
uniform sampler2D iAlbedo;
uniform sampler2D iHdri;

in vec2 fragCoord;
in vec2 fragTexCoord;

out vec4 fragColor;

// DEFINITIONS ---------------------------------------------------------------------------------------

#define TWO_PI      6.28318530718
#define PI          3.14159265359
#define DEG_RAD     0.01745329252
#define M_E         2.71828182846

#define HDRI_STRENGTH 1.0
#define AO_LENGTH     1.0

#define MAX_DIST      5000.0
#define RAY_BOUNCES   32
#define SPP           1
#define SAMPLES       30

#define EPSILON       0.001

// CONSTANTS ---------------------------------------------------------------------------------------

const int Quad_Face[4] = int[](1,2,0,1);

// GLOBALS ---------------------------------------------------------------------------------------

uvec4 white_noise_seed;
uvec2 pixel;
vec3  rgb_noise;

// GENERIC FUNCTIONS ---------------------------------------------------------------------------------------

float cross2d( in vec2 a, in vec2 b ) { return a.x * b.y - a.y * b.x; }
vec4 conjugate(vec4 q) { return vec4(-q.x, -q.y, -q.z, q.w); }
float mapFloat(float FromMin, float FromMax, float ToMin, float ToMax, float Value) {
	if (Value > FromMax) return ToMax;
	else if (Value < FromMin) return ToMin;
	else return (ToMin + ((ToMax - ToMin) / (FromMax - FromMin)) * (Value - FromMin));
}

uvec4 hash(uvec4 seed) {
	seed = seed * 1664525u + 1013904223u;
	seed.x += seed.y*seed.w; seed.y += seed.z*seed.x; seed.z += seed.x*seed.y; seed.w += seed.y*seed.z;
	seed = seed ^ (seed>>16u);
	seed.x += seed.y*seed.w; seed.y += seed.z*seed.x; seed.z += seed.x*seed.y; seed.w += seed.y*seed.z;
	return seed;
}
float rand1() { return float(hash(white_noise_seed).x)   / float(0xffffffffu); }
float rand1r(float min_x, float max_x) { return mapFloat(0.0, 1.0, min_x, max_x, float(hash(white_noise_seed).x)   / float(0xffffffffu)); }
vec2  rand2() { return vec2 (hash(white_noise_seed).xy)  / float(0xffffffffu); }
vec3  rand3() { return vec3 (hash(white_noise_seed).xyz) / float(0xffffffffu); }
vec4  rand4() { return vec4 (hash(white_noise_seed))     / float(0xffffffffu); }
vec2 normaland2(float sigma, vec2 mean) {
	vec2 Z = rand2();
	return mean + sigma * sqrt(-2.0 * log(Z.x)) * vec2(cos(TWO_PI * Z.y), sin(TWO_PI * Z.y));
}
vec3 normaland3(float sigma, vec3 mean) {
	vec4 Z = rand4();
	return mean + sigma * sqrt(-2.0 * log(Z.xxy)) * vec3(cos(TWO_PI * Z.z), sin(TWO_PI * Z.z), cos(TWO_PI * Z.w));
}
void rng_initialize(vec2 pix, uint frame) {
	pixel = uvec2(pix);
	white_noise_seed = uvec4(pixel, frame, uint(pixel.x) + uint(pixel.y));
}

float snell (float sin_theta, float iori, float iort) {
	return iori / iort * sin_theta;
}
float fresnel(float iori, float iort, float cosi, float cost){
	float rpar = (iort * cosi - iori * cost) / (iort * cosi + iori * cost);
	float rper = (iori * cosi - iort * cost) / (iori * cosi + iort * cost);
	rpar *= rpar;
	rper *= rper;
	return (rpar + rper) / 2.;
}

mat3 eulerToRot(vec3 euler) {
	const float Yaw =   euler.x * DEG_RAD;
	const float Pitch = euler.y * DEG_RAD;
	const float Roll =  euler.z * DEG_RAD;

	const mat3 yawMat = mat3 (
		 cos(Yaw) , 0 , sin(Yaw) ,
		 0        , 1 , 0        ,
		-sin(Yaw) , 0 , cos(Yaw)
	);

	const mat3 pitchMat = mat3 (
		1 , 0          ,  0          ,
		0 , cos(Pitch) , -sin(Pitch) ,
		0 , sin(Pitch) ,  cos(Pitch)
	);

	const mat3 rollMat = mat3 (
		cos(Roll) , -sin(Roll) , 0 ,
		sin(Roll) ,  cos(Roll) , 0 ,
		0         ,  0         , 1
	);

	return pitchMat * yawMat * rollMat;
}

// STRUCTS ---------------------------------------------------------------------------------------

#define DIFFUSE  0
#define GLASS    1
#define EMISSIVE 2
#define TEXTURED 3

struct Material {
	int   Type;
	vec3  Color;
	float Emissive_Strength;
	float Roughness;
	float IOR;
};
struct Ray {
	vec3  Ray_Origin;
	vec3  Ray_Direction;
};
struct Hit {
	float Ray_Length;
	vec3  Hit_New_Dir;
	vec3  Hit_Pos;
	int   Hit_Obj;
	bool  Ray_Inside;
	Material Hit_Mat;
	vec2  Hit_UV;
};
struct Sphere {
	vec3     Position;
	float    Diameter;
	Material Mat;
};
struct Quad {
	vec3 v0;
	vec3 v1;
	vec3 v2;
	vec3 v3;
	Material Mat;
};
struct Tri {
	vec3     v0;
	vec3     v1;
	vec3     v2;
	Material Mat;
};

// SCENE ---------------------------------------------------------------------------------------
#define SPHERE_COUNT 6
#define QUAD_COUNT   7

const Sphere Scene_Spheres[SPHERE_COUNT] = Sphere[SPHERE_COUNT](
		// POSITION                      , RADIUS  ,          Type     , Color              , Emissiveness, Roughness, IOR
	Sphere(vec3( -1    ,  0.3   , -1    ), 0.2     , Material(DIFFUSE  , vec3(1  , 1  , 1  ), 0           , 1        , 1.2 )),
	Sphere(vec3( -1    ,  0.9   , -1    ), 0.2     , Material(DIFFUSE  , vec3(1  , 1  , 1  ), 0           , 0        , 1.2 )),
	Sphere(vec3( -1    ,  1.5   , -1    ), 0.2     , Material(GLASS    , vec3(1  , 1  , 1  ), 0           , 0        , 1.2 )),
	Sphere(vec3(  1    ,  0.3   , -1    ), 0.2     , Material(DIFFUSE  , vec3(1  , 0  , 0  ), 0           , 0        , 1.2 )),
	Sphere(vec3(  1    ,  0.9   , -1    ), 0.2     , Material(DIFFUSE  , vec3(0  , 1  , 0  ), 0           , 0.1      , 1.2 )),
	Sphere(vec3(  1    ,  1.5   , -1    ), 0.2     , Material(DIFFUSE  , vec3(0  , 0  , 1  ), 0           , 0        , 1.2 ))
);
const Quad Scene_Quads[QUAD_COUNT] = Quad[QUAD_COUNT](
	// VERT_A                    , VERT_B                  , VERT_C                  , VERT_D                  ,          Type     , Color              , Emissiveness, Roughness, IOR
	Quad(vec3( -2.66 , 0  , -15 ), vec3(  2.66 , 0  , -15 ), vec3(  2.66 , 0  ,  5  ), vec3( -2.66 , 0  ,  5  ), Material(DIFFUSE  , vec3(1  , 1  , 1  ), 0           , 1        , 1.0 )), // Floor
	Quad(vec3(  2.66 , 0  , -15 ), vec3(  2.66 , 0  ,  5  ), vec3(  2.66 , 3  ,  5  ), vec3(  2.66 , 3  , -15 ), Material(DIFFUSE  , vec3(1  , 1  , 1  ), 0           , 0.01     , 1.0 )), // Right Wall
	Quad(vec3( -2.66 , 0  , -15 ), vec3( -2.66 , 0  ,  5  ), vec3( -2.66 , 3  ,  5  ), vec3( -2.66 , 3  , -15 ), Material(DIFFUSE  , vec3(1  , 1  , 1  ), 0           , 0.01     , 1.0 )), // Left  Wall
	Quad(vec3( -2.66 , 0  , -15 ), vec3(  2.66 , 0  , -15 ), vec3(  2.66 , 3  , -15 ), vec3( -2.66 , 3  , -15 ), Material(TEXTURED , vec3(1  , 1  , 1  ), 0           , 1        , 1.0 )), // Back  Wall
	Quad(vec3( -2.66 , 3  , -15 ), vec3(  2.66 , 3  , -15 ), vec3(  2.66 , 3  ,  5  ), vec3( -2.66 , 3  ,  5  ), Material(DIFFUSE  , vec3(1  , 1  , 1  ), 0           , 1        , 1.0 )), // Ceiling
	Quad(vec3( -1.8  , 2.9, -10 ), vec3( -1    , 2.9, -10 ), vec3( -1    , 2.9,  3  ), vec3( -1.8  , 2.9,  3  ), Material(EMISSIVE , vec3(1  , 1  , 1  ), 2.5         , 1        , 1.0 )), // Light Right
	Quad(vec3(  1.8  , 2.9, -10 ), vec3(  1    , 2.9, -10 ), vec3(  1    , 2.9,  3  ), vec3(  1.8  , 2.9,  3  ), Material(EMISSIVE , vec3(1  , 1  , 1  ), 2.5         , 1        , 1.0 ))  // Light Left
);

// INTERSECTIONS ---------------------------------------------------------------------------------------

bool f_SphereIntersection(in Ray ray, in Sphere sphere, inout float ray_length) {
	ray.Ray_Origin = ray.Ray_Origin - sphere.Position;

	float b = dot(ray.Ray_Origin, ray.Ray_Direction);
	float delta = b * b - dot(ray.Ray_Origin, ray.Ray_Origin) + sphere.Diameter * sphere.Diameter;
	
	if (delta < 0) {
		return false;
	}
	float sqdelta = sqrt(delta);

	if (-b - sqdelta > EPSILON) {
		ray_length = -b - sqdelta;
		return true;
	}
	else if (-b + sqdelta > EPSILON) {
		ray_length = -b + sqdelta;
		return true;
	}
	return false;
}

bool f_QuadIntersection(in Ray ray, in Quad quad, inout float ray_length, out vec2 uv) {
	vec3 a = quad.v1 - quad.v0;
	vec3 b = quad.v3 - quad.v0;
	vec3 c = quad.v2 - quad.v0;
	vec3 p = ray.Ray_Origin - quad.v0;

	vec3 nor = cross(a,b);
	float t = -dot(p,nor)/dot(ray.Ray_Direction,nor);
	if( t < 0.0 ) return false;
	vec3 pos = p + t*ray.Ray_Direction;

	vec3 mor = abs(nor);
	int id = (mor.x>mor.y && mor.x>mor.z ) ? 0 : (mor.y>mor.z) ? 1 : 2;

	int idu = Quad_Face[id  ];
	int idv = Quad_Face[id+1];

	vec2 kp = vec2( pos[idu], pos[idv] );
	vec2 ka = vec2( a[idu], a[idv] );
	vec2 kb = vec2( b[idu], b[idv] );
	vec2 kc = vec2( c[idu], c[idv] );

	vec2 kg = kc-kb-ka;

	float k0 = cross2d( kp, kb );
	float k2 = cross2d( kc-kb, ka );
	float k1 = cross2d( kp, kg ) - nor[id];

	float u, v;
	if( abs(k2) < 0.00001) {
		v = -k0/k1;
		u = cross2d( kp, ka )/k1;
	}
	else {
		float w = k1*k1 - 4.0*k0*k2;
		if( w<0.0 ) return false;
		w = sqrt( w );

		float ik2 = 1.0/(2.0*k2);
		v = (-k1 - w)*ik2;
		if( v<0.0 || v>1.0 ) v = (-k1 + w)*ik2;
		u = (kp.x - ka.x*v)/(kb.x + kg.x*v);
	}
	if( u<0.0 || u>1.0 || v<0.0 || v>1.0) {
		return false;
	}
	else {
		ray_length = t;
		uv = vec2(v,1-u);
		return true;
	}
}

// FUNCTIONS ---------------------------------------------------------------------------------------

vec3 f_Hemisphere() {
	vec2 p = rand2();
	p = vec2(2. * PI * p.x, sqrt(p.y));
	return normalize(vec3(sin(p.x) * p.y, cos(p.x) * p.y, sqrt(1. - p.y * p.y)));
}

vec3 f_ConeRoughness(vec3 dir, float theta) {
	vec3 left = cross(dir, vec3(0., 1., 0.));
	left = length(left) > 0.1 ? normalize(left) : normalize(cross(dir, vec3(0., 0., 1.)));
	vec3 up = normalize(cross(dir, left));

	vec2 u = rand2();
	float cos_theta = (1. - u.x) + u.x * cos(theta);
	float sin_theta = sqrt(1. - cos_theta * cos_theta);
	float phi = u.y * 2.0 * PI;
	return normalize(
		left * cos(phi) * sin_theta +
		up   * sin(phi) * sin_theta +
		dir  * cos_theta);
}

Hit f_SceneIntersection(const in Ray ray) {
	Hit hit_data;
	hit_data.Ray_Length = MAX_DIST;
	vec2 uv = vec2(0);

	for (int i = 0; i < SPHERE_COUNT; i++) {
		float resultRayLength;
		if (f_SphereIntersection(ray, Scene_Spheres[i], resultRayLength)) {
			if(resultRayLength < hit_data.Ray_Length && resultRayLength > 0.001) {
				hit_data.Ray_Length = resultRayLength;
				hit_data.Hit_Pos = ray.Ray_Origin + ray.Ray_Direction * resultRayLength;
				hit_data.Hit_New_Dir = normalize(hit_data.Hit_Pos - Scene_Spheres[i].Position);
				hit_data.Hit_Mat = Scene_Spheres[i].Mat;
				hit_data.Hit_Obj = i;
				hit_data.Ray_Inside = distance(ray.Ray_Origin, Scene_Spheres[i].Position) <= Scene_Spheres[i].Diameter;
				if (hit_data.Ray_Inside) hit_data.Hit_New_Dir *= -1.0;
			}
		}
	}
	for (int i = 0; i < QUAD_COUNT; i++) {
		float resultRayLength;
		if (f_QuadIntersection(ray, Scene_Quads[i], resultRayLength, uv)) {
			if(resultRayLength < hit_data.Ray_Length && resultRayLength > 0.001) {
				hit_data.Ray_Length = resultRayLength;
				hit_data.Hit_Pos = ray.Ray_Origin + ray.Ray_Direction * resultRayLength;
				vec3 nor = normalize(cross(Scene_Quads[i].v2 - Scene_Quads[i].v1, Scene_Quads[i].v3 - Scene_Quads[i].v1));
				hit_data.Hit_New_Dir = faceforward( nor, ray.Ray_Direction, nor );
				hit_data.Hit_Mat = Scene_Quads[i].Mat;
				hit_data.Hit_UV = uv;
				hit_data.Hit_Obj = i + SPHERE_COUNT;
			}
		}
	}
	return hit_data;
}

vec3 f_EnvironmentHDR(in Ray r) {
	r.Ray_Direction = eulerToRot(vec3(0,-90,0)) * r.Ray_Direction;

	float phi = atan(r.Ray_Direction.y, r.Ray_Direction.x);
	float theta = acos(r.Ray_Direction.z);
	float u = phi / TWO_PI + 0.5;
	float v = theta / PI;

	return texture(iHdri, vec2(u,v)).rgb * HDRI_STRENGTH;
}

vec3 f_AmbientOcclusion(in Ray r) {
	float distPercent;
	for (int b = 0; b < 2; b++){
		Hit hit_data = f_SceneIntersection(r);
		if (hit_data.Ray_Length >= MAX_DIST) {
			return vec3(0.0); // MISS;
		}
		r.Ray_Direction = f_ConeRoughness(hit_data.Hit_New_Dir, 10.0);
		r.Ray_Origin = hit_data.Hit_Pos + r.Ray_Direction * EPSILON;
		distPercent = min(hit_data.Ray_Length / AO_LENGTH, 1.0);
	}
	return vec3(distPercent, distPercent, distPercent);
}

vec3 f_Radiance(in Ray r){
	vec3 rad = vec3(0);
	vec3 brdf = vec3(1);

	for (int b = 0; b < RAY_BOUNCES; b++) {
		Hit hit_data = f_SceneIntersection(r);

		if (hit_data.Ray_Length >= MAX_DIST) {
			return rad + brdf * f_EnvironmentHDR(r); // MISS;
		}
		if (hit_data.Hit_Mat.Type == DIFFUSE) {
			vec3 tangent = normalize(cross(r.Ray_Direction, hit_data.Hit_New_Dir));
			vec3 bitangent = normalize(cross(hit_data.Hit_New_Dir, tangent));
			vec3 normal = f_Hemisphere();
			r.Ray_Direction = normalize(mix(reflect(r.Ray_Direction, hit_data.Hit_New_Dir), normalize(tangent * normal.x + bitangent * normal.y + hit_data.Hit_New_Dir * normal.z), hit_data.Hit_Mat.Roughness));
			brdf *= hit_data.Hit_Mat.Color;
		}
		else if (hit_data.Hit_Mat.Type == TEXTURED) {
			vec3 tangent = normalize(cross(r.Ray_Direction, hit_data.Hit_New_Dir));
			vec3 bitangent = normalize(cross(hit_data.Hit_New_Dir, tangent));
			vec3 normal = f_Hemisphere();
			r.Ray_Direction = normalize(mix(reflect(r.Ray_Direction, hit_data.Hit_New_Dir), normalize(tangent * normal.x + bitangent * normal.y + hit_data.Hit_New_Dir * normal.z), hit_data.Hit_Mat.Roughness));
			return rad + brdf * texture(iAlbedo, hit_data.Hit_UV).rgb;
		}
		else if (hit_data.Hit_Mat.Type == GLASS) {
			float cosi = abs(dot(hit_data.Hit_New_Dir, r.Ray_Direction));
			float sini = sqrt(1. - cosi * cosi);
			float iort = hit_data.Hit_Mat.IOR;
			float iori = 1.0;
			if (hit_data.Ray_Inside){
				iori = iort;
				iort = 1.0;
			}
			float sint = snell(sini, iori, iort);
			float cost = sqrt(1.0 - sint * sint);
			float frsn = fresnel(iori, iort, cosi, cost);

			if (rand1() > frsn){
				vec3 bitangent = normalize(r.Ray_Direction - dot(hit_data.Hit_New_Dir, r.Ray_Direction) * hit_data.Hit_New_Dir);
				r.Ray_Direction = normalize(bitangent * sint - cost * hit_data.Hit_New_Dir);
				brdf *= hit_data.Hit_Mat.Color;
			}
			else {
				r.Ray_Direction = reflect(r.Ray_Direction, hit_data.Hit_New_Dir);
			}
		}
		else if (hit_data.Hit_Mat.Type == EMISSIVE) {
			return rad + brdf * hit_data.Hit_Mat.Color * hit_data.Hit_Mat.Emissive_Strength;
		}
		r.Ray_Origin = hit_data.Hit_Pos + r.Ray_Direction * EPSILON;
	}
	return rad;
}

vec3 f_ZDepth(in Ray r) {
	Hit hit_data = f_SceneIntersection(r);
	if (hit_data.Ray_Length >= MAX_DIST) {
		return vec3(0.0); // MISS;
	}
	return vec3(1 - min(hit_data.Ray_Length / 50.0, 0.9));
}

Ray f_CameraRay(vec2 uv) {
	vec3 projection_center = iCameraPos + iCameraFocalLength * iCameraFront;
	vec3 projection_u = normalize(cross(iCameraFront, iCameraUp)) * iCameraSensorWidth;
	vec3 projection_v = normalize(cross(projection_u, iCameraFront)) * (iCameraSensorWidth / 1.0);
	return Ray(iCameraPos, normalize(projection_center + (projection_u * uv.x) + (projection_v * uv.y) - iCameraPos) );
}

// Main ---------------------------------------------------------------------------------------
void main() {
	if (iFrame < SAMPLES) {
		rng_initialize(gl_FragCoord.xy, iFrame);
		const vec2 uv = (gl_FragCoord.xy - 1.0 - iResolution.xy /2.0) / max(iResolution.x, iResolution.y);
		const vec2 pixel_size = 1/ iResolution.xy;

		// -------------------------- Ambient Occlusion
		if (iRenderMode == 0) {
			vec3 col;
			for (int x = 0; x < SPP; x++) {
				for (int y = 0; y < SPP; y++) {
					vec2 subpixelUV = uv - (vec2(0.5) * pixel_size) + (vec2(float(x) / float(SPP), float(y) / float(SPP)) * pixel_size);
					col += f_AmbientOcclusion(f_CameraRay(subpixelUV));
				}
			}
			col /= float(SPP * SPP);
			fragColor = vec4(col , 1);
		}
		// -------------------------- PathTracer
		else if (iRenderMode == 1) {
			vec3 col;
			for (int x = 0; x < SPP; x++) {
				for (int y = 0; y < SPP; y++) {
					vec2 subpixelUV = uv - (vec2(0.5) * pixel_size) + (vec2(float(x) / float(SPP), float(y) / float(SPP)) * pixel_size);
					col += f_Radiance(f_CameraRay(subpixelUV));
				}
			}

			col /= float(SPP * SPP);
			fragColor = vec4(col, 1);
		}
		// -------------------------- Z-Depth
		else if (iRenderMode == 2) {
			fragColor = vec4(f_ZDepth(f_CameraRay(uv)) , 1);
		}
	}
	else {
		fragColor = texture(iLastFrame, fragTexCoord);
	}
}