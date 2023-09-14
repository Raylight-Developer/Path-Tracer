#pragma once

#include "Include.h"

struct Camera {
	double
		focal_length,
		sensor_width;

	dvec3
		position,
		euler_rot,
		front_vec,
		up_vec,
		right_vec;

	Camera() {
		focal_length = 0.05;
		sensor_width = 0.036;
		position  = dvec3(   0, 0,  5 );
		euler_rot = dvec3( -90, 0,  0 );
		front_vec = dvec3(   0, 0, -1 );
		up_vec    = dvec3(   0, 1,  0 );
		right_vec = dvec3(   1, 0,  0 );
	};

	void move(const double& i_x, const double& i_y, const double& i_z, const double& i_speed) {
		position += i_x * i_speed * right_vec;
		position += i_y * i_speed * up_vec;
		position += i_z * i_speed * front_vec;
	}

	dmat4 GetViewMatrix() {
		return lookAt(position, position + front_vec, up_vec);
	}

	void rotate(const double& i_yaw, const double& i_pitch) {
		euler_rot += dvec3(i_yaw, i_pitch, 0);

		if (euler_rot.y > 89.0) euler_rot.y = 89.0;
		if (euler_rot.y < -89.0) euler_rot.y = -89.0;

		updateCameraVectors();
	}

	void updateCameraVectors() {
		front_vec = normalize(dvec3(
			cos(euler_rot.x * DEG_RAD) * cos(euler_rot.y * DEG_RAD),
			sin(euler_rot.y * DEG_RAD),
			sin(euler_rot.x * DEG_RAD) * cos(euler_rot.y * DEG_RAD)
		));
		right_vec = normalize(cross(front_vec, dvec3(0, 1, 0)));
		up_vec = normalize(cross(right_vec, front_vec));
	}
};