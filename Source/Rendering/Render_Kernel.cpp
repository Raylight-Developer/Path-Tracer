#include "Rendering/Render_Kernel.h"



// Randomness
vec1 f_randVec1() {
	static uniform_real_distribution<vec1> distribution(0.0, 1.0);
	static mt19937 generator;
	return distribution(generator);
}

vec2 f_randVec2() {
	return vec2(f_randVec1(), f_randVec1());
}

vec3 f_randVec3() {
	return vec3(f_randVec1(), f_randVec1(), f_randVec1());
}

vec1 f_randVec1(const vec1& i_min, const vec1& i_max) {
	return i_min + (i_max - i_min) * f_randVec1();
}

vec2 f_randVec2(const vec1& i_min, const vec1& i_max) {
	return vec2(i_min + (i_max - i_min)) * f_randVec2();
}

vec3 f_randVec3(const vec1& i_min, const vec1& i_max) {
	return vec3(i_min + (i_max - i_min)) * f_randVec3();
}

vec1 f_randUnitVec1() {
	while (true) {
		const vec1 value = f_randVec1(-1.0, 1.0);
		if (abs(pow(value, val(2.0))) < 1.0)
			return value;
	}
}

vec2 f_randUnitVec2() {
	while (true) {
		const vec2 value = f_randVec2(-1.0, 1.0);
		if (pow(value.length(), val(2.0)) < 1.0)
			return value;
	}
}

vec3 f_randUnitVec3() {
	while (true) {
		const vec3 value = f_randVec3(-1.0, 1.0);
		if (pow(value.length(), val(2.0)) < 1.0)
			return value;
	}
}

Ray f_cameraRay(const Camera& i_camera, const uint32& i_u, const uint32& i_v) {
	if (i_camera.depth_of_field) {
		return Ray(
			i_camera.position,// + (f_randUnitVec1() * i_camera.depth_u) + (f_randUnitVec1() * i_camera.depth_v),
			normalize(
				i_camera.projection_center
				+ i_camera.projection_u * val(i_u)
				+ i_camera.projection_v * val(i_v)
				- i_camera.position
			)
		);
	}
	return Ray(
		i_camera.position,

		normalize(
			i_camera.projection_center
			+ i_camera.projection_u * val(i_u)
			+ i_camera.projection_v * val(i_v)
			- i_camera.position
		)
	);
}

Ray f_cameraRay(const Camera& i_camera, const vec2& i_uv) {
	if (i_camera.depth_of_field) {
		return Ray(
			i_camera.position,
			normalize(
				i_camera.projection_center
				+ i_camera.projection_u * i_uv.x
				+ i_camera.projection_v * i_uv.y
				- i_camera.position
			)
		);
	}
	return Ray(
		i_camera.position,
		normalize(
			i_camera.projection_center
			+ i_camera.projection_u * i_uv.x
			+ i_camera.projection_v * i_uv.y
			- i_camera.position
		)
	);
}

bool f_sphereIntersection(const Ray& ray, const Sphere& sphere, vec1& ray_length) {
	const vec3 ray_origin = ray.origin - sphere.position;
	const vec1 b = dot(ray_origin, ray.direction);
	const vec1 delta = b * b - dot(ray_origin, ray_origin) + sphere.radius * sphere.radius;

	if (delta < 0)
		return false;
	vec1 sqdelta = sqrt(delta);
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

Intersection f_sceneIntersection(const File& i_file, const Ray& i_ray) {
	Intersection hit_data;

	hit_data.ray_length = i_file.render_max_ray_length;

	for (const Sphere& sphere : i_file.file_spheres) {
		vec1 resultRayLength;
		if (f_sphereIntersection(i_ray, sphere, resultRayLength)) {
			if (resultRayLength < hit_data.ray_length && resultRayLength > 0.001) {
				hit_data.ray_length = resultRayLength;
				hit_data.position = i_ray.origin + i_ray.direction * resultRayLength;
				hit_data.normal = normalize(hit_data.position - sphere.position);

				hit_data.inside = distance(i_ray.origin, sphere.position) <= sphere.radius;
				if (hit_data.inside) hit_data.normal *= -1.0;

				hit_data.material = sphere.material;
				//hit_data.Hit_Obj = i;
				hit_data.hit = true;
			}
		}
	}
	return hit_data;
}