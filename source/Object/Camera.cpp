#include "Object/Camera.h"

Camera::Camera() {
	resolution = uvec2(1920, 1080);

	depth_of_field = false;
	focal_length = val(0.05);
	focal_angle = val(1.0);

	sensor_width = val(0.036);

	position = dvec3(  0 , 0,  5 );
	rotation = dvec3( -90, 0,  0 );

	x_vector = dvec3(  1 , 0,  0 );
	y_vector = dvec3(  0 , 1,  0 );
	z_vector = dvec3(  0 , 0, -1 );

	f_compileVectors();
	f_compile();
}

void Camera::f_move(const vec1& i_x, const vec1& i_y, const vec1& i_z, const vec1& i_speed) {
	position += i_x * i_speed * x_vector;
	position += i_y * i_speed * y_vector;
	position += i_z * i_speed * z_vector;
}

mat4 Camera::f_getViewMatrix() {
	return lookAt(position, position + z_vector, y_vector);
}

void Camera::f_rotate(const vec1& i_yaw, const vec1& i_pitch) {
	rotation += vec3(i_yaw, i_pitch, 0);

	if (rotation.y > 89.0) rotation.y = 89.0;
	if (rotation.y < -89.0) rotation.y = -89.0;

	f_compileVectors();
}

void Camera::f_compile() {
	f_compileVectors();

	projection_center = position + sensor_width * z_vector;
	projection_u = normalize(cross(z_vector, y_vector)) * sensor_width;
	projection_v = normalize(cross(projection_u, z_vector)) * sensor_width;
}

void Camera::f_compileVectors() {
	z_vector = normalize(vec3(
		cos(rotation.x * DEG_RAD) * cos(rotation.y * DEG_RAD),
		sin(rotation.y * DEG_RAD),
		sin(rotation.x * DEG_RAD) * cos(rotation.y * DEG_RAD)
	));
	x_vector = normalize(cross(z_vector, vec3(0, 1, 0)));
	y_vector = normalize(cross(x_vector, z_vector));
}
