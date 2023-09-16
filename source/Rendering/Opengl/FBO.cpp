#include "Rendering/Opengl/FBO.h"

void FBO::f_init() {
	glGenFramebuffers(1, &ID);
}

void FBO::f_bind() {
	glBindFramebuffer(GL_FRAMEBUFFER, ID);
}

void FBO::f_unbind() {
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void FBO::f_delete() {
	glDeleteFramebuffers(1, &ID);
}