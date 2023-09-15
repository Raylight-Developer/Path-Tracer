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
#define MAX_DIST 50000.0
#define RAY_BOUNCES 8
#define SPP         2

// CONSTANTS ---------------------------------------------------------------------------------------

const int Quad_Face[4] = int[](1,2,0,1);

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

float cross2d( in vec2 a, in vec2 b ) { return a.x * b.y - a.y * b.x; }

// STRUCTS ---------------------------------------------------------------------------------------

struct Material {
	float Diffuse_Gain;
	vec3  Diffuse_Color;
	float Emmisive_Gain;
	vec3  Emmisive_Color;
	float Specular_Gain;
	float Roughness;
	float Refraction;
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

struct Triangle {
	vec3     Position_A;
	vec3     Position_B;
	vec3     Position_C;
	Material Mat;
};

// SCENE ---------------------------------------------------------------------------------------

const Sphere Scene_Spheres[3] = Sphere[3](
	Sphere(vec3( 0.0, 2.05, -4.0 ), 2.0 , Material(1, vec3(1,0,1)  , 0 , vec3(1), 0, 0.25, 0 , 1.1, 0.85)), // Diffuse
	Sphere(vec3( 0.0, 1.55,  0.0 ), 1.5 , Material(1, vec3(1,1,1)  , 50, vec3(1), 0, 0   , 0 , 1.1, 1.0 )), // Emmisive
	Sphere(vec3( 0.0, 1.05,  3.5 ), 1.0 , Material(0, vec3(0.5,1,1), 0 , vec3(1), 1, 0.15, 1 , 1.3, 0.95))  // Glass
);

const Quad Scene_Quads[1] = Quad[1](
	Quad(vec3( -10, 0, -10 ), vec3( 10, 0, -10 ), vec3( 10, 0, 10 ), vec3( -10, 0, 10 ), Material(1, vec3(0.5), 0, vec3(1), 0, 0.25 , 0 , 1 , 0.85)) // Floor
);

// INTERSECTIONS ---------------------------------------------------------------------------------------

float Spehere_Intersection(in Ray ray, in Sphere sphere) {
	vec3 s0_r0 = ray.Ray_Origin - sphere.Position;
	float a = dot(ray.Ray_Direction, ray.Ray_Direction);
	float b = 2.0 * dot(ray.Ray_Direction, s0_r0);
	float c = dot(s0_r0, s0_r0) - (sphere.Diameter * sphere.Diameter);

	if (b*b - 4.0*a*c < 0.0) {
		return -1.0;
	}
	else {
		return (-b - sqrt((b*b) - 4.0*a*c))/(2.0*a);
	}
}

vec3 Quad_Intersection(in Ray ray, in Quad quad) {
	vec3 a = quad.v1 - quad.v0;
	vec3 b = quad.v3 - quad.v0;
	vec3 c = quad.v2 - quad.v0;

	vec3 p = ray.Ray_Origin - quad.v0;

	vec3 nor = cross(a,b);
	float t = -dot(p, nor)/dot(ray.Ray_Direction, nor);
	if( t<0.0 ) return vec3(-1.0);

	vec3 pos = p + t * ray.Ray_Direction;
	vec3 mor = abs(nor);
	int id;
	if (mor.x > mor.y && mor.x > mor.z ) id = 0;
	else if (mor.y > mor.z) id = 1;
	else id = 2;

	int idu = Quad_Face[id];
	int idv = Quad_Face[id+1];

	vec2 kp = vec2( pos[idu], pos[idv] );
	vec2 ka = vec2( a[idu], a[idv] );
	vec2 kb = vec2( b[idu], b[idv] );
	vec2 kc = vec2( c[idu], c[idv] );

	vec2 kg = kc-kb-ka;

	float k0 = cross2d( kp, kb );
	float k2 = cross2d( kc-kb, ka );
	float k1 = cross2d( kp, kg ) - nor[id];
	
	// if edges are parallel, this is a linear equation
	float u, v;
	if( abs(k2) < 0.00001 ) {
		v = -k0 / k1;
		u = cross2d( kp, ka ) / k1;
	}
	else {
		// otherwise, it's a quadratic
		float w = k1 * k1 - 4.0 * k0 * k2;
		if( w<0.0 ) {
			return vec3(-1.0);
		}
		w = sqrt( w );
		float ik2 = 1.0 / (2.0 * k2);
		v = (-k1 - w)*ik2;
		if( v < 0.0 || v > 1.0 ) {
			v = (-k1 + w) * ik2;
			u = (kp.x - ka.x*v)/(kb.x + kg.x*v);
		}
	}
	
	if( u<0.0 || u>1.0 || v<0.0 || v>1.0) {
		return vec3(-1.0);
	}
	else {
		return vec3( t, u, v );
	}
}

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
	for (int i =0; i < 1; i++) {
		vec3 resultTUV = Quad_Intersection(ray, Scene_Quads[i]);
		if(resultTUV.x < hit_data.Ray_Length && resultTUV.x > 0.001) {
			hit_data.Ray_Length = resultTUV.x;
			hit_data.Hit_Pos = ray.Ray_Origin + ray.Ray_Direction * resultTUV.x;
			hit_data.Hit_Normal = normalize(cross(Scene_Quads[i].v2 - Scene_Quads[i].v1, Scene_Quads[i].v3 - Scene_Quads[i].v1));
			hit_data.Hit_Mat = Scene_Quads[i].Mat;
		}
	}
	return hit_data;
}

vec4 renderRadiance() {
	Ray ray;
	getRay(fragCoord, ray.Ray_Origin, ray.Ray_Direction);

	vec3 Color = vec3(0);
	float Absorption = 1.0;
	float Bounces = 1;

	for (int depth = 0; depth < RAY_BOUNCES; depth++) {
		Hit hit_data = Scene_Intersection(ray);
		if (hit_data.Ray_Length >= MAX_DIST) {
			Color += vec3(0) * Absorption; // Ambient Lighting
			break;
		}

		if (hit_data.Hit_Mat.Diffuse_Gain == 1) {
			Color += hit_data.Hit_Mat.Diffuse_Color * hit_data.Hit_Mat.Emmisive_Gain * Absorption * 0.05;
			ray.Ray_Direction = normalize(reflect(ray.Ray_Direction, hit_data.Hit_Normal) + rand3() * hit_data.Hit_Mat.Roughness);
		}

		if (hit_data.Hit_Mat.Specular_Gain > 0 && hit_data.Hit_Mat.Refraction > 0) {
			Color += hit_data.Hit_Mat.Diffuse_Color * hit_data.Hit_Mat.Emmisive_Gain * Absorption * 0.05;
			if (rand1() > 0.5) {
				ray.Ray_Direction = normalize(reflect(ray.Ray_Direction, hit_data.Hit_Normal) + rand3() * hit_data.Hit_Mat.Roughness);
			}
			else {
				ray.Ray_Direction = normalize(refract(ray.Ray_Direction, hit_data.Hit_Normal, hit_data.Hit_Mat.IOR) + rand3() * hit_data.Hit_Mat.Roughness);
			}
		}

		else if (hit_data.Hit_Mat.Specular_Gain > 0) {
			Color += hit_data.Hit_Mat.Diffuse_Color * hit_data.Hit_Mat.Emmisive_Gain * Absorption * 0.05;
			ray.Ray_Direction = normalize(reflect(ray.Ray_Direction, hit_data.Hit_Normal) + rand3() * hit_data.Hit_Mat.Roughness);
		}

		else if (hit_data.Hit_Mat.Refraction > 0) {
			Color += hit_data.Hit_Mat.Diffuse_Color * hit_data.Hit_Mat.Emmisive_Gain * Absorption * 0.05;
			ray.Ray_Direction = normalize(refract(ray.Ray_Direction, hit_data.Hit_Normal, hit_data.Hit_Mat.IOR) + rand3() * hit_data.Hit_Mat.Roughness);
		}

		if (hit_data.Hit_Mat.Emmisive_Gain > 0) {
			break;
		}

		ray.Ray_Origin = ray.Ray_Origin + ray.Ray_Direction * hit_data.Ray_Length;
		Absorption *= hit_data.Hit_Mat.Absorption;
		Bounces = float(depth + 1);
	}
	return vec4(Color, 1.0/ Bounces);
}

// Main ---------------------------------------------------------------------------------------
void main() {
	rng_initialize(gl_FragCoord.xy, iFrame);

	if (iFrame <= 1) {
		fragColor = renderRadiance();
	}
	else {
		fragColor = texture(iLastFrame, fragTexCoord);
	}
	//for(int i = 0; i < SPP; i++) {
		fragColor = renderRadiance();
	//}
}