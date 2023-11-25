#pragma once

#include "Include.h"

#define EPSILON 0.00001

struct Camera {
	uvec2 resolution;

	bool depth_of_field;
	vec1 focal_length;
	vec1 focal_angle;

	vec1 sensor_width;

	vec3 position;
	vec3 rotation;

	vec3 x_vector;
	vec3 y_vector;
	vec3 z_vector;

	vec3 projection_center;
	vec3 projection_u;
	vec3 projection_v;

	Camera();

	void f_move(const vec1& i_x, const vec1& i_y, const vec1& i_z, const vec1& i_speed);

	mat4 f_getViewMatrix();

	void f_rotate(const vec1& i_yaw, const vec1& i_pitch);

	void f_compile();
	void f_compileVectors();
};