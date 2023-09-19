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
	dvec3 v1v0 = i_tri.vertex_b - i_tri.vertex_a;
	dvec3 v2v0 = i_tri.vertex_c - i_tri.vertex_a;
	dvec3 rov0 = i_ray.origin   - i_tri.vertex_a;
	dvec3  n = cross(v1v0, v2v0);
	dvec3  q = cross(rov0, i_ray.direction);
	double d = 1.0 / dot(i_ray.direction, n);
	double u = d * dot(-q, v2v0);
	double v = d * dot(q, v1v0);
	double distance = d * dot(-n, rov0);

	if (u < 0.0 || v < 0.0 || (u + v) > 1.0) {
		distance = -1.0;
	}
	return distance;
}

double Kerzenlicht_Renderer::f_quadIntersection(const Ray& i_ray, const Quad& i_quad) {
	dvec3 a = i_quad.vertex_b - i_quad.vertex_a;
	dvec3 b = i_quad.vertex_d - i_quad.vertex_a;
	dvec3 c = i_quad.vertex_c - i_quad.vertex_a;
	dvec3 p = i_ray.origin - i_quad.vertex_a;
	dvec3 normal = cross(a, b);
	double distance = -dot(p, normal) / dot(i_ray.direction, normal);
	if (distance < 0.0) {
		return -1.0;
	}
	vec3 pos = p + distance * i_ray.direction;
	vec3 mor = abs(normal);
	int id;
	if (mor.x > mor.y && mor.x > mor.z) {
		id = 0;
	}
	else if (mor.y > mor.z) {
		id = 1;
	}
	else {
		id = 2;
	}
	int idu = quad_face[id];
	int idv = quad_face[id + 1];
	dvec2 kp = dvec2(pos[idu], pos[idv]);
	dvec2 ka = dvec2(a[idu], a[idv]);
	dvec2 kb = dvec2(b[idu], b[idv]);
	dvec2 kc = dvec2(c[idu], c[idv]);
	dvec2 kg = kc - kb - ka;
	double k0 = cross(kp, kb);
	double k2 = cross(kc - kb, ka);
	double k1 = cross(kp, kg) - normal[id];
	double u, v;
	if (abs(k2) < EPSILON) { // Parallel
		v = -k0 / k1;
		u = cross(kp, ka) / k1;
	}
	else {
		double w = k1 * k1 - 4.0 * k0 * k2;
		if (w < 0.0) {
			return -1.0;
		}
		w = sqrt(w);
		double ik2 = 1.0 / (2.0 * k2);
		v = (-k1 - w) * ik2;
		if (v < 0.0 || v > 1.0) {
			v = (-k1 + w) * ik2;
			u = (kp.x - ka.x * v) / (kb.x + kg.x * v);
		}
	}

	if (u < 0.0 || u > 1.0 || v < 0.0 || v > 1.0) {
		return -1.0;
	}
	return distance;
}

double Kerzenlicht_Renderer::f_sphereIntersection(const Ray& i_ray, const Sphere& i_sphere) {
	dvec3 delta_position = i_ray.origin - i_sphere.position;

	double incidence = dot(delta_position, i_ray.direction);
	double delta = incidence * incidence - dot(delta_position, delta_position) + i_sphere.radius * i_sphere.radius;
	double sqdelta = sqrt(delta);

	if (delta < 0.0) {
		return -1.0;
	}
	if (-incidence - sqdelta > EPSILON) {
		return -incidence - sqdelta;
	}
	if (-incidence + sqdelta > EPSILON) {
		return -incidence + sqdelta;
	}

	return -1.0;
}

Ray_Hit Kerzenlicht_Renderer::f_sceneIntersection(const Ray& i_ray) {
	return Ray_Hit();
}