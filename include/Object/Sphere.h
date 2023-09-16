#pragma once

#include "Include.h"
#include "Rendering/Material.h"

struct Sphere {
	dvec3     position;
	double    radius;
	Material* material;

	Sphere();
};