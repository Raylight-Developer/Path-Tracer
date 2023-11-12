#include "Object/Camera.h"

Camera::Camera() {
	focal_length = 0.05;
	sensor_width = 0.036;
	width  = 1920;
	height = 1080;

	position = dvec3(  45 , 25, 45 );
	rotation = dvec3( -135, -15,  0 );
	z_vector = normalize(dvec3(
		cos(rotation.x * DEG_RAD) * cos(rotation.y * DEG_RAD),
		sin(rotation.y * DEG_RAD),
		sin(rotation.x * DEG_RAD) * cos(rotation.y * DEG_RAD)
	));
	x_vector = normalize(cross(z_vector, dvec3(0, 1, 0)));
	y_vector = normalize(cross(x_vector, z_vector));
}

void Camera::f_move(const double& i_x, const double& i_y, const double& i_z, const double& i_speed) {
	position += i_x * i_speed * x_vector;
	position += i_y * i_speed * y_vector;
	position += i_z * i_speed * z_vector;
}

dmat4 Camera::f_getViewMatrix() {
	return lookAt(position, position + z_vector, y_vector);
}

void Camera::f_rotate(const double& i_yaw, const double& i_pitch) {
	rotation += dvec3(i_yaw, i_pitch, 0);

	if (rotation.y > 89.0) rotation.y = 89.0;
	if (rotation.y < -89.0) rotation.y = -89.0;

	f_compile();
}

void Camera::f_compile() {
	z_vector = normalize(dvec3(
		cos(rotation.x * DEG_RAD) * cos(rotation.y * DEG_RAD),
		sin(rotation.y * DEG_RAD),
		sin(rotation.x * DEG_RAD) * cos(rotation.y * DEG_RAD)
	));
	x_vector = normalize(cross(z_vector, dvec3(0, 1, 0)));
	y_vector = normalize(cross(x_vector, z_vector));
}