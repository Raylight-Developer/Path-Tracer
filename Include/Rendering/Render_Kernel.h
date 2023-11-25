#pragma once

#include "Include.h"

#include "Object/Camera.h"
#include "Object/Sphere.h"
#include "I-O/File.h"

struct Ray {
	vec3 origin;
	vec3 direction;

	Ray(const vec3& i_origin = vec3(0), const vec3& i_direction = vec3(0,0,-1)) :
		origin(i_origin),
		direction(i_direction)
	{};
};

struct Intersection {
	vec1 ray_length;
	vec2 uv;
	vec3 normal;
	vec3 position;
	bool inside = false;
	bool hit    = false;
	Material* material;
};

// Randomness
vec1 f_randVec1();
vec2 f_randVec2();
vec3 f_randVec3();
vec1 f_randVec1(const vec1& i_min, const vec1& i_max);
vec2 f_randVec2(const vec1& i_min, const vec1& i_max);
vec3 f_randVec3(const vec1& i_min, const vec1& i_max);

vec1 f_randUnitVec1();
vec2 f_randUnitVec2();
vec3 f_randUnitVec3();

// Ray
Ray f_cameraRay(const Camera& i_camera, const uint32& i_u, const uint32& i_v);
Ray f_cameraRay(const Camera& i_camera, const vec2& i_uv);

// Intersection
bool f_sphereIntersection(const Ray& ray, const Sphere& sphere, vec1& ray_length);
Intersection f_sceneIntersection(const File& i_file, const Ray& i_ray);