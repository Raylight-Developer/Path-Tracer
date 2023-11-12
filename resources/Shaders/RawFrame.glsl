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
uniform sampler2D iTextures;
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

#define MAX_DIST      5000.0
#define RAY_BOUNCES   4
#define SPP           1
#define SAMPLES       32

#define EPSILON       0.001

// CONSTANTS ---------------------------------------------------------------------------------------

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

#define SEA_LANTERN       1
#define PRISMARINE_BRICKS 2
#define MAGMA_BLOCK       3
#define GRAVEL            4
#define GOLD              5
#define DARK_PRISMARINE   6
#define GLASS             7
#define CORAL             8
#define KELP              9

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
	int   Hit_Mat;
	vec2  Hit_UV;
};
struct Cube {
	vec3 Position;
	int  Mat;
};
struct BOX{
	vec3 Position;
	vec3 Size;
	int  Mat;
};
struct Sphere {
	vec3  Position;
	float Diameter;
	int   Mat;
};

// SCENE ---------------------------------------------------------------------------------------
#define SPHERE_COUNT 1
#define LIGHTS_COUNT 4
#define GLASS_COUNT 5
#define DARK_PRISMARINE_COUNT (30 * 2 + 28 * 2) *2 + ( 28 * 2 + 26 * 2) * 2 + (12 * 4) + (12 * 4)

const Sphere Scene_Spheres[SPHERE_COUNT] = Sphere[SPHERE_COUNT](
	Sphere(vec3( 0 , 50 , 0 ), 15, GLASS)
);

const Cube Scene_Lights[LIGHTS_COUNT] = Cube[LIGHTS_COUNT](
	Cube(vec3(  13.5 , 14 ,  13.5 ), SEA_LANTERN),
	Cube(vec3(  13.5 , 14 , -13.5 ), SEA_LANTERN),
	Cube(vec3( -13.5 , 14 ,  13.5 ), SEA_LANTERN),
	Cube(vec3( -13.5 , 14 , -13.5 ), SEA_LANTERN)
);

const BOX Scene_Glass[GLASS_COUNT] = BOX[GLASS_COUNT](
	BOX(vec3(  0    , 0   ,  0    ), vec3( 13 , 0.5 , 13  ), GLASS),
	BOX(vec3(  13.5 , 6.5 ,  0    ), vec3( 0.1 , 6  , 13  ), GLASS),
	BOX(vec3( -13.5 , 6.5 ,  0    ), vec3( 0.1 , 6  , 13  ), GLASS),
	BOX(vec3(  0    , 6.5 ,  13.5 ), vec3( 13  , 6  , 0.1 ), GLASS),
	BOX(vec3(  0    , 6.5 , -13.5 ), vec3( 13  , 6  , 0.1 ), GLASS)
);

