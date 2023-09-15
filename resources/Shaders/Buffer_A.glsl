#version 460 core

uniform float iTime;
uniform uint iFrame;
uniform vec2 iResolution;

uniform float iCameraFocalLength;
uniform float iCameraSensorWidth;
uniform vec3  iCameraPos;
uniform vec3  iCameraFront;
uniform vec3  iCameraUp;
uniform bool  iCameraChange;

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

#define INFINITY 5000.
#define M_PI 3.1415926535897932384626433832795
#define M_E 2.7182818284590452353602874

#define SAMPLES 1
#define MAX_BOUNCES 8
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

float mapFloat(float FromMin, float FromMax, float ToMin, float ToMax, float Value) {
	if (Value > FromMax) return ToMax;
	else if (Value < FromMin) return ToMin;
	else return (ToMin + ((ToMax - ToMin) / (FromMax - FromMin)) * (Value - FromMin));
}

// STRUCTS ---------------------------------------------------------------------------------------

struct Material {
	float Diffuse_Gain;
	vec3  Diffuse_Color;
	float Emissive_Gain;
	vec3  Emissive_Color;
	float Specular_Gain;
	float Roughness;
	float Refraction;
	float IOR;
	float Absorption;
	float Dispersion_WV_A;
	float Dispersion_WV_B;
	float Dispersion_Strength;
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
	vec3  Hit_New_Dir;
	vec3  Hit_Pos;
	int   Hit_Obj;
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

const Sphere Scene_Spheres[9] = Sphere[9](
	Sphere(vec3( 1   , -0.5   , -3.2    ), 0.5, Material(0, vec3(1  , 1  , 1  )  , 0 , vec3(1), 0, 0.05, 1 , 1.5, 0.95, 0, 300, 0.5)), // Glass
	Sphere(vec3( 0   , -0.5   , -5.2    ), 0.5, Material(1, vec3(0.1, 0.5, 0.9)  , 0 , vec3(1), 0, 0   , 0 , 1.1, 1.0 , 0, 0  , 0.1)),
	Sphere(vec3(-1   , -0.5   , -4.2    ), 0.5, Material(0, vec3(1  , 1  , 1  )  , 0 , vec3(1), 1, 0   , 0 , 1.3, 1.0 , 0, 300, 0.1)), // Mirror
	Sphere(vec3( 0   ,  1.9   , -4.5    ), 0.4, Material(0, vec3(1  , 1  , 1  )  , 5 , vec3(1), 0, 0   , 0 , 1.1, 1.0 , 0, 300, 0.1)), // Emmisive
	Sphere(vec3( 0   , -1000  , -4.0    ), 999, Material(1, vec3(1  , 1  , 1  )  , 0 , vec3(1), 0, 0.25, 0 , 1.1, 0.85, 0, 0  , 0.1)),
	Sphere(vec3( 1001,  0     ,  0      ), 999, Material(1, vec3(0  , 1  , 0  )  , 0 , vec3(1), 0, 0.25, 0 , 1.1, 0.85, 0, 0  , 0.1)),
	Sphere(vec3(-1001,  0     ,  0      ), 999, Material(1, vec3(1  , 0  , 0  )  , 0 , vec3(1), 0, 0.25, 0 , 1.1, 0.85, 0, 0  , 0.1)),
	Sphere(vec3( 0   ,  0.5   , -1005.5 ), 999, Material(1, vec3(1  , 1  , 1  )  , 0 , vec3(1), 0, 0.25, 0 , 1.1, 0.85, 0, 0  , 0.1)),
	Sphere(vec3( 0   ,  1001.7,  0      ), 999, Material(1, vec3(1  , 1  , 1  )  , 0 , vec3(1), 0, 0.25, 0 , 1.1, 0.85, 0, 0  , 0.1))
);

const Quad Scene_Quads[1] = Quad[1](
	Quad(vec3( -10, 0, -10 ), vec3( 10, 0, -10 ), vec3( 10, 0, 10 ), vec3( -10, 0, 10 ), Material(1, vec3(0.5), 0, vec3(1), 0, 0.25 , 0 , 1 , 0.85, 0, 0, 0)) // Floor
);

// INTERSECTIONS ---------------------------------------------------------------------------------------

float Spehere_Intersection(in Ray ray, in Sphere sphere) {
	ray.Ray_Origin = ray.Ray_Origin - sphere.Position;
	
	float b = dot(ray.Ray_Origin, ray.Ray_Direction);
	float delta = b * b - dot(ray.Ray_Origin, ray.Ray_Origin) + sphere.Diameter * sphere.Diameter;
	
	if (delta < 0)
		return -1;

	float sqdelta = sqrt(delta);

	if (-b - sqdelta > 0.001)
		return -b - sqdelta;
	else if (-b + sqdelta > 0.001)
		return -b + sqdelta;
	return -1;
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
// LUT ---------------------------------------------------------------------------------------

vec3 getRGBfromHue(float hue) {
	float Max = 1.0;
	float Min = 0.0;
	float Volatile = (Max - Min) * (1.0 - float(int(abs(hue / 60.0)) % 2) - 1.0) + Min;
	if (hue < 60.0)
		return vec3(Max, Volatile, Min);
	else if (hue < 120.0)
		return vec3(Volatile, Max, Min);
	else if (hue < 180.0)
		return vec3(Min, Max, Volatile);
	else if (hue < 240.0)
		return vec3(Min, Volatile, Max);
	else if (hue < 300.0)
		return vec3(Volatile, Min, Max);
	else if (hue < 360.0)
		return vec3(Max, Min, Volatile);
	else
		return vec3(Max, Min, Min);
}

vec3 getRGBfromWV(float wv) {
	float Max = 1.0;
	float Min = 0.0;
	float Volatile = (Max - Min) * (1.0 - float(int(abs(wv / 60.0)) % 2) - 1.0) + Min;
	if (wv < 60.0)
		return vec3(Volatile, Min, Max);
	else if (wv < 120.0)
		return vec3(Min, Volatile, Max);
	else if (wv < 180.0)
		return vec3(Min, Max, Volatile);
	else if (wv < 240.0)
		return vec3(Volatile, Max, Min);
	else if (wv < 300.0)
		return vec3(Max, Volatile, Min);
	else if (wv <= 360.0)
		return vec3(Max, Min, Volatile);
}

float WVfromRGB(vec3 rgb) {
	float hue = degrees(rgb.x);
	if (hue < 0)
		hue += 360;
	return hue;
}

// FUNCTIONS ---------------------------------------------------------------------------------------

float DispersionLaw(float wv_a, float wv_b, float wv, float strength) {
	return mapFloat(wv_a, wv_b, -1, 1, wv) * strength;
}

float hash1(inout float seed)
{
	return fract(sin(seed += 0.1)*43758.5453123);
}

float nrand( vec2 n )
{
	return fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453);
}

vec2 hash2(inout float seed)
{
	return fract(sin(vec2(seed+=0.1,seed+=0.1))*vec2(43758.5453123,22578.1459123));
}


float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 uniform_disk_sample(inout float seed) {
	vec2 p = hash2(seed);
	return vec2(2. * M_PI * p.x, sqrt(p.y));
}

vec3 cosine_weighted_hemi_sample(inout float seed) {
	vec2 p = uniform_disk_sample(seed);
	return normalize(vec3(sin(p.x) * p.y, cos(p.x) * p.y, sqrt(1. - p.y * p.y)));
}

Hit intersect_scene(const in Ray ray, inout bool inside) {
	Hit hit_data;
	hit_data.Ray_Length = MAX_DIST;

	for (int i =0; i < 9; i++) {
		float resultRayLength = Spehere_Intersection(ray, Scene_Spheres[i]);
		if(resultRayLength < hit_data.Ray_Length && resultRayLength > 0.001) {
			hit_data.Ray_Length = resultRayLength;
			hit_data.Hit_Pos = ray.Ray_Origin + ray.Ray_Direction * resultRayLength;
			hit_data.Hit_New_Dir = normalize(hit_data.Hit_Pos - Scene_Spheres[i].Position);
			hit_data.Hit_Mat = Scene_Spheres[i].Mat;
			hit_data.Hit_Obj = i;
			inside = distance(ray.Ray_Origin, Scene_Spheres[i].Position) <= Scene_Spheres[i].Diameter;
			if (inside) hit_data.Hit_New_Dir *= -1.0;
		}
	}
	return hit_data;
}

vec3 cone_uniform(in float theta, in vec3 dir, inout float seed) {
	
	vec3 left = cross(dir, vec3(0., 1., 0.));
	left = length(left) > 0.1 ? normalize(left) : normalize(cross(dir, vec3(0., 0., 1.)));
	vec3 up = normalize(cross(dir, left));
	
	//cone sampling implementation from pbrt
	vec2 u = hash2(seed);
	float cos_theta = (1. - u.x) + u.x * cos(theta);
	float sin_theta = sqrt(1. - cos_theta * cos_theta);
	float phi = u.y * 2. * M_PI;
	return normalize(
		left * cos(phi) * sin_theta +
		up   * sin(phi) * sin_theta +
		dir  * cos_theta);

}

vec3 sample_light(const in Hit hit_data, in int object, inout float seed, out float inv_prob) //return the radiance already scaled by the pdf
{
	Sphere l = Scene_Spheres[object];
	vec3 dir = normalize(l.Position - hit_data.Hit_Pos);
	float dist = length(l.Position - hit_data.Hit_Pos);
	float theta = asin(l.Diameter / dist);
	Ray r = Ray(hit_data.Hit_Pos + hit_data.Hit_New_Dir * 0.0001, cone_uniform(theta, dir, seed)); //epsilon to make sure it self intersects

	bool inside;

	inv_prob = (2. * (1. - cos(theta)));

	Hit hit = intersect_scene(r, inside);
	if (hit.Hit_Mat.Emissive_Gain > 0 && hit.Hit_Obj == object) {
		return l.Mat.Emissive_Color * l.Mat.Emissive_Gain * max(0., dot(r.Ray_Direction, hit_data.Hit_New_Dir)) * inv_prob;
	}
	return vec3(0);
}

float snell (float sin_theta, float iori, float iort)
{
	return iori / iort * sin_theta;
}

float fresnel(float iori, float iort, float cosi, float cost){
	float rpar = (iort * cosi - iori * cost) / (iort * cosi + iori * cost);
	float rper = (iori * cosi - iort * cost) / (iori * cosi + iort * cost);
	rpar *= rpar;
	rper *= rper;
	return (rpar + rper) / 2.;
}

vec3 get_radiance(Ray r, inout float seed){
	vec3 rad = vec3(0);
	vec3 brdf = vec3(1);
	bool delta = true;
	bool inside = false;

	for (int b = 0; b < MAX_BOUNCES; b++){
		Hit hit_data = intersect_scene(r, inside);

		if (hit_data.Ray_Length >= MAX_DIST) {
			return rad + brdf * vec3(0.0, 0.0, 0.0); // MISS;
		}
		float prob = 0.;
		if (hit_data.Hit_Mat.Diffuse_Gain > 0){ // DIFFUSE
			delta = false;
			vec3 tangent = normalize(cross(r.Ray_Direction, hit_data.Hit_New_Dir));
			vec3 bitangent = normalize(cross(hit_data.Hit_New_Dir, tangent));
			vec3 nr = cosine_weighted_hemi_sample(seed);;
			r.Ray_Direction = normalize(tangent * nr.x + bitangent * nr.y + hit_data.Hit_New_Dir * nr.z);
			brdf *= hit_data.Hit_Mat.Diffuse_Color;
			for (int i = 0; i < 9; i++) {
				vec3 acc = brdf * sample_light(hit_data, i, seed, prob);
				rad += acc;
			}
		}
		else if (hit_data.Hit_Mat.Specular_Gain > 0){ // SPECULAR
			delta = true;
			r.Ray_Direction = reflect(r.Ray_Direction, hit_data.Hit_New_Dir);
			brdf *= hit_data.Hit_Mat.Diffuse_Color;
		}
		else if (hit_data.Hit_Mat.Refraction > 0){ // GLASS
			delta = true;
			float cosi = abs(dot(hit_data.Hit_New_Dir, r.Ray_Direction));
			float sini = sqrt(1. - cosi * cosi);
			float Wavelength = mix(hit_data.Hit_Mat.Dispersion_WV_A, hit_data.Hit_Mat.Dispersion_WV_B, rand1());
			float iort = hit_data.Hit_Mat.IOR + DispersionLaw(hit_data.Hit_Mat.Dispersion_WV_A, hit_data.Hit_Mat.Dispersion_WV_B, Wavelength, hit_data.Hit_Mat.Dispersion_Strength);
			float iori = 1.0;
			if (inside){
				iori = iort;
				iort = 1.0;
			}
			float sint = snell(sini, iori, iort);
			float cost = sqrt(1.0 - sint * sint);
			float frsn = fresnel(iori, iort, cosi, cost);

			if (hash1(seed) > frsn){
				vec3 bitangent = normalize(r.Ray_Direction - dot(hit_data.Hit_New_Dir, r.Ray_Direction) * hit_data.Hit_New_Dir);
				r.Ray_Direction = normalize(bitangent * sint - cost * hit_data.Hit_New_Dir);
				brdf *= getRGBfromHue(Wavelength);
			}
			else{
				r.Ray_Direction = reflect(r.Ray_Direction, hit_data.Hit_New_Dir);
			}
		}
		else if (hit_data.Hit_Mat.Emissive_Gain > 0) { // EMISSIVE
			return rad + brdf * (delta ? hit_data.Hit_Mat.Emissive_Color *  hit_data.Hit_Mat.Emissive_Gain : vec3(0));
		}
		r.Ray_Origin = hit_data.Hit_Pos + r.Ray_Direction * 0.001;
	}
	return rad;
}

Ray ray_from_camera(vec2 uv) {
	vec3 projection_center = iCameraPos + iCameraFocalLength * iCameraFront;
	vec3 projection_u = normalize(cross(iCameraFront, iCameraUp)) * iCameraSensorWidth;
	vec3 projection_v = normalize(cross(projection_u, iCameraFront)) * (iCameraSensorWidth / 1.0);
	return Ray(iCameraPos, normalize(projection_center + (projection_u * uv.x) + (projection_v * uv.y) - iCameraPos));
}

// Main ---------------------------------------------------------------------------------------
void main() {
	rng_initialize(gl_FragCoord.xy, iFrame);
	vec2 uv0 = gl_FragCoord.xy/iResolution.xy;
	
	vec3 col;
	for (int s = 0; s < SAMPLES; s++){
		float seed = hash12(gl_FragCoord.xy + iTime * M_PI + float(s) * 634.2342) + nrand(uv0 * iTime) * 52.2246 + hash2(uv0.x).x; //
		vec2 uv = (gl_FragCoord.xy + hash2(seed) - 1. - iResolution.xy /2.)/max(iResolution.x, iResolution.y);
		col += get_radiance(ray_from_camera(uv), seed);

		
	}
	col /= float(SAMPLES);
	// Accumulation
	if (iFrame <= 1 || !iCameraChange) {
		float interval = float(iFrame);
		col = (texture(iLastFrame, fragTexCoord).xyz * interval + col) / (interval + 1.);
	}
	fragColor = vec4(col , 0.0);
}