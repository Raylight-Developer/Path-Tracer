#include "Rendering/Kerzenlicht_Renderer.h"

Kerzenlicht_Renderer::Kerzenlicht_Renderer() {
	render_data = new float[file.render_camera.resolution.x * file.render_camera.resolution.y * 4];
	display_data = new float[0];

	for (uint32 x = 0; x < file.render_camera.resolution.x; x++) {
		for (uint32 y = 0; y < file.render_camera.resolution.y; y++) {
			f_drawPixel(x, y, vec4((vec1)x / file.render_camera.resolution.x, val(0.0), (vec1)y / file.render_camera.resolution.y, val(1.0)));
		}
	}
}

void Kerzenlicht_Renderer::f_render() {
	file.render_camera.f_compile();
	const vec1 aspect_ratio = val(file.render_camera.resolution.y) / val(file.render_camera.resolution.x);

	for (uint32 x = 0; x < file.render_camera.resolution.x; x++) {
		for (uint32 y = 0; y < file.render_camera.resolution.y; y++) {
			const vec2 uv = vec2(x, y * aspect_ratio) / vec(file.render_camera.resolution) - vec2(0.5, 0.5 * aspect_ratio);

			Ray ray = f_cameraRay(file.render_camera, uv);

			Intersection hit = f_sceneIntersection(file, ray);
			fvec3 color = hit.hit ? fvec3(1.f) : fvec3(1.f, 0.f, 1.f);
			f_drawPixel(x, y, color, 1.0f);
		}
	}
}

void Kerzenlicht_Renderer::f_resize() {
	delete[] render_data;
	delete[] display_data;
	render_data = new float[file.render_camera.resolution.x * file.render_camera.resolution.y * 4];
	display_data = new float[0];
}

void Kerzenlicht_Renderer::f_drawPixel(const uint32& i_x, const uint32& i_y, const fvec4& i_color) {
	render_data[(i_y * file.render_camera.resolution.x + i_x) * 4    ] = i_color.r;
	render_data[(i_y * file.render_camera.resolution.x + i_x) * 4 + 1] = i_color.g;
	render_data[(i_y * file.render_camera.resolution.x + i_x) * 4 + 2] = i_color.b;
	render_data[(i_y * file.render_camera.resolution.x + i_x) * 4 + 3] = i_color.a;
}

void Kerzenlicht_Renderer::f_drawPixel(const uint32& i_x, const uint32& i_y, const fvec3& i_color, const fvec1& i_alpha) {
	render_data[(i_y * file.render_camera.resolution.x + i_x) * 4    ] = i_color.r;
	render_data[(i_y * file.render_camera.resolution.x + i_x) * 4 + 1] = i_color.g;
	render_data[(i_y * file.render_camera.resolution.x + i_x) * 4 + 2] = i_color.b;
	render_data[(i_y * file.render_camera.resolution.x + i_x) * 4 + 3] = i_alpha;
}

void Kerzenlicht_Renderer::f_updateDisplay(GLuint& ID) {
	//delete[] display_data;
	display_data = render_data;
	glGenTextures(1, &ID);
	glBindTexture(GL_TEXTURE_2D, ID);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, file.render_camera.resolution.x, file.render_camera.resolution.y, 0, GL_RGBA, GL_FLOAT, display_data);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

	glBindTexture(GL_TEXTURE_2D, 0);
}

void Kerzenlicht_Renderer::f_bindDisplay(GLuint& ID, GLuint& program) {
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, ID);
	glUniform1i(glGetUniformLocation(program, "render_output"), 0);
}