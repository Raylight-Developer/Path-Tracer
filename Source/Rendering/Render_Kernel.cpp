#include "Rendering/Render_Kernel.h"

Ray f_cameraRay(const Camera& i_camera, const uint32& i_u, const uint32& i_v) {
	const vec3 projection_center = i_camera.position + i_camera.sensor_width * i_camera.z_vector;
	const vec3 projection_u = normalize(cross(i_camera.z_vector, i_camera.y_vector)) * i_camera.sensor_width;
	const vec3 projection_v = normalize(cross(projection_u, i_camera.z_vector)) * i_camera.sensor_width;

	return Ray(
		i_camera.position,
		normalize(
			projection_center
			+ (projection_u * val(i_u) / val(i_camera.resolution.x))
			+ (projection_v * val(i_v) / val(i_camera.resolution.y))
			- i_camera.position
		)
	);
}

Ray f_cameraRay(const Camera& i_camera, const vec2& i_uv) {
	const vec3 projection_center = i_camera.position + i_camera.sensor_width * i_camera.z_vector;
	const vec3 projection_u = normalize(cross(i_camera.z_vector, i_camera.y_vector)) * i_camera.sensor_width;
	const vec3 projection_v = normalize(cross(projection_u, i_camera.z_vector)) * i_camera.sensor_width;

	return Ray(
		i_camera.position,
		normalize(
			projection_center
			+ projection_u * i_uv.x
			+ projection_v * i_uv.y
			- i_camera.position
		)
	);
}

bool f_sphereIntersection(const Ray& ray, const Sphere& sphere, vec1& ray_length) {
	const vec3 ray_origin = ray.origin - sphere.position;
	const vec1 b = dot(ray_origin, ray.direction);
	const vec1 delta = b * b - dot(ray_origin, ray_origin) + sphere.radius * sphere.radius;

	if (delta < 0)
		return false;
	vec1 sqdelta = sqrt(delta);
	if (-b - sqdelta > EPSILON) {
		ray_length = -b - sqdelta;
		return true;
	}
	else if (-b + sqdelta > EPSILON) {
		ray_length = -b + sqdelta;
		return true;
	}
	return false;
}

Intersection f_sceneIntersection(const File& i_file, const Ray& i_ray) {
	Intersection hit_data;

	hit_data.ray_length = i_file.render_max_ray_length;

	for (const Sphere& sphere : i_file.file_spheres) {
		vec1 resultRayLength;
		if (f_sphereIntersection(i_ray, sphere, resultRayLength)) {
			if (resultRayLength < hit_data.ray_length && resultRayLength > 0.001) {
				hit_data.ray_length = resultRayLength;
				hit_data.position = i_ray.origin + i_ray.direction * resultRayLength;
				hit_data.normal = normalize(hit_data.position - sphere.position);

				hit_data.inside = distance(i_ray.origin, sphere.position) <= sphere.radius;
				if (hit_data.inside) hit_data.normal *= -1.0;

				hit_data.material = sphere.material;
				//hit_data.Hit_Obj = i;
				hit_data.hit = true;
			}
		}
	}
	return hit_data;
}