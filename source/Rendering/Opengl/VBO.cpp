#include "Rendering/Opengl/VBO.h"

void VBO::f_init(GLfloat* vertices, GLsizeiptr size) {
	glGenBuffers(1, &ID);
	glBindBuffer(GL_ARRAY_BUFFER, ID);
	glBufferData(GL_ARRAY_BUFFER, size, vertices, GL_STATIC_DRAW);
}

void VBO::f_bind() {
	glBindBuffer(GL_ARRAY_BUFFER, ID);
}

void VBO::f_unbind() {
	glBindBuffer(GL_ARRAY_BUFFER, 0);
}

void VBO::f_delete() {
	glDeleteBuffers(1, &ID);
}