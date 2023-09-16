#include "Rendering/Opengl/FBT.h"

void FBT::f_init(const uvec2& i_size) {
	glGenTextures(1, &ID);
	glBindTexture(GL_TEXTURE_2D, ID);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, i_size.x, i_size.y, 0, GL_RGBA, GL_FLOAT, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, ID, 0);

	glBindTexture(GL_TEXTURE_2D, 0);
}

void FBT::f_resize(const uvec2& i_size) {
	GLuint new_ID;

	glGenTextures(1, &new_ID);
	glBindTexture(GL_TEXTURE_2D, new_ID);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, i_size.x, i_size.y, 0, GL_RGBA, GL_FLOAT, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, new_ID, 0);

	glBindTexture(GL_TEXTURE_2D, 0);
	ID = new_ID;
}

void FBT::f_bind(const GLenum& i_texture_id) {
	glActiveTexture(i_texture_id);
	glBindTexture(GL_TEXTURE_2D, ID);
}

void FBT::f_unbind() {
	glBindTexture(GL_TEXTURE_2D, 0);
}

void FBT::f_delete() {
	glDeleteTextures(1, &ID);
}