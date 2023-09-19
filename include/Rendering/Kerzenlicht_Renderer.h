#pragma once

#include "Include.h"

#include "I-O/File.h"
#include "Material.h"
#include "Math/Math.h"
#include "Object/Mesh.h"
#include "Object/Camera.h"
#include "Object/Sphere.h"

const uint8_t quad_face[] = {1, 2, 0, 1};

struct Ray {
	dvec3 origin;
	dvec3 direction;

	Ray();
	Ray(const dvec3& i_origin, const dvec3& i_direction);
};

struct Ray_Hit {
	double    ray_length;
	dvec3     hit_position;  // Next ray origin
	dvec3     hit_direction; // Next ray direction
	bool      internal;      // Inside an object
	Material* hit_material;

	Ray_Hit();
};

struct Kerzenlicht_Renderer {
	File file;
	vector<vector<dvec4>> pixels;

	Kerzenlicht_Renderer();

	Ray f_getRay(const dvec2& i_uv);
	double f_triIntersection(const Ray& i_ray, const Tri& i_tri);          // no uv
	double f_quadIntersection(const Ray& i_ray, const Quad& i_quad);       // no uv
	double f_sphereIntersection(const Ray& i_ray, const Sphere& i_sphere); // no uv
	Ray_Hit f_sceneIntersection(const Ray& i_ray);
};