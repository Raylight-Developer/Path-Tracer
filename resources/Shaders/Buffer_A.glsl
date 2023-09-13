#version 460 core

uniform float iTime;
uniform uint iFrame;
uniform vec2 iResolution;

uniform sampler2D iLastFrame;

in vec2 fragCoord;
in vec2 fragTexCoord;

out vec4 fragColor;

// DEFINITIONS ---------------------------------------------------------------------------------------

#define TWO_PI   6.28318530718
#define PI       3.14159265359
#define DEG_RAD  0.01745329252

// CONSTANTS ---------------------------------------------------------------------------------------

vec3 Wavelets[] = vec3[] (
	vec3( 0.001368, 0.000039, 0.006450 ), // 380 nm
	vec3( 0.002236, 0.000064, 0.010550 ), // 385 nm
	vec3( 0.004243, 0.000120, 0.020050 ), // 390 nm
	vec3( 0.007650, 0.000217, 0.036210 ), // 395 nm
	vec3( 0.014310, 0.000396, 0.067850 ), // 400 nm
	vec3( 0.023190, 0.000640, 0.110200 ), // 405 nm
	vec3( 0.043510, 0.001210, 0.207400 ), // 410 nm
	vec3( 0.077630, 0.002180, 0.371300 ), // 415 nm
	vec3( 0.134380, 0.004000, 0.645600 ), // 420 nm
	vec3( 0.214770, 0.007300, 1.039050 ), // 425 nm
	vec3( 0.283900, 0.011600, 1.385600 ), // 430 nm
	vec3( 0.328500, 0.016840, 1.622960 ), // 435 nm
	vec3( 0.348280, 0.023000, 1.747060 ), // 440 nm
	vec3( 0.348060, 0.029800, 1.782600 ), // 445 nm
	vec3( 0.336200, 0.038000, 1.772110 ), // 450 nm
	vec3( 0.318700, 0.048000, 1.744100 ), // 455 nm
	vec3( 0.290800, 0.060000, 1.669200 ), // 460 nm
	vec3( 0.251100, 0.073900, 1.528100 ), // 465 nm
	vec3( 0.195360, 0.090980, 1.287640 ), // 470 nm
	vec3( 0.142100, 0.112600, 1.041900 ), // 475 nm
	vec3( 0.095640, 0.139020, 0.812950 ), // 480 nm
	vec3( 0.057950, 0.169300, 0.616200 ), // 485 nm
	vec3( 0.032010, 0.208020, 0.465180 ), // 490 nm
	vec3( 0.014700, 0.258600, 0.353300 ), // 495 nm
	vec3( 0.004900, 0.323000, 0.272000 ), // 500 nm
	vec3( 0.002400, 0.407300, 0.212300 ), // 505 nm
	vec3( 0.009300, 0.503000, 0.158200 ), // 510 nm
	vec3( 0.029100, 0.608200, 0.111700 ), // 515 nm
	vec3( 0.063270, 0.710000, 0.078250 ), // 520 nm
	vec3( 0.109600, 0.793200, 0.057250 ), // 525 nm
	vec3( 0.165500, 0.862000, 0.042160 ), // 530 nm
	vec3( 0.225750, 0.914850, 0.029840 ), // 535 nm
	vec3( 0.290400, 0.954000, 0.020300 ), // 540 nm
	vec3( 0.359700, 0.980300, 0.013400 ), // 545 nm
	vec3( 0.433450, 0.994950, 0.008750 ), // 550 nm
	vec3( 0.512050, 1.000000, 0.005750 ), // 555 nm
	vec3( 0.594500, 0.995000, 0.003900 ), // 560 nm
	vec3( 0.678400, 0.978600, 0.002750 ), // 565 nm
	vec3( 0.762100, 0.952000, 0.002100 ), // 570 nm
	vec3( 0.842500, 0.915400, 0.001800 ), // 575 nm
	vec3( 0.916300, 0.870000, 0.001650 ), // 580 nm
	vec3( 0.978600, 0.816300, 0.001400 ), // 585 nm
	vec3( 1.026300, 0.757000, 0.001100 ), // 590 nm
	vec3( 1.056700, 0.694900, 0.001000 ), // 595 nm
	vec3( 1.062200, 0.631000, 0.000800 ), // 600 nm
	vec3( 1.045600, 0.566800, 0.000600 ), // 605 nm
	vec3( 1.002600, 0.503000, 0.000340 ), // 610 nm
	vec3( 0.938400, 0.441200, 0.000240 ), // 615 nm
	vec3( 0.854450, 0.381000, 0.000190 ), // 620 nm
	vec3( 0.751400, 0.321000, 0.000100 ), // 625 nm
	vec3( 0.642400, 0.265000, 0.000050 ), // 630 nm
	vec3( 0.541900, 0.217000, 0.000030 ), // 635 nm
	vec3( 0.447900, 0.175000, 0.000020 ), // 640 nm
	vec3( 0.360800, 0.138200, 0.000010 ), // 645 nm
	vec3( 0.283500, 0.107000, 0.000000 ), // 650 nm
	vec3( 0.218700, 0.081600, 0.000000 ), // 655 nm
	vec3( 0.164900, 0.061000, 0.000000 ), // 660 nm
	vec3( 0.121200, 0.044580, 0.000000 ), // 665 nm
	vec3( 0.087400, 0.032000, 0.000000 ), // 670 nm
	vec3( 0.063600, 0.023200, 0.000000 ), // 675 nm
	vec3( 0.046770, 0.017000, 0.000000 ), // 680 nm
	vec3( 0.032900, 0.011920, 0.000000 ), // 685 nm
	vec3( 0.022700, 0.008210, 0.000000 ), // 690 nm
	vec3( 0.015840, 0.005723, 0.000000 ), // 695 nm
	vec3( 0.011359, 0.004102, 0.000000 ), // 700 nm
	vec3( 0.008111, 0.002929, 0.000000 ), // 705 nm
	vec3( 0.005790, 0.002091, 0.000000 ), // 710 nm
	vec3( 0.004109, 0.001484, 0.000000 ), // 715 nm
	vec3( 0.002899, 0.001047, 0.000000 ), // 720 nm
	vec3( 0.002049, 0.000740, 0.000000 ), // 725 nm
	vec3( 0.001440, 0.000520, 0.000000 ), // 730 nm
	vec3( 0.001000, 0.000361, 0.000000 ), // 735 nm
	vec3( 0.000690, 0.000249, 0.000000 ), // 740 nm
	vec3( 0.000476, 0.000172, 0.000000 ), // 745 nm
	vec3( 0.000332, 0.000120, 0.000000 ), // 750 nm
	vec3( 0.000235, 0.000085, 0.000000 ), // 755 nm
	vec3( 0.000166, 0.000060, 0.000000 ), // 760 nm
	vec3( 0.000117, 0.000042, 0.000000 ), // 765 nm
	vec3( 0.000083, 0.000030, 0.000000 ), // 770 nm
	vec3( 0.000059, 0.000021, 0.000000 ), // 775 nm
	vec3( 0.000042, 0.000015, 0.000000 )  // 780 nm
);

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

