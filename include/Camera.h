#pragma once

#include "Include.h"

struct Camera {
	double
		sensor_width,
		focal_length;

	dvec3
		position,
		forward_vec,
		up_vec,
		right_vec;

	Camera() {
		sensor_width = 0.05;
		focal_length = 0.036;
		position     = dvec3( 0, 0, 5);
		forward_vec  = dvec3( 0, 0, -1);
		up_vec       = dvec3( 0, 1,  0);
		right_vec    = dvec3( 1, 0,  0);
	};

	void rotateLocalX(double i_angleDegrees) {
		dmat4 rotation = rotate(dmat4(1.0), i_angleDegrees * DEG_RAD, right_vec);
		forward_vec = dmat3(rotation) * forward_vec;
		up_vec = cross(right_vec, forward_vec);
		updateVectors();
	}

	void rotateLocalY(double i_angleDegrees) {
		dmat4 rotation = rotate(dmat4(1.0), i_angleDegrees * DEG_RAD, dvec3(0.0, 1.0, 0.0));
		forward_vec = dmat3(rotation) * forward_vec;
		right_vec = cross(forward_vec, up_vec);
		updateVectors();
	}

	void rotateLocalZ(double i_angleDegrees) {
		dmat4 rotation = rotate(dmat4(1.0), i_angleDegrees * DEG_RAD, forward_vec);
		right_vec = dmat3(rotation) * right_vec;
		up_vec = cross(right_vec, forward_vec);
		updateVectors();
	}

	void updateVectors() {
		forward_vec = normalize(forward_vec);
		right_vec = normalize(cross(forward_vec, up_vec));
		up_vec = normalize(cross(right_vec, forward_vec));
	}
};