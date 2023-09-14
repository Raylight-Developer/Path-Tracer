#version 460 core

uniform float iTime;
uniform uint iFrame;
uniform vec2 iResolution;

uniform float iCameraFocalLength;
uniform float iCameraSensorWidth;
uniform vec3  iCameraPos;
uniform vec3  iCameraFront;
uniform vec3  iCameraUp;

uniform sampler2D iLastFrame;

in vec2 fragCoord;
in vec2 fragTexCoord;

out vec4 fragColor;

// DEFINITIONS ---------------------------------------------------------------------------------------

#define TWO_PI   6.28318530718
#define PI       3.14159265359
#define DEG_RAD  0.01745329252
#define MAX_DIST 5000.0
#define RAY_BOUNCES 4

// CONSTANTS ---------------------------------------------------------------------------------------

// GLOBALS ---------------------------------------------------------------------------------------

// GENERIC FUNCTIONS ---------------------------------------------------------------------------------------

uvec4 white_noise_seed;
uvec2 pixel;

uvec4 hash(uvec4 seed) {
	seed = seed * 1664525u + 1013904223u;
	seed.x += seed.y*seed.w; seed.y += seed.z*seed.x; seed.z += seed.x*seed.y; seed.w += seed.y*seed.z;
	seed = seed ^ (seed>>16u);
	seed.x += seed.y*seed.w; seed.y += seed.z*seed.x; seed.z += seed.x*seed.y; seed.w += seed.y*seed.z;
	return seed;
}

float rand1() { return float(hash(white_noise_seed).x)   / float(0xffffffffu); }
vec2  rand2() { return vec2 (hash(white_noise_seed).xy)  / float(0xffffffffu); }
vec3  rand3() { return vec3 (hash(white_noise_seed).xyz) / float(0xffffffffu); }
vec4  rand4() { return vec4 (hash(white_noise_seed))     / float(0xffffffffu); }

vec2 nrand2(float sigma, vec2 mean) {
	vec2 Z = rand2();
	return mean + sigma * sqrt(-2.0 * log(Z.x)) * vec2(cos(TWO_PI * Z.y), sin(TWO_PI * Z.y));
}
vec3 nrand3(float sigma, vec3 mean) {
	vec4 Z = rand4();
	return mean + sigma * sqrt(-2.0 * log(Z.xxy)) * vec3(cos(TWO_PI * Z.z), sin(TWO_PI * Z.z), cos(TWO_PI * Z.w));
}

void rng_initialize(vec2 pix, uint frame) {
	pixel = uvec2(pix);
	white_noise_seed = uvec4(pixel, frame, uint(pixel.x) + uint(pixel.y));
}

vec3 rgb_noise() {
	return rand3();
}
vec3 white_noise() {
	return vec3(rand1());
}

// STRUCTS ---------------------------------------------------------------------------------------

struct Material {
	float Diffuse_Gain;
	vec3  Diffuse_Color;
	float Emmisive_Gain;
	vec3  Emmisive_Color;
	float Specular_Gain;
	float Roughness;
	float Refraction;
	float Reflection;
	float IOR;
	float Absorption;
};

struct Sun_Light {
	float Intensity;
	vec3  Color;
	vec3  Direction;
};

struct Ray {
	vec3  Ray_Origin;
	vec3  Ray_Direction;
};

struct Hit {
	float Ray_Length;
	vec3  Hit_Normal;
	vec3  Hit_Pos;
	Material Hit_Mat;
};

struct Sphere {
	vec3     Position;
	float    Radius;
	Material Mat;
};

struct Triangle {
	vec3     Position_A;
	vec3     Position_B;
	vec3     Position_C;
	Material Mat;
};

// SCENE ---------------------------------------------------------------------------------------

const Sphere Scene_Spheres[3] = Sphere[3](
	Sphere(vec3(  1.25, 0.0, -2.5 ), 1.25, Material(1, vec3(0,0,1), 0, vec3(1), 0, 0.5 , 0 ,0 , 1  , 0.85)),
	Sphere(vec3(   0.0, 0.0, -7.5 ), 1.0 , Material(1, vec3(1,1,1), 0, vec3(1), 1, 0.25, 1 ,1 , 1.5, 0.95)),
	Sphere(vec3( -0.75, 0.0,  0.0 ), 1.5 , Material(1, vec3(1,1,1), 1, vec3(1), 0, 0   , 0 ,0 , 1  , 1.0 ))
);