struct Camera {
	vec3  Position;
	vec3  Rotation;
	float Senosr_Width;
	float Focal_Length;
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
	Sphere(vec3( 1.0, 1.0, 0.0), 1.0, Material(vec3(1), vec3(0), vec3(1), 0.25, 1.35)),
	Sphere(vec3(-1.0, 2.0, 0.0), 2.0, Material(vec3(1), vec3(0), vec3(1), 0.25, 1.35))
);

// FUNCTIONS ---------------------------------------------------------------------------------------

void getRay(in vec2 uv, out vec3 ray_origin, out vec3 ray_direction) {
	uv = uv -0.5;
	uv.x *= iResolution.x / iResolution.y;

	// CAMERA POSITION
	ray_origin = vec3(1.0, 5.0, 0.00);
	float sensor_width = 0.036;
	float focal_length = 0.05;
	// CAMERA ROTATION
	float Yaw =   0.0  * DEG_RAD;
	float Pitch = 90.0 * DEG_RAD;
	float Roll =  0.0  * DEG_RAD;
	mat4 pitchMat = mat4(
		1 , 0          , 0           , 0 ,
		0 , cos(Pitch) , -sin(Pitch) , 0 ,
		0 , sin(Pitch) ,  cos(Pitch) , 0 ,
		0 , 0          , 0           , 1
	);
	mat4 yawMat = mat4(
		 cos(Yaw) , 0 , sin(Yaw) , 0 ,
		 0        , 1 , 0        , 0 ,
		-sin(Yaw) , 0 , cos(Yaw) , 0 ,
		 0        , 0 , 0        , 1
	);
	mat4 rollMat = mat4(
		cos(Roll) , -sin(Roll) , 0 , 0 ,
		sin(Roll) ,  cos(Roll) , 0 , 0 ,
		0         ,  0         , 1 , 0 ,
		0         ,  0         , 0 , 1
	);
	mat4 rotmat = pitchMat * yawMat * rollMat;
	vec3 forward_vec = normalize(vec3(rotmat * vec4(0, 0, -1, 0)));
	vec3 up_vec = normalize(vec3(rotmat * vec4(0, 1, 0, 0)));
	
	vec3 projection_center = ray_origin + (focal_length * forward_vec);
	vec3 projection_u = normalize(cross(forward_vec, up_vec)) * sensor_width;
	vec3 projection_v = normalize(cross(projection_u, forward_vec)) * (sensor_width / 1.0);

	ray_direction = normalize(projection_center + (projection_u * uv.x) + (projection_v * uv.y) - ray_origin);
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
		Sphere sphere = Sphere(vec3( 1.0, 1.0, 0.0), 1.0, Material(vec3(1), vec3(0), vec3(1), 0.25, 1.35));
	if (Spehere_Intersection(light_path, sphere) != -1.0) {
		return vec4(1.0);
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