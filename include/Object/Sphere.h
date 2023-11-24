#pragma once

#include "Include.h"

#include "Rendering/Material.h"

struct Sphere {
	vec3 position;
	vec1 radius;
	Material* material;

	Sphere();
};