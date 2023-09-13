#include "Texture.h"

void Texture::Init(const string& i_image_path, const File_Extension::Enum& i_type) {
	if (i_type == File_Extension::EXR) {
		uint16_t width = 4096;
		uint16_t height = 4096;
		vector<float> pixels = {};

		glGenTextures(1, &ID);
		glBindTexture(GL_TEXTURE_2D, ID);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_FLOAT, &pixels);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, ID, 0);

		glBindTexture(GL_TEXTURE_2D, 0);
	}
	else {
		cout << "ERROR: Image ( " << i_image_path << " ) Cannot be loaded.";
	}
}

void Texture::Bind(const GLenum& i_texture_id) {
	glActiveTexture(i_texture_id);
	glBindTexture(GL_TEXTURE_2D, ID);
}

void Texture::Unbind() {
	glBindTexture(GL_TEXTURE_2D, 0);
}

void Texture::Delete() {
	glDeleteTextures(1, &ID);
}