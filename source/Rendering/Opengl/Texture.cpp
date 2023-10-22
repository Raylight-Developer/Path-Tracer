#include "Rendering/Opengl/Texture.h"

void Texture::f_init(const string& i_image_path) {
	Image texture = Image();
	if (texture.f_load(i_image_path)) {
		glGenTextures(1, &ID);
		glBindTexture(GL_TEXTURE_2D, ID);
		glTexImage2D(GL_TEXTURE_2D, 0, texture.channel_fromat, texture.width, texture.height, 0, texture.channel_fromat, texture.data_type, texture.data);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

		glBindTexture(GL_TEXTURE_2D, 0);
	}
}

void Texture::f_bind(const GLenum& i_texture_id) {
	glActiveTexture(i_texture_id);
	glBindTexture(GL_TEXTURE_2D, ID);
}

void Texture::f_unbind() {
	glBindTexture(GL_TEXTURE_2D, 0);
}

void Texture::f_delete() {
	glDeleteTextures(1, &ID);
}