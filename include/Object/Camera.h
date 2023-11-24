#pragma once

#include "Include.h"

#define EPSILON 0.00001

struct Camera {
	uvec2 resolution;

	vec1 focal_length;
	vec1 sensor_width;

	vec3 position;
	vec3 rotation;
	vec3 x_vector;
	vec3 y_vector;
	vec3 z_vector;

	Camera();

	void f_move(const vec1& i_x, const vec1& i_y, const vec1& i_z, const vec1& i_speed);

	dmat4 f_getViewMatrix();

	void f_rotate(const vec1& i_yaw, const vec1& i_pitch);

	void f_compile();
};