const Cube Scene_Frame[DARK_PRISMARINE_COUNT] = Cube[DARK_PRISMARINE_COUNT](
	// Bottom --------------------------------
	Cube(vec3( -14.5 , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -12.5 , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -11.5 , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -10.5 , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -9.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -8.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -7.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -6.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -5.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -4.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -3.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -2.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -1.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -0.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  0.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  1.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  2.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  3.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  4.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  5.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  6.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  7.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  8.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  9.5  , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  10.5 , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  11.5 , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  12.5 , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  14.5 ), DARK_PRISMARINE),
	//
	Cube(vec3( -14.5 , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -12.5 , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -11.5 , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -10.5 , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -9.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -8.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -7.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -6.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -5.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -4.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -3.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -2.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -1.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -0.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  0.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  1.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  2.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  3.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  4.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  5.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  6.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  7.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  8.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  9.5  , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  10.5 , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  11.5 , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  12.5 , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -14.5 ), DARK_PRISMARINE),
	//
	Cube(vec3(  14.5 , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -12.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -11.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -10.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -9.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -8.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -7.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -6.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -5.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -4.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -3.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -2.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -1.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  , -0.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  0.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  1.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  2.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  3.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  4.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  5.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  6.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  7.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  8.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  9.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  10.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  11.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  12.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 0  ,  13.5 ), DARK_PRISMARINE),
	//
	Cube(vec3( -14.5 , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -12.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -11.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -10.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -9.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -8.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -7.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -6.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -5.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -4.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -3.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -2.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -1.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  , -0.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  0.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  1.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  2.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  3.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  4.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  5.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  6.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  7.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  8.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  9.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  10.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  11.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  12.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 0  ,  13.5 ), DARK_PRISMARINE),
	// TOP --------------------------------------
	Cube(vec3( -14.5 , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -12.5 , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -11.5 , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -10.5 , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -9.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -8.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -7.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -6.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -5.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -4.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -3.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -2.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -1.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -0.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  0.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  1.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  2.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  3.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  4.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  5.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  6.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  7.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  8.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  9.5  , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  10.5 , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  11.5 , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  12.5 , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  14.5 ), DARK_PRISMARINE),
	//
	Cube(vec3( -14.5 , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -12.5 , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -11.5 , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -10.5 , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -9.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -8.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -7.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -6.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -5.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -4.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -3.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -2.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -1.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -0.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  0.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  1.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  2.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  3.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  4.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  5.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  6.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  7.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  8.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  9.5  , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  10.5 , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  11.5 , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  12.5 , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -14.5 ), DARK_PRISMARINE),
	//
	Cube(vec3(  14.5 , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -12.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -11.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -10.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -9.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -8.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -7.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -6.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -5.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -4.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -3.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -2.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -1.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 , -0.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  0.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  1.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  2.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  3.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  4.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  5.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  6.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  7.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  8.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  9.5  ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  10.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  11.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  12.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 13 ,  13.5 ), DARK_PRISMARINE),
	//
	Cube(vec3( -14.5 , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -12.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -11.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -10.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -9.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -8.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -7.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -6.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -5.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -4.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -3.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -2.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -1.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 , -0.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  0.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  1.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  2.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  3.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  4.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  5.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  6.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  7.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  8.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  9.5  ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  10.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  11.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  12.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 13 ,  13.5 ), DARK_PRISMARINE),
// Bottom --------------------------------
	Cube(vec3( -13.5 , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -12.5 , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -11.5 , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -10.5 , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -9.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -8.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -7.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -6.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -5.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -4.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -3.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -2.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -1.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -0.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  0.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  1.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  2.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  3.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  4.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  5.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  6.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  7.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  8.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  9.5  , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  10.5 , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  11.5 , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  12.5 , 0  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  13.5 ), DARK_PRISMARINE),
	//
	Cube(vec3( -13.5 , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -12.5 , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -11.5 , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -10.5 , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -9.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -8.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -7.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -6.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -5.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -4.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -3.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -2.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -1.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -0.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  0.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  1.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  2.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  3.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  4.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  5.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  6.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  7.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  8.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  9.5  , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  10.5 , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  11.5 , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  12.5 , 0  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -13.5 ), DARK_PRISMARINE),
	// 
	Cube(vec3(  13.5 , 0  , -12.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -11.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -10.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -9.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -8.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -7.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -6.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -5.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -4.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -3.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -2.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -1.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  , -0.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  0.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  1.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  2.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  3.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  4.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  5.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  6.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  7.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  8.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  9.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  10.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  11.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 0  ,  12.5 ), DARK_PRISMARINE),
	//
	Cube(vec3( -13.5 , 0  , -12.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -11.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -10.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -9.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -8.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -7.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -6.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -5.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -4.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -3.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -2.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -1.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  , -0.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  0.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  1.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  2.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  3.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  4.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  5.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  6.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  7.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  8.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  9.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  10.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  11.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 0  ,  12.5 ), DARK_PRISMARINE),
	// TOP --------------------------------------
	Cube(vec3( -13.5 , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -12.5 , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -11.5 , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -10.5 , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -9.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -8.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -7.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -6.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -5.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -4.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -3.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -2.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -1.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -0.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  0.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  1.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  2.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  3.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  4.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  5.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  6.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  7.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  8.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  9.5  , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  10.5 , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  11.5 , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  12.5 , 13 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  13.5 ), DARK_PRISMARINE),
	//
	Cube(vec3( -13.5 , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -12.5 , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -11.5 , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -10.5 , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -9.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -8.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -7.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -6.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -5.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -4.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -3.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -2.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -1.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -0.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  0.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  1.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  2.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  3.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  4.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  5.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  6.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  7.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  8.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  9.5  , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  10.5 , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  11.5 , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  12.5 , 13 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -13.5 ), DARK_PRISMARINE),
	//
	Cube(vec3(  13.5 , 13 , -12.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -11.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -10.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -9.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -8.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -7.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -6.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -5.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -4.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -3.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -2.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -1.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 , -0.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  0.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  1.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  2.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  3.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  4.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  5.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  6.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  7.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  8.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  9.5  ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  10.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  11.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 13 ,  12.5 ), DARK_PRISMARINE),
	//
	Cube(vec3( -13.5 , 13 , -12.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -11.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -10.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -9.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -8.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -7.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -6.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -5.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -4.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -3.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -2.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -1.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 , -0.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  0.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  1.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  2.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  3.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  4.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  5.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  6.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  7.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  8.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  9.5  ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  10.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  11.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 13 ,  12.5 ), DARK_PRISMARINE),
	// Pillars
	Cube(vec3( -14.5 , 1  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 2  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 3  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 4  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 5  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 6  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 7  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 8  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 9  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 10 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 11 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 12 , -14.5 ), DARK_PRISMARINE),
	//
	Cube(vec3(  14.5 , 1  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 2  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 3  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 4  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 5  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 6  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 7  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 8  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 9  , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 10 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 11 , -14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 12 , -14.5 ), DARK_PRISMARINE),
	//
	Cube(vec3(  14.5 , 1  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 2  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 3  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 4  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 5  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 6  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 7  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 8  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 9  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 10 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 11 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3(  14.5 , 12 ,  14.5 ), DARK_PRISMARINE),
	//
	Cube(vec3( -14.5 , 1  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 2  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 3  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 4  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 5  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 6  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 7  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 8  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 9  ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 10 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 11 ,  14.5 ), DARK_PRISMARINE),
	Cube(vec3( -14.5 , 12 ,  14.5 ), DARK_PRISMARINE),
		// Pillars
	Cube(vec3( -13.5 , 1  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 2  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 3  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 4  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 5  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 6  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 7  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 8  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 9  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 10 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 11 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 12 , -13.5 ), DARK_PRISMARINE),
	//
	Cube(vec3(  13.5 , 1  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 2  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 3  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 4  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 5  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 6  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 7  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 8  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 9  , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 10 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 11 , -13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 12 , -13.5 ), DARK_PRISMARINE),
	//
	Cube(vec3(  13.5 , 1  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 2  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 3  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 4  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 5  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 6  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 7  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 8  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 9  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 10 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 11 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3(  13.5 , 12 ,  13.5 ), DARK_PRISMARINE),
	//
	Cube(vec3( -13.5 , 1  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 2  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 3  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 4  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 5  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 6  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 7  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 8  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 9  ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 10 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 11 ,  13.5 ), DARK_PRISMARINE),
	Cube(vec3( -13.5 , 12 ,  13.5 ), DARK_PRISMARINE)
);

// INTERSECTIONS ---------------------------------------------------------------------------------------

bool f_SphereIntersection(in Ray ray, in Sphere sphere, inout float ray_length, out vec2 uv, out vec3 normal) {
	ray.Ray_Origin = ray.Ray_Origin - sphere.Position;
	float b = dot(ray.Ray_Origin, ray.Ray_Direction);
	float delta = b * b - dot(ray.Ray_Origin, ray.Ray_Origin) + sphere.Diameter * sphere.Diameter;
	
	if (delta < 0)
		return false;

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

bool f_BOXIntersection(in Ray ray, in BOX box, inout float ray_length, out vec2 uv, out vec3 normal) {
	mat4 txi = mat4(1.0);
	txi[3] = vec4(box.Position, 1.0);
	mat4 txx = inverse(txi);

	vec3 rdd = (txx*vec4(ray.Ray_Direction,0.0)).xyz;
	vec3 roo = (txx*vec4(ray.Ray_Origin,1.0)).xyz;

	vec3 m = 1.0 / rdd;
	vec3 n = m*roo;
	vec3 k = abs(m) * box.Size;
	vec3 s = vec3(
		(rdd.x<0.0)?1.0:-1.0,
		(rdd.y<0.0)?1.0:-1.0,
		(rdd.z<0.0)?1.0:-1.0
	);

	vec3 t1 = -n - k;
	vec3 t2 = -n + k;

	float tNear = max( max( t1.x, t1.y ), t1.z );
	float tFar  = min( min( t2.x, t2.y ), t2.z );
	if ( tNear > tFar || tFar < 0.0)
		return false;

	vec4 res = vec4(0);
	if (tNear > 0.0)
		res = vec4( tNear, step(vec3(tNear),t1));
	else
		res = vec4(tFar, step(t2,vec3(tFar)));

	normal = (txi * vec4(-sign(rdd) * res.yzw,0.0)).xyz;
	if ( t1.x>t1.y && t1.x>t1.z ) {
		normal = normalize(txi[0].xyz*s.x);
		uv = roo.yz+rdd.yz*t1.x;
	}
	else if ( t1.y>t1.z ) {
		normal = normalize(txi[1].xyz*s.y);
		uv = roo.zx+rdd.zx*t1.y;
	}
	else {
		normal = normalize(txi[2].xyz*s.z);
		uv = roo.xy+rdd.xy*t1.z;
	}
	uv += 0.5;
	
	ray_length = tNear;
	return true;
}

bool f_CubeIntersection(in Ray ray, in Cube cube, inout float ray_length, out vec2 uv, out vec3 normal) {
	mat4 txi = mat4(1.0);
	txi[3] = vec4(cube.Position, 1.0);
	mat4 txx = inverse(txi);

	vec3 rdd = (txx*vec4(ray.Ray_Direction,0.0)).xyz;
	vec3 roo = (txx*vec4(ray.Ray_Origin,1.0)).xyz;

	vec3 m = 1.0 / rdd;
	vec3 s = vec3(
		(rdd.x<0.0)?1.0:-1.0,
		(rdd.y<0.0)?1.0:-1.0,
		(rdd.z<0.0)?1.0:-1.0
	);
	
	vec3 t1 = m*(-roo + s*0.5);
	vec3 t2 = m*(-roo - s*0.5);

	float tNear = max( max( t1.x, t1.y ), t1.z );
	float tFar  = min( min( t2.x, t2.y ), t2.z );
	if ( tNear > tFar || tFar < 0.0)
		return false;

	vec4 res = vec4(0);

	if (tNear > 0.0)
		res = vec4( tNear, step(vec3(tNear),t1));
	else
		res = vec4(tFar, step(t2,vec3(tFar)));

	if ( t1.x>t1.y && t1.x>t1.z ) {
		normal = normalize(txi[0].xyz*s.x);
		uv = roo.yz+rdd.yz*t1.x;
	}
	else if ( t1.y>t1.z ) {
		normal = normalize(txi[1].xyz*s.y);
		uv = roo.zx+rdd.zx*t1.y;
	}
	else {
		normal = normalize(txi[2].xyz*s.z);
		uv = roo.xy+rdd.xy*t1.z;
	}
	uv += 0.5;

	ray_length = tNear;
	return true;
}

// FUNCTIONS ---------------------------------------------------------------------------------------

vec3 f_HemiCube() {
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
	vec3 normal = vec3(0);
	vec2 uv = vec2(0);
	bool inside = false;

	for (int i = 0; i < SPHERE_COUNT; i++) {
		float resultRayLength;
		if (f_SphereIntersection(ray, Scene_Spheres[i], resultRayLength, uv, normal)) {
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
	for (int i = 0; i < LIGHTS_COUNT; i++) {
		float resultRayLength;
		if (f_CubeIntersection(ray, Scene_Lights[i], resultRayLength, uv, normal)) {
			if(resultRayLength < hit_data.Ray_Length && resultRayLength > EPSILON) {
				hit_data.Ray_Length = resultRayLength;
				hit_data.Hit_Obj = i + SPHERE_COUNT;
				hit_data.Hit_Mat = Scene_Lights[i].Mat;
				hit_data.Hit_UV = uv;
				hit_data.Hit_Pos = ray.Ray_Origin + ray.Ray_Direction * hit_data.Ray_Length;
				hit_data.Hit_New_Dir = normal;
				hit_data.Ray_Inside = false;
			}
		}
	}
	for (int i = 0; i < GLASS_COUNT; i++) {
		float resultRayLength;
		if (f_BOXIntersection(ray, Scene_Glass[i], resultRayLength, uv, normal)) {
			if(resultRayLength < hit_data.Ray_Length && resultRayLength > EPSILON) {
				hit_data.Ray_Length = resultRayLength;
				hit_data.Hit_Obj = i + SPHERE_COUNT + LIGHTS_COUNT;
				hit_data.Hit_Mat = Scene_Glass[i].Mat;
				hit_data.Hit_Pos = ray.Ray_Origin + ray.Ray_Direction * hit_data.Ray_Length;
				hit_data.Hit_New_Dir = normal;
				hit_data.Ray_Inside = false;
			}
		}
	}
	for (int i = 0; i < DARK_PRISMARINE_COUNT; i++) {
		float resultRayLength;
		if (f_CubeIntersection(ray, Scene_Frame[i], resultRayLength, uv, normal)) {
			if(resultRayLength < hit_data.Ray_Length && resultRayLength > EPSILON) {
				hit_data.Ray_Length = resultRayLength;
				hit_data.Hit_Obj = i + SPHERE_COUNT + LIGHTS_COUNT + GLASS_COUNT;
				hit_data.Hit_Mat = Scene_Frame[i].Mat;
				hit_data.Hit_UV = uv;
				hit_data.Hit_Pos = ray.Ray_Origin + ray.Ray_Direction * hit_data.Ray_Length;
				hit_data.Hit_New_Dir = normal;
				hit_data.Ray_Inside = false;
			}
		}
	}
	float d = -log(rand1());
	if (d < 0.05) {
				hit_data.Ray_Length = d;
				hit_data.Hit_Obj = -1;
				hit_data.Hit_Mat = -1;
				hit_data.Hit_UV = vec2(0,0);
				hit_data.Hit_Pos = ray.Ray_Origin + ray.Ray_Direction * hit_data.Ray_Length;
				hit_data.Hit_New_Dir = refract(ray.Ray_Direction, normalize(rand3()) , 1.05) ;
				hit_data.Ray_Inside = false;
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

vec3 f_Radiance(in Ray r){
	vec3 rad = vec3(0);
	vec3 brdf = vec3(1);

	for (int b = 0; b < RAY_BOUNCES; b++) {
		Hit hit_data = f_SceneIntersection(r);
		vec3 tangent = normalize(cross(r.Ray_Direction, hit_data.Hit_New_Dir));
		vec3 bitangent = normalize(cross(hit_data.Hit_New_Dir, tangent));
		vec3 normal = f_HemiCube();
		if (hit_data.Ray_Length >= MAX_DIST) {
			return rad + brdf * f_EnvironmentHDR(r); // MISS;
		}
		if (hit_data.Hit_Mat == GLASS) {
			float cosi = abs(dot(hit_data.Hit_New_Dir, r.Ray_Direction));
			float sini = sqrt(1. - cosi * cosi);
			float iort = 1.05;
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
				brdf *= vec3(1.0);
			}
			else
				r.Ray_Direction = reflect(r.Ray_Direction, hit_data.Hit_New_Dir);
			r.Ray_Origin = hit_data.Hit_Pos + r.Ray_Direction * EPSILON;
			continue;
		}
		else if (hit_data.Hit_Mat == SEA_LANTERN) {
			vec2 uv = hit_data.Hit_UV.yx * vec2(1.0/3.0, 1.0/9.0) + vec2(0, float(9-hit_data.Hit_Mat)/9.0);
			return rad + brdf * vec3(pow(texture(iTextures, uv).r,  8), pow(texture(iTextures, uv).g,  8), pow(texture(iTextures, uv).b,  8)) * 50;
		}

		vec2 uv = hit_data.Hit_UV.yx * vec2(1.0/3.0, 1.0/9.0) + vec2(0, float(9-hit_data.Hit_Mat)/9.0);

		float roughness = texture(iTextures, uv).b;
		r.Ray_Direction = normalize(mix(reflect(r.Ray_Direction, hit_data.Hit_New_Dir), normalize(tangent * normal.x + bitangent * normal.y + hit_data.Hit_New_Dir * normal.z), roughness));
		r.Ray_Origin = hit_data.Hit_Pos + r.Ray_Direction * EPSILON;
		brdf *= texture(iTextures, uv).rgb;
	}
	return rad;
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
	else {
		fragColor = texture(iLastFrame, fragTexCoord);
	}
}