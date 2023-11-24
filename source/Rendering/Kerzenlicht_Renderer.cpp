#include "Rendering/Kerzenlicht_Renderer.h"

Kerzenlicht_Renderer::Kerzenlicht_Renderer() {
	resolution = uvec2(1920, 1080);
	render_data = new float[resolution.x * resolution.y * 4];
	display_data = new float[0];

	for (int x = 0; x < resolution.x; x++) {
		for (int y = 0; y < resolution.y; y++) {
			f_renderPixel(x, y, vec4((float)x / resolution.x, 0.0f, (float)y / resolution.y, 1.0f));
		}
	}
}

void Kerzenlicht_Renderer::f_renderPixel(const uint16& i_x, const uint16& i_y, const vec4& i_color) {
	render_data[(i_y * resolution.x + i_x) * 4] = i_color.r;
	render_data[(i_y * resolution.x + i_x) * 4 + 1] = i_color.g;
	render_data[(i_y * resolution.x + i_x) * 4 + 2] = i_color.b;
	render_data[(i_y * resolution.x + i_x) * 4 + 3] = i_color.a;
}

void Kerzenlicht_Renderer::f_renderPixel(const uvec2& i_pixel, const vec4& i_color) {
	render_data[(i_pixel.y * resolution.x + i_pixel.x) * 4    ] = i_color.r;
	render_data[(i_pixel.y * resolution.x + i_pixel.x) * 4 + 1] = i_color.g;
	render_data[(i_pixel.y * resolution.x + i_pixel.x) * 4 + 2] = i_color.b;
	render_data[(i_pixel.y * resolution.x + i_pixel.x) * 4 + 3] = i_color.a;
}

void Kerzenlicht_Renderer::f_updateDisplay(GLuint& ID) {
	delete[] display_data;
	display_data = render_data;
	glGenTextures(1, &ID);
	glBindTexture(GL_TEXTURE_2D, ID);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, resolution.x, resolution.y, 0, GL_RGBA, GL_FLOAT, display_data);
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