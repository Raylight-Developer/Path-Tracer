#pragma once

#include "Include.h"

struct Camera {
	double
		Focal_Length,
		Sensor_Width;

	dvec3
		Pos,
		Rot,
		X_Vec,
		Y_Vec,
		Z_Vec;

	Camera() {
		Focal_Length = 0.05;
		Sensor_Width = 0.036;
		Pos   = dvec3(   0, 0.5,  5 );
		Rot   = dvec3( -90, 0,  0 );
		X_Vec = dvec3(   1, 0,  0 );
		Y_Vec = dvec3(   0, 1,  0 );
		Z_Vec = dvec3(   0, 0, -1 );
	};

	void move(const double& i_x, const double& i_y, const double& i_z, const double& i_speed) {
		Pos += i_x * i_speed * X_Vec;
		Pos += i_y * i_speed * Y_Vec;
		Pos += i_z * i_speed * Z_Vec;
	}

	dmat4 GetViewMatrix() {
		return lookAt(Pos, Pos + Z_Vec, Y_Vec);
	}

	void rotate(const double& i_yaw, const double& i_pitch) {
		Rot += dvec3(i_yaw, i_pitch, 0);

		if (Rot.y > 89.0) Rot.y = 89.0;
		if (Rot.y < -89.0) Rot.y = -89.0;

		updateCameraVectors();
	}

	void updateCameraVectors() {
		Z_Vec = normalize(dvec3(
			cos(Rot.x * DEG_RAD) * cos(Rot.y * DEG_RAD),
			sin(Rot.y * DEG_RAD),
			sin(Rot.x * DEG_RAD) * cos(Rot.y * DEG_RAD)
		));
		X_Vec = normalize(cross(Z_Vec, dvec3(0, 1, 0)));
		Y_Vec = normalize(cross(X_Vec, Z_Vec));
	}
};