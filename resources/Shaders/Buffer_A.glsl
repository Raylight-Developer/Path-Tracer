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
	vec3  Albedo;
	vec3  Emmision;
	vec3  Refraction;
	float Roughness;
	float IOR;
};

struct Ray {
	vec3  Ray_Origin;
	vec3  Ray_Direction;
};

struct Hit {
	Ray   Light_Ray;
	float Distance;
	vec3  Hit_Normal;
	vec3  Hit_Pos;
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

const Sphere Scene_Spheres[2] = Sphere[2](
	Sphere(vec3(  1.25, 0.0, -2.5 ), 1.25, Material(vec3(1), vec3(0), vec3(1), 0.25, 1.35)),
	Sphere(vec3( -0.75, 0.0,  0.0 ), 1.5, Material(vec3(1), vec3(0), vec3(1), 0.25, 1.35))
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

float Spehere_Intersection(Ray ray, Sphere sphere) {
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

	for (int i =0; i < 2; i++) {
		float hit_ray_length = Spehere_Intersection(ray, Scene_Spheres[i]);
		if (hit_ray_length < hit_data.Distance && hit_ray_length > 0.001) { // ZBuffer
			hit_data.Distance = hit_ray_length;
			hit_data.Hit_Pos = ray.Ray_Origin + ray.Ray_Direction * hit_ray_length;

			hit_data.Hit_Normal = normalize(hit_data.Hit_Pos - Scene_Spheres[i].Position);
		}
	}
	return hit_data;
}

vec4 render() {
	Ray light_path;
	getRay(fragCoord, light_path.Ray_Origin, light_path.Ray_Direction);
	for (int i = 0; i < 2; i++) {
		if (Spehere_Intersection(light_path, Scene_Spheres[i]) != -1.0) {
			if (i == 0)
				return vec4(1);
			return vec4(1,0,0,1);
		}
	}
	return vec4(0,0,0,1);
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
	fragColor = render();
}