// FUNCTIONS ---------------------------------------------------------------------------------------

void getRay(in vec2 uv, out vec3 ray_origin, out vec3 ray_direction) {
	uv = uv -0.5;
	uv.x *= iResolution.x / iResolution.y;

	vec3 projection_center = iCameraPos + iCameraFocalLength * iCameraFront;
	vec3 projection_u = normalize(cross(iCameraFront, iCameraUp)) * iCameraSensorWidth;
	vec3 projection_v = normalize(cross(projection_u, iCameraFront)) * (iCameraSensorWidth / 1.0);

	ray_origin = iCameraPos;
	ray_direction = normalize(projection_center + (projection_u * uv.x) + (projection_v * uv.y) - iCameraPos);
}

float Spehere_Intersection(inout Ray ray, in Sphere sphere) {
	vec3 s0_r0 = ray.Ray_Origin - sphere.Position;
	float a = dot(ray.Ray_Direction, ray.Ray_Direction);
	float b = 2.0 * dot(ray.Ray_Direction, s0_r0);
	float c = dot(s0_r0, s0_r0) - (sphere.Radius * sphere.Radius);

	if (b*b - 4.0*a*c < 0.0) {
		return -1.0;
	}
	return (-b - sqrt((b*b) - 4.0*a*c))/(2.0*a);
}

Hit Scene_Intersection(in Ray ray) {
	Hit hit_data;
	hit_data.Ray_Length = MAX_DIST;

	for (int i =0; i < 3; i++) {
		float resultRayLength = Spehere_Intersection(ray, Scene_Spheres[i]);
		if(resultRayLength < hit_data.Ray_Length && resultRayLength > 0.001) {
			hit_data.Ray_Length = resultRayLength;
			hit_data.Hit_Pos = ray.Ray_Origin + ray.Ray_Direction * resultRayLength;
			hit_data.Hit_Normal = normalize(hit_data.Hit_Pos - Scene_Spheres[i].Position);
			hit_data.Hit_Mat = Scene_Spheres[i].Mat;
		}
	}
	return hit_data;
}

vec4 renderRadiance() {
	Ray ray;
	getRay(fragCoord, ray.Ray_Origin, ray.Ray_Direction);

	vec3 Color = vec3(0);
	float Trasparency = 1;
	float Absorption = 1.0;

	for(int i = 0; i < 1; i++) {
		Hit hit_data = Scene_Intersection(ray);

		if (hit_data.Ray_Length >= MAX_DIST) {
			Color = vec3(0.5, 0.5, 0.9) * Absorption; // Ambient Lighting
			Trasparency = 0;
			break;
		}

		if (hit_data.Hit_Mat.Diffuse_Gain > 0) {
			Color += hit_data.Hit_Mat.Diffuse_Color * Absorption;
			ray.Ray_Direction = reflect(ray.Ray_Direction, hit_data.Hit_Normal);
		}
		else if (hit_data.Hit_Mat.Specular_Gain > 0){
			Color += hit_data.Hit_Mat.Diffuse_Color * Absorption;
			ray.Ray_Direction = reflect(ray.Ray_Direction, hit_data.Hit_Normal);
		}
		else if (hit_data.Hit_Mat.Refraction > 0){
			Color += hit_data.Hit_Mat.Diffuse_Color * Absorption;
			ray.Ray_Direction = refract(ray.Ray_Direction, hit_data.Hit_Normal, hit_data.Hit_Mat.IOR);
		}
		else if (hit_data.Hit_Mat.Emmisive_Gain > 0){
			Color += hit_data.Hit_Mat.Diffuse_Color * Absorption;
			ray.Ray_Direction = reflect(ray.Ray_Direction, hit_data.Hit_Normal);
		}

		ray.Ray_Origin = ray.Ray_Origin + ray.Ray_Direction * 0.0001;
		Absorption *= hit_data.Hit_Mat.Absorption;
	}
	return vec4(Color, Trasparency);
}

// Main ---------------------------------------------------------------------------------------
void main() {
	rng_initialize(gl_FragCoord.xy, iFrame);

	// if (iFrame <= 1) {
	// 	fragColor = render(fragCoord);
	// }
	// else {
	// 	fragColor = texture(iLastFrame, fragTexCoord);
	// }
	fragColor = renderRadiance();
}