#include "Rendering/Kerzenlicht_Renderer.h"

Ray::Ray() {
	origin    = dvec3(0.0, 0.0, 0.0);
	direction = dvec3(0.0, 0.0, 1.0);
}

Ray::Ray(const dvec3& i_origin, const dvec3& i_direction) {
	origin = i_origin;
	direction = i_direction;
}

Ray_Hit::Ray_Hit() {
	ray_length     = 2.0;
	hit_position   = dvec3(0.0, 0.0,  2.0);
	hit_direction  = dvec3(0.0, 0.0, -1.0);
	internal       = false;
	hit_material   = nullptr;
}

Kerzenlicht_Renderer::Kerzenlicht_Renderer() {
	file = File();
	pixels = vector(file.render_camera.width, vector(file.render_camera.height, dvec4(0, 0, 0, 1)));
}

Ray Kerzenlicht_Renderer::f_getRay(const dvec2& i_uv) {
	dvec2 uv = i_uv - 0.5;
	uv.x *= double(file.render_camera.width) / double(file.render_camera.height);

	dvec3 projection_center = file.render_camera.position + file.render_camera.focal_length * file.render_camera.z_vector;
	dvec3 projection_u = normalize(cross(file.render_camera.z_vector, file.render_camera.y_vector)) * file.render_camera.sensor_width;
	dvec3 projection_v = normalize(cross(projection_u, file.render_camera.z_vector)) * (file.render_camera.sensor_width / 1.0);
	return Ray(
		file.render_camera.position,
		normalize(projection_center + (projection_u * uv.x) + (projection_v * uv.y) - file.render_camera.position)
	);
}

double Kerzenlicht_Renderer::f_triIntersection(const Ray& i_ray, const Tri& i_tri) {
	return 1.0;
}

double Kerzenlicht_Renderer::f_quadIntersection(const Ray& i_ray, const Quad& i_quad) {
	return 1.0;
}

double Kerzenlicht_Renderer::f_sphereIntersection(const Ray& i_ray, const Sphere& i_sphere) {
	return 1.0;
}

Ray_Hit Kerzenlicht_Renderer::f_sceneIntersection(const Ray& i_ray) {
	return Ray_Hit();
}