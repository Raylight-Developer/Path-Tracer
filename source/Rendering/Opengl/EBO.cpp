#include "Rendering/Opengl/EBO.h"

void EBO::f_init(GLuint* i_indices, GLsizeiptr i_size) {
	glGenBuffers(1, &ID);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ID);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, i_size, i_indices, GL_STATIC_DRAW);
}

void EBO::f_bind() {
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ID);
}

void EBO::f_unbind() {
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

void EBO::f_delete() {
	glDeleteBuffers(1, &ID);